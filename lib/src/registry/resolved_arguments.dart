/// The fully-resolved (AST already evaluated, types already converted and
/// validated against [PropertyDefinition]s) arguments passed to a
/// [WidgetDefinition]/[ConstructorDefinition] builder function.
///
/// By the time a builder sees a [ResolvedArguments], every value is a
/// plain Dart object — `Color`, `EdgeInsets`, `Widget`, `List<Widget>`,
/// `String`, callbacks, etc. There is no AST left to walk and no way to
/// reach anything outside of what was explicitly resolved.
class ResolvedArguments {
  const ResolvedArguments({
    this.named = const <String, Object?>{},
    this.positional = const <Object?>[],
  });

  final Map<String, Object?> named;
  final List<Object?> positional;

  bool has(String name) => named.containsKey(name);

  /// Reads a named property, cast to [T]. Returns `null` if absent (which
  /// is safe for nullable `T`) — required-ness is enforced earlier, during
  /// resolution, not here.
  T? get<T>(String name) => named[name] as T?;

  /// Like [get] but with a fallback used when the property is absent.
  T getOr<T>(String name, T fallback) => (named[name] as T?) ?? fallback;

  /// Reads a positional argument by index, cast to [T].
  T? positionalAt<T>(int index) =>
      index < positional.length ? positional[index] as T? : null;
}
