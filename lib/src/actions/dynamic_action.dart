/// A resolved `action("name")` / `action("name", {...})` call from the DSL.
///
/// This is an inert data value — a name plus already-evaluated arguments —
/// produced by the value resolver. It only becomes a real callback when a
/// widget property binds it against an [ActionRegistry] (see
/// `CallbackResolver`), which is the single choke point where remote UI is
/// allowed to trigger host behavior.
class DynamicAction {
  const DynamicAction(this.name, [this.arguments = const <String, Object?>{}]);

  final String name;
  final Map<String, Object?> arguments;

  @override
  String toString() => 'action("$name", $arguments)';
}
