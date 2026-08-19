import 'package:flutter/widgets.dart';

import '../ast/ast.dart';
import '../config/dynamic_error_behavior.dart';
import '../context/dynamic_build_context.dart';
import '../errors/dynamic_parser_exception.dart';
import '../errors/suggestion.dart';
import '../expressions/expression_evaluator.dart';
import '../registry/property_definition.dart';
import '../registry/resolved_arguments.dart';
import '../registry/widget_definition.dart';

/// Turns AST into real values: primitives pass through, expressions are
/// evaluated, identifier paths resolve against the registry's value table,
/// and call nodes (`Container(...)`, `EdgeInsets.all(...)`, `action(...)`)
/// dispatch to whichever registered widget or constructor they name.
///
/// This is the single place where a [WidgetNode] found in "value position"
/// (e.g. as the value of a `child:` property, or an item in a `children:`
/// list) turns into an actual [Widget] — which is what lets nested widgets,
/// nested constructors (`TextStyle(...)` inside `style:`), and actions all
/// share one resolution path instead of three bespoke ones.
///
/// Per-node error recovery (see [DynamicErrorBehavior]) is applied at every
/// widget boundary, not just the root: a failure resolving one item deep
/// inside a `children:` list only replaces that item.
class ValueResolver {
  const ValueResolver();

  /// Resolves the parsed root value into a widget tree, applying error
  /// recovery per [DynamicBuildContext.config] at the root and at every
  /// nested widget boundary.
  Widget buildRoot(ValueNode ast, DynamicBuildContext context) {
    try {
      if (ast is! WidgetNode) {
        throw ValidationException(
          'The top-level value must be a widget constructor call, e.g. "Container(...)".',
          span: ast.span,
          actual: ast.runtimeType.toString(),
        );
      }
      return _buildWidgetNode(ast, context);
    } catch (error, stackTrace) {
      return _recover('<root>', context, error, stackTrace);
    }
  }

  /// Resolves any [ValueNode] to a plain Dart value (or a [Widget], if the
  /// node is a call that names a registered widget).
  Object? resolve(ValueNode node, DynamicBuildContext context) {
    if (node is NullValueNode) return null;
    if (node is BoolValueNode) return node.value;
    if (node is IntValueNode) return node.value;
    if (node is DoubleValueNode) return node.value;
    if (node is StringValueNode) return node.value;
    if (node is StringInterpolationValueNode) {
      return _resolveInterpolation(node, context);
    }
    if (node is ListValueNode) {
      return node.items
          .map((ValueNode n) => resolve(n, context))
          .toList(growable: false);
    }
    if (node is MapValueNode) return _resolveMap(node, context);
    if (node is ExpressionNode) {
      return ExpressionEvaluator(context.data).evaluate(node);
    }
    if (node is IdentifierPathValueNode) {
      return _resolveIdentifierPath(node, context);
    }
    if (node is WidgetNode) return _resolveCall(node, context);
    throw ValidationException('Unsupported AST node: ${node.runtimeType}.',
        span: node.span);
  }

  // ---------------------------------------------------------------------
  // Widget resolution (with per-node error recovery)
  // ---------------------------------------------------------------------

  Widget resolveWidgetNode(WidgetNode node, DynamicBuildContext context) {
    try {
      return _buildWidgetNode(node, context);
    } catch (error, stackTrace) {
      return _recover(node.fullName, context, error, stackTrace);
    }
  }

  Widget _buildWidgetNode(WidgetNode node, DynamicBuildContext context) {
    final WidgetDefinition? widgetDef =
        context.registry.lookupWidget(node.fullName);
    if (widgetDef == null) {
      throw _unknownCallable(node, context, widgetOnly: true);
    }
    final ResolvedArguments args = _resolveArguments(widgetDef, node, context);
    return widgetDef.builder(context, args);
  }

  Widget _recover(String label, DynamicBuildContext context, Object error,
      StackTrace stackTrace) {
    switch (context.config.errorBehavior) {
      case DynamicErrorBehavior.throwError:
        Error.throwWithStackTrace(error, stackTrace);
      case DynamicErrorBehavior.fallback:
        context.config.onError?.call(error, stackTrace);
        if (context.config.enableDebugLogging) {
          debugPrint(
              '[dynamic_widget_parser] recovered from error at "$label": $error');
        }
        return context.config
            .fallbackWidgetBuilder(context.buildContext, error, stackTrace);
      case DynamicErrorBehavior.ignore:
        if (context.config.enableDebugLogging) {
          debugPrint(
              '[dynamic_widget_parser] ignored error at "$label": $error');
        }
        return context.config
            .fallbackWidgetBuilder(context.buildContext, error, stackTrace);
    }
  }

