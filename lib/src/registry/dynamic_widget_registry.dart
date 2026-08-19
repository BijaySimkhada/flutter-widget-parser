import 'package:flutter/widgets.dart';

import '../context/dynamic_build_context.dart';
import 'property_definition.dart';
import 'resolved_arguments.dart';
import 'widget_definition.dart';

/// Outcome of a value-registry lookup (`Colors.blue`, `MainAxisAlignment.
/// center`, `AppColors.primary`, ...). Distinguishes "registered and
/// resolved to null" from "not registered at all" — the latter is a
/// security-relevant rejection (see [WidgetResolutionException]), the
/// former is a legitimate value.
class ValueLookupResult {
  const ValueLookupResult.found(this.value) : isFound = true;
  const ValueLookupResult.notFound()
      : isFound = false,
        value = null;

  final bool isFound;
  final Object? value;
}

/// Convenience signature matching the simplified registration API shown in
/// the package README — a lighter-weight alternative to building a full
/// [WidgetDefinition] by hand when you don't need per-property validation.
typedef SimpleWidgetBuilder = Widget Function(
  DynamicBuildContext context,
  Map<String, Object?> properties,
  List<Widget> children,
);

/// The central allowlist the whole pipeline resolves names against:
/// widgets, value constructors, enum/constant values, and aliases.
///
/// Nothing is reachable through the parser/resolver unless it was
/// registered here first — this is the mechanism that makes "never
/// instantiate arbitrary classes" an structural guarantee rather than a
/// convention. See the README's "Security model" section.
///
/// Supports simple dependency injection via [fork]: create a child
/// registry seeded from a shared base (e.g. built-ins) and layer
/// app-specific or even screen-specific widgets/values on top, without
/// mutating the shared parent. Builder closures registered on a registry
/// can themselves close over injected services (repositories, view
/// models, etc.), which is how DI is threaded into widget construction.
class DynamicWidgetRegistry {
  DynamicWidgetRegistry({DynamicWidgetRegistry? parent}) : _parent = parent;

  final DynamicWidgetRegistry? _parent;

  final Map<String, WidgetDefinition> _widgets = <String, WidgetDefinition>{};
  final Map<String, ConstructorDefinition> _constructors =
      <String, ConstructorDefinition>{};
  final Map<String, Object? Function()> _values =
      <String, Object? Function()>{};
  final Map<String, String> _aliases = <String, String>{};

  // ---------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------

  void registerWidgetDefinition(WidgetDefinition definition) {
    _widgets[definition.name] = definition;
  }

  /// Lightweight widget registration for application code:
  /// ```dart
  /// registry.registerWidget('UserCard', (context, properties, children) {
  ///   return UserCard(name: properties['name'] as String?);
  /// });
  /// ```
  void registerWidget(
    String name,
    SimpleWidgetBuilder builder, {
    List<PropertyDefinition> properties = const <PropertyDefinition>[],
    String? description,
  }) {
    registerWidgetDefinition(
      WidgetDefinition(
        name: name,
        properties: properties,
        description: description,
        builder: (DynamicBuildContext context, ResolvedArguments args) =>
            builder(context, args.named,
                args.get<List<Widget>>('children') ?? const <Widget>[]),
      ),
    );
  }

  WidgetDefinition? lookupWidget(String name) =>
      _findWidget(_resolveAlias(name));

  WidgetDefinition? _findWidget(String name) {
    DynamicWidgetRegistry? level = this;
    while (level != null) {
      final WidgetDefinition? def = level._widgets[name];
      if (def != null) return def;
      level = level._parent;
    }
    return null;
  }

  Iterable<String> get widgetNames sync* {
    yield* _widgets.keys;
    if (_parent != null) yield* _parent.widgetNames;
  }

  // ---------------------------------------------------------------------
  // Value constructors (EdgeInsets.all, Color, TextStyle, ...)
  // ---------------------------------------------------------------------

  void registerConstructor(ConstructorDefinition definition) {
    _constructors[definition.name] = definition;
  }

  ConstructorDefinition? lookupConstructor(String name) =>
      _findConstructor(_resolveAlias(name));

  ConstructorDefinition? _findConstructor(String name) {
    DynamicWidgetRegistry? level = this;
    while (level != null) {
      final ConstructorDefinition? def = level._constructors[name];
      if (def != null) return def;
      level = level._parent;
    }
    return null;
  }

  Iterable<String> get constructorNames sync* {
    yield* _constructors.keys;
    if (_parent != null) yield* _parent.constructorNames;
  }

  // ---------------------------------------------------------------------
  // Values (colors, enums, app constants)
  // ---------------------------------------------------------------------

  /// Registers a constant/computed value reachable by dotted path, e.g.
  /// ```dart
  /// registry.registerValue('AppColors.primary', () => AppColors.primary);
  /// ```
  void registerValue(String path, Object? Function() factory) {
    _values[path] = factory;
  }

  /// Registers every member of a Dart enum under `EnumName.memberName`,
  /// making enum resolution registry-driven rather than a hardcoded
  /// switch statement.
  void registerEnum<T extends Enum>(String enumName, List<T> values) {
    for (final T value in values) {
      registerValue('$enumName.${value.name}', () => value);
    }
  }

  ValueLookupResult resolveValue(String path) {
    DynamicWidgetRegistry? level = this;
    while (level != null) {
      final Object? Function()? factory = level._values[path];
      if (factory != null) return ValueLookupResult.found(factory());
      level = level._parent;
    }
    return const ValueLookupResult.notFound();
  }

  bool hasValue(String path) => resolveValue(path).isFound;

  Iterable<String> get valueNames sync* {
    yield* _values.keys;
    if (_parent != null) yield* _parent.valueNames;
  }

  // ---------------------------------------------------------------------
  // Aliases
  // ---------------------------------------------------------------------

  /// Registers [alias] so parsing `alias(...)` behaves as if [target] had
  /// been written instead, e.g. `registerAlias('PrimaryButton',
  /// 'AppPrimaryButton')`. Works for both widget and constructor names.
  void registerAlias(String alias, String target) {
    _aliases[alias] = target;
  }

  String _resolveAlias(String name) {
    String current = name;
    final Set<String> seen = <String>{};
    while (seen.add(current)) {
      final String? target = _findAliasTarget(current);
      if (target == null) return current;
      current = target;
    }
    return current; // Alias cycle detected; stop rather than loop forever.
  }

  String? _findAliasTarget(String name) {
    DynamicWidgetRegistry? level = this;
    while (level != null) {
      if (level._aliases.containsKey(name)) return level._aliases[name];
      level = level._parent;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Composition
  // ---------------------------------------------------------------------

  /// Creates a child registry that inherits everything from this one but
  /// can register additional/overriding widgets, constructors, values, and
  /// aliases without mutating the parent. Ideal for per-app or per-test
  /// customization layered on top of a shared set of built-ins.
  DynamicWidgetRegistry fork() => DynamicWidgetRegistry(parent: this);
}
