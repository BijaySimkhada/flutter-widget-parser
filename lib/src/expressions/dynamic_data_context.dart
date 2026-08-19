/// Implement this to expose a plain Dart object's fields to the expression
/// language without reflection. This is the *only* sanctioned way for a
/// `$variable.path` expression to reach into a host-application object —
/// anything not listed in [toDynamicValues] is simply invisible to remote
/// UI, by construction.
///
/// ```dart
/// class UserSummary implements DynamicExposable {
///   UserSummary({required this.name, required this.isLoggedIn});
///   final String name;
///   final bool isLoggedIn;
///
///   @override
///   Map<String, Object?> toDynamicValues() => {
///     'name': name,
///     'isLoggedIn': isLoggedIn,
///   };
/// }
/// ```
abstract class DynamicExposable {
  Map<String, Object?> toDynamicValues();
}

/// The explicit, host-controlled set of variables visible to `$path`
/// expressions in a single parse/build. Nothing outside of [values] is
/// reachable — there is no ambient access to the widget tree, app state,
/// or Dart runtime.
///
/// Values may be:
///  * primitives (`String`, `num`, `bool`, `null`)
///  * `Map<String, Object?>` (traversed by key)
///  * a [DynamicExposable] (traversed via `toDynamicValues()`)
///  * a `List` (indexable with integer path segments, e.g. `$items.0.name`)
///
/// Any other object type is a dead end for path traversal: resolving a
/// path segment against it returns "not found" rather than reaching into
/// its fields via reflection (which this package never uses).
class DynamicDataContext {
  const DynamicDataContext({this.values = const <String, Object?>{}});

  final Map<String, Object?> values;

  static const DynamicDataContext empty = DynamicDataContext();

  DynamicDataContext merge(Map<String, Object?> overrides) {
    return DynamicDataContext(
        values: <String, Object?>{...values, ...overrides});
  }

  /// Resolves a dotted path (e.g. `['user', 'profile', 'name']`) against
  /// [values]. Returns [PathLookupResult.notFound] if any segment along the
  /// way is missing or unreachable — this is a normal, non-throwing outcome
  /// so expressions like `$user.nickname ?? "Guest"` work as expected.
  PathLookupResult resolve(List<String> path) {
    if (path.isEmpty) return const PathLookupResult.notFound();
    if (!values.containsKey(path.first)) {
      return const PathLookupResult.notFound();
    }
    Object? current = values[path.first];
    for (final String segment in path.skip(1)) {
      final PathLookupResult step = _step(current, segment);
      if (!step.found) return const PathLookupResult.notFound();
      current = step.value;
    }
    return PathLookupResult.of(current);
  }

  static PathLookupResult _step(Object? current, String segment) {
    if (current is Map<String, Object?>) {
      if (!current.containsKey(segment)) {
        return const PathLookupResult.notFound();
      }
      return PathLookupResult.of(current[segment]);
    }
    if (current is DynamicExposable) {
      final Map<String, Object?> exposed = current.toDynamicValues();
      if (!exposed.containsKey(segment)) {
        return const PathLookupResult.notFound();
      }
      return PathLookupResult.of(exposed[segment]);
    }
    if (current is List) {
      final int? index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) {
        return const PathLookupResult.notFound();
      }
      return PathLookupResult.of(current[index]);
    }
    return const PathLookupResult.notFound();
  }
}

/// Outcome of a variable path lookup. Distinguishes "found a null value"
/// from "path does not exist", which matters for `??` semantics.
class PathLookupResult {
  const PathLookupResult.of(this.value) : found = true;
  const PathLookupResult.notFound()
      : found = false,
        value = null;

  final bool found;
  final Object? value;
}