  // ---------------------------------------------------------------------
  // Calls: dispatch to widget or constructor
  // ---------------------------------------------------------------------

  Object? _resolveCall(WidgetNode node, DynamicBuildContext context) {
    if (context.registry.lookupWidget(node.fullName) != null) {
      return resolveWidgetNode(node, context);
    }
    final ConstructorDefinition? ctorDef =
        context.registry.lookupConstructor(node.fullName);
    if (ctorDef != null) {
      final ResolvedArguments args = _resolveArguments(ctorDef, node, context);
      try {
        return ctorDef.builder(context, args);
      } on DynamicParserException catch (e) {
        // Errors thrown directly by a constructor builder (e.g. the
        // `action(...)` constructor rejecting an unregistered action name)
        // don't have access to the call site's span, so back-fill it here
        // rather than surfacing a location-less error.
        if (e.span != null) rethrow;
        throw PropertyResolutionException(
          e.message,
          span: node.span,
          widget: node.fullName,
          property: e.property,
          expected: e.expected,
          actual: e.actual,
          suggestion: e.suggestion,
        );
      } catch (e) {
        throw PropertyResolutionException(
          'Failed to construct "${node.fullName}": $e',
          span: node.span,
          widget: node.fullName,
        );
      }
    }
    throw _unknownCallable(node, context, widgetOnly: false);
  }

  DynamicParserException _unknownCallable(
      WidgetNode node, DynamicBuildContext context,
      {required bool widgetOnly}) {
    final Iterable<String> candidates = widgetOnly
        ? context.registry.widgetNames
        : <String>{
            ...context.registry.widgetNames,
            ...context.registry.constructorNames
          };
    final String? suggestion = findClosestMatch(node.fullName, candidates);
    return WidgetResolutionException(
      widgetOnly
          ? 'Unknown widget "${node.fullName}". Widgets must be explicitly registered before they can be used.'
          : 'Unknown widget or constructor "${node.fullName}". Names must be explicitly registered before they can be used.',
      span: node.span,
      widget: node.fullName,
      suggestion: suggestion,
    );
  }

  // ---------------------------------------------------------------------
  // Argument resolution shared by widgets and constructors
  // ---------------------------------------------------------------------

  ResolvedArguments _resolveArguments(CallableDefinition<Object?> def,
      WidgetNode node, DynamicBuildContext context) {
    final Map<String, Object?> named = <String, Object?>{};
    final Set<String> providedNames = <String>{};

    for (final PropertyNode propNode in node.properties) {
      final PropertyDefinition? propDef = def.propertyByName(propNode.name);
      if (propDef == null) {
        final String? suggestion =
            findClosestMatch(propNode.name, def.propertyNames);
        throw PropertyResolutionException(
          'Unknown property "${propNode.name}" for "${def.name}".',
          span: propNode.span,
          widget: def.name,
          property: propNode.name,
          suggestion: suggestion,
        );
      }
      providedNames.add(propNode.name);
      named[propNode.name] =
          _resolveAndConvertProperty(propDef, propNode.value, def, context);
    }

    for (final PropertyDefinition propDef in def.properties) {
      if (providedNames.contains(propDef.name)) continue;
      if (propDef.isRequired) {
        throw PropertyResolutionException(
          'Missing required property "${propDef.name}" for "${def.name}".',
          span: node.span,
          widget: def.name,
          property: propDef.name,
          expected: propDef.type.toString(),
        );
      }
      if (propDef.hasDefault) {
        named[propDef.name] = propDef.defaultValue;
      }
    }

    if (def.positionalParameters.isEmpty &&
        node.positionalArguments.isNotEmpty) {
      throw PropertyResolutionException(
        '"${def.name}" does not accept positional arguments.',
        span: node.span,
        widget: def.name,
      );
    }
    if (node.positionalArguments.length > def.positionalParameters.length) {
      throw PropertyResolutionException(
        '"${def.name}" accepts at most ${def.positionalParameters.length} positional argument(s), '
        'got ${node.positionalArguments.length}.',
        span: node.span,
        widget: def.name,
      );
    }

    final List<Object?> positional = <Object?>[];
    for (int i = 0; i < def.positionalParameters.length; i++) {
      final PropertyDefinition paramDef = def.positionalParameters[i];
      if (i < node.positionalArguments.length) {
        positional.add(_resolveAndConvertProperty(
            paramDef, node.positionalArguments[i], def, context));
      } else if (paramDef.isRequired) {
        throw PropertyResolutionException(
          'Missing required positional argument #$i ("${paramDef.name}") for "${def.name}".',
          span: node.span,
          widget: def.name,
          property: paramDef.name,
        );
      } else if (paramDef.hasDefault) {
        positional.add(paramDef.defaultValue);
      } else {
        positional.add(null);
      }
    }

    return ResolvedArguments(named: named, positional: positional);
  }

