import '../actions/action_registry.dart';
import '../ast/ast.dart';
import '../errors/suggestion.dart';
import '../registry/dynamic_widget_registry.dart';
import '../registry/property_definition.dart';
import '../registry/widget_definition.dart';
import 'validation_result.dart';

/// Walks parsed AST and checks it against a [DynamicWidgetRegistry] (and
/// optionally an [ActionRegistry]) *without* building any widgets —
/// collecting every issue it finds rather than stopping at the first one,
/// which is what makes it useful for showing a developer (or a CMS/backend
/// team authoring remote UI) a complete list of problems at once.
class SemanticValidator {
  const SemanticValidator();

  ValidationResult validate(
    ValueNode ast, {
    required DynamicWidgetRegistry registry,
    ActionRegistry? actions,
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    if (ast is! WidgetNode) {
      issues.add(ValidationIssue(
        message:
            'The top-level value must be a widget constructor call, e.g. "Container(...)".',
        severity: ValidationSeverity.error,
        span: ast.span,
      ));
      return ValidationResult(issues);
    }
    _visitCall(ast, registry, actions, issues);
    return ValidationResult(issues);
  }

  void _visitValue(ValueNode node, DynamicWidgetRegistry registry,
      ActionRegistry? actions, List<ValidationIssue> issues) {
    if (node is WidgetNode) {
      _visitCall(node, registry, actions, issues);
      return;
    }
    if (node is ListValueNode) {
      for (final ValueNode item in node.items) {
        _visitValue(item, registry, actions, issues);
      }
      return;
    }
    if (node is MapValueNode) {
      for (final MapEntryNode entry in node.entries) {
        _visitValue(entry.key, registry, actions, issues);
        _visitValue(entry.value, registry, actions, issues);
      }
      return;
    }
    if (node is StringInterpolationValueNode) {
      for (final Object part in node.parts) {
        if (part is ValueNode) _visitValue(part, registry, actions, issues);
      }
      return;
    }
    if (node is IdentifierPathValueNode) {
      if (!registry.hasValue(node.joined)) {
        issues.add(ValidationIssue(
          message:
              'Unknown value "${node.joined}". Colors, enums, and constants must be explicitly registered.',
          severity: ValidationSeverity.error,
          span: node.span,
          suggestion: findClosestMatch(node.joined, registry.valueNames),
        ));
      }
      return;
    }
    // Literals and expressions: nothing further can be statically checked
    // without a DynamicDataContext.
  }

  void _visitCall(WidgetNode node, DynamicWidgetRegistry registry,
      ActionRegistry? actions, List<ValidationIssue> issues) {
    if (node.name == 'action' && node.constructorName == null) {
      _visitAction(node, registry, actions, issues);
      return;
    }

    final WidgetDefinition? widgetDef = registry.lookupWidget(node.fullName);
    final ConstructorDefinition? ctorDef =
        widgetDef != null ? null : registry.lookupConstructor(node.fullName);

    if (widgetDef == null && ctorDef == null) {
      issues.add(ValidationIssue(
        message:
            'Unknown widget or constructor "${node.fullName}". Names must be explicitly registered.',
        severity: ValidationSeverity.error,
        span: node.span,
        widget: node.fullName,
        suggestion: findClosestMatch(node.fullName,
            <String>{...registry.widgetNames, ...registry.constructorNames}),
      ));
      for (final PropertyNode p in node.properties) {
        _visitValue(p.value, registry, actions, issues);
      }
      for (final ValueNode a in node.positionalArguments) {
        _visitValue(a, registry, actions, issues);
      }
      return;
    }

    final String defName = (widgetDef ?? ctorDef)!.name;
    final List<PropertyDefinition> properties =
        widgetDef?.properties ?? ctorDef!.properties;
    final List<PropertyDefinition> positionalParameters =
        widgetDef?.positionalParameters ?? ctorDef!.positionalParameters;
    final Set<String> propertyNames =
        widgetDef?.propertyNames ?? ctorDef!.propertyNames;

    final Set<String> providedNames = <String>{};
    final Set<String> duplicates = <String>{};
    for (final PropertyNode p in node.properties) {
      if (!providedNames.add(p.name)) {
        duplicates.add(p.name);
      }
      if (!propertyNames.contains(p.name)) {
        issues.add(ValidationIssue(
          message: 'Unknown property "${p.name}" for "$defName".',
          severity: ValidationSeverity.error,
          span: p.span,
          widget: defName,
          property: p.name,
          suggestion: findClosestMatch(p.name, propertyNames),
        ));
      }
      _visitValue(p.value, registry, actions, issues);
    }
    for (final String duplicate in duplicates) {
      issues.add(ValidationIssue(
        message: 'Duplicate property "$duplicate" for "$defName".',
        severity: ValidationSeverity.error,
        span: node.span,
        widget: defName,
        property: duplicate,
      ));
    }
    for (final PropertyDefinition propDef in properties) {
      if (propDef.isRequired && !providedNames.contains(propDef.name)) {
        issues.add(ValidationIssue(
          message:
              'Missing required property "${propDef.name}" for "$defName".',
          severity: ValidationSeverity.error,
          span: node.span,
          widget: defName,
          property: propDef.name,
        ));
      }
    }

    if (positionalParameters.isEmpty && node.positionalArguments.isNotEmpty) {
      issues.add(ValidationIssue(
        message: '"$defName" does not accept positional arguments.',
        severity: ValidationSeverity.error,
        span: node.span,
        widget: defName,
      ));
    } else if (node.positionalArguments.length > positionalParameters.length) {
      issues.add(ValidationIssue(
        message:
            '"$defName" accepts at most ${positionalParameters.length} positional argument(s), '
            'got ${node.positionalArguments.length}.',
        severity: ValidationSeverity.error,
        span: node.span,
        widget: defName,
      ));
    } else {
      for (int i = 0; i < positionalParameters.length; i++) {
        if (i >= node.positionalArguments.length) {
          if (positionalParameters[i].isRequired) {
            issues.add(ValidationIssue(
              message:
                  'Missing required positional argument #$i ("${positionalParameters[i].name}") for "$defName".',
              severity: ValidationSeverity.error,
              span: node.span,
              widget: defName,
              property: positionalParameters[i].name,
            ));
          }
        } else {
          _visitValue(node.positionalArguments[i], registry, actions, issues);
        }
      }
    }
  }

  void _visitAction(WidgetNode node, DynamicWidgetRegistry registry,
      ActionRegistry? actions, List<ValidationIssue> issues) {
    if (node.positionalArguments.isEmpty) {
      issues.add(ValidationIssue(
        message: 'action(...) requires a name, e.g. action("login").',
        severity: ValidationSeverity.error,
        span: node.span,
        widget: 'action',
      ));
      return;
    }
    final ValueNode nameNode = node.positionalArguments.first;
    if (nameNode is StringValueNode &&
        actions != null &&
        !actions.has(nameNode.value)) {
      issues.add(ValidationIssue(
        message:
            'Unknown action "${nameNode.value}". Actions must be explicitly registered.',
        severity: ValidationSeverity.error,
        span: nameNode.span,
        widget: 'action',
        suggestion: findClosestMatch(nameNode.value, actions.names),
      ));
    }
    if (node.positionalArguments.length > 1) {
      _visitValue(node.positionalArguments[1], registry, actions, issues);
    }
  }
}
