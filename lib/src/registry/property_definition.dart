/// Transforms an already-generically-resolved property value (a plain
/// Dart value, Color, Widget, enum instance, etc. — never raw AST) into the
/// exact type a widget/constructor expects. Return the input unchanged if
/// no conversion is needed. Throw [PropertyResolutionException] (or let a
/// [TypeError] surface, which the resolver wraps) to reject an invalid
/// value.
typedef PropertyConverter = Object? Function(Object? value);

/// Validates an already-converted property value. Return `null` if valid,
/// or a human-readable reason if not (surfaced verbatim in the resulting
/// [PropertyResolutionException]).
typedef PropertyValidator = String? Function(Object? value);

/// Describes one named or positional argument accepted by a registered
/// widget or value constructor: its expected type, whether it's required,
/// its default, and optional conversion/validation hooks.
///
/// This is the single source of truth the resolver uses to catch, before a
/// single Flutter widget is built:
///  * unknown properties (not declared on the definition)
///  * missing required properties
///  * values that don't match [type] (after [converter] has had a chance
///    to coerce them)
///  * values that fail [validator]
class PropertyDefinition {
  const PropertyDefinition({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.hasDefault = false,
    this.defaultValue,
    this.converter,
    this.validator,
    this.description,
  });

  /// Convenience constructor for an optional property with a default
  /// value, which implies [hasDefault].
  const PropertyDefinition.withDefault({
    required this.name,
    required this.type,
    required this.defaultValue,
    this.converter,
    this.validator,
    this.description,
  })  : isRequired = false,
        hasDefault = true;

  final String name;

  /// Expected runtime [Type] after conversion, used both for documentation
  /// and for a final safety-net type check.
  final Type type;

  final bool isRequired;

  /// Whether [defaultValue] should be applied when the property is absent.
  /// Distinguished from "absent means null" so a property can legitimately
  /// default to `null` versus not appearing in resolved arguments at all.
  final bool hasDefault;
  final Object? defaultValue;

  final PropertyConverter? converter;
  final PropertyValidator? validator;

  /// Short human-readable description, surfaced by tooling (e.g. a future
  /// schema export for server-side payload validation).
  final String? description;
}