  Object? _resolveAndConvertProperty(
    PropertyDefinition propDef,
    ValueNode valueNode,
    CallableDefinition<Object?> owner,
    DynamicBuildContext context,
  ) {
    Object? value = resolve(valueNode, context);
    if (propDef.converter != null) {
      try {
        value = propDef.converter!(value);
      } on DynamicParserException {
        rethrow;
      } catch (e) {
        throw PropertyResolutionException(
          'Invalid value for property "${propDef.name}" of "${owner.name}": $e',
          span: valueNode.span,
          widget: owner.name,
          property: propDef.name,
          expected: propDef.type.toString(),
          actual: value == null ? 'null' : value.runtimeType.toString(),
        );
      }
    }
    if (!_matchesDeclaredType(value, propDef.type)) {
      throw PropertyResolutionException(
        'Invalid type for property "${propDef.name}" of "${owner.name}".',
        span: valueNode.span,
        widget: owner.name,
        property: propDef.name,
        expected: propDef.type.toString(),
        actual: value == null ? 'null' : value.runtimeType.toString(),
      );
    }
    if (propDef.validator != null) {
      final String? error = propDef.validator!(value);
      if (error != null) {
        throw PropertyResolutionException(
          'Invalid value for property "${propDef.name}" of "${owner.name}": $error',
          span: valueNode.span,
          widget: owner.name,
          property: propDef.name,
        );
      }
    }
    return value;
  }

  /// Best-effort safety net for scalar primitives. Complex/Flutter types
  /// (`Color`, `EdgeInsetsGeometry`, `Widget`, ...) are trusted to the
  /// combination of registry-driven resolution (which can only ever
  /// produce a correctly-typed instance for registered names) and each
  /// property's [PropertyDefinition.converter] — Dart has no reflective
  /// "is this an instance of this runtime Type" check to fall back on.
  bool _matchesDeclaredType(Object? value, Type type) {
    if (value == null) return true;
    if (type == String) return value is String;
    if (type == int) return value is int;
    if (type == double) return value is double;
    if (type == num) return value is num;
    if (type == bool) return value is bool;
    return true;
  }

  // ---------------------------------------------------------------------
  // Collections / strings / identifiers
  // ---------------------------------------------------------------------

  Map<String, Object?> _resolveMap(
      MapValueNode node, DynamicBuildContext context) {
    final Map<String, Object?> result = <String, Object?>{};
    for (final MapEntryNode entry in node.entries) {
      final Object? key = resolve(entry.key, context);
      if (key is! String) {
        throw ValidationException(
          'Map keys must be strings, got ${key == null ? 'null' : key.runtimeType}.',
          span: entry.key.span,
        );
      }
      result[key] = resolve(entry.value, context);
    }
    return result;
  }

  String _resolveInterpolation(
      StringInterpolationValueNode node, DynamicBuildContext context) {
    final StringBuffer buffer = StringBuffer();
    for (final Object part in node.parts) {
      if (part is String) {
        buffer.write(part);
      } else if (part is ValueNode) {
        buffer.write(_stringify(resolve(part, context)));
      }
    }
    return buffer.toString();
  }

  String _stringify(Object? value) => value == null ? '' : value.toString();

  Object? _resolveIdentifierPath(
      IdentifierPathValueNode node, DynamicBuildContext context) {
    final result = context.registry.resolveValue(node.joined);
    if (result.isFound) return result.value;
    final String? suggestion =
        findClosestMatch(node.joined, context.registry.valueNames);
    throw WidgetResolutionException(
      'Unknown value "${node.joined}". Colors, enums, and constants must be explicitly registered before they can be used.',
      span: node.span,
      widget: node.joined,
      suggestion: suggestion,
    );
  }
}
