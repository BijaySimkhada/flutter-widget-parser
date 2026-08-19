import 'package:flutter/widgets.dart';

import '../context/dynamic_build_context.dart';
import 'property_definition.dart';
import 'resolved_arguments.dart';

/// Builds a value of type [T] from fully-resolved arguments. Shared shape
/// for both widget construction ([WidgetDefinition], `T = Widget`) and
/// value-constructor construction ([ConstructorDefinition], `T = Object?`
/// — e.g. `EdgeInsets.all(16)`, `Color(0xFF2196F3)`).
///
/// Registering a new widget or constructor never requires touching the
/// lexer, parser, or resolver — it's purely a matter of adding one of
/// these to a [DynamicWidgetRegistry], which is what makes the system
/// extensible without modifying core parsing code.
class CallableDefinition<T> {
  const CallableDefinition({
    required this.name,
    required this.builder,
    this.properties = const <PropertyDefinition>[],
    this.positionalParameters = const <PropertyDefinition>[],
    this.description,
  });

  /// Full registry key, e.g. `Container` or `EdgeInsets.symmetric`.
  final String name;

  final T Function(DynamicBuildContext context, ResolvedArguments args) builder;

  /// Accepted named arguments.
  final List<PropertyDefinition> properties;

  /// Accepted positional arguments, in order.
  final List<PropertyDefinition> positionalParameters;

  final String? description;

  PropertyDefinition? propertyByName(String propertyName) {
    for (final PropertyDefinition p in properties) {
      if (p.name == propertyName) return p;
    }
    return null;
  }

  Set<String> get propertyNames =>
      properties.map((PropertyDefinition p) => p.name).toSet();
}

/// A registered Flutter widget, e.g. `Container`, `Row`, `Image.network`.
typedef WidgetDefinition = CallableDefinition<Widget>;

/// A registered non-widget value constructor, e.g. `EdgeInsets.all`,
/// `Color`, `BorderRadius.circular`, `TextStyle`.
typedef ConstructorDefinition = CallableDefinition<Object?>;
