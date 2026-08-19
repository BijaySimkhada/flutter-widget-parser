import 'dart:async';

import 'package:flutter/widgets.dart';

/// A registered, host-defined side effect (navigation, API call, state
/// update, analytics event...) that remote UI can trigger by name.
///
/// [arguments] are already-resolved, safe values — plain literals or the
/// result of evaluating `$variable.path` expressions against the host's
/// [DynamicDataContext]. There is no way for remote source text to invoke
/// anything other than a callback the host explicitly registered here.
typedef DynamicActionCallback = FutureOr<void> Function(
  BuildContext context,
  Map<String, Object?> arguments,
);

/// An allowlist of named callbacks that `action("name")` /
/// `action("name", {...})` in the DSL may invoke.
///
/// Actions are looked up strictly by name: an `action("logout")` call for
/// an unregistered `"logout"` action throws a
/// [WidgetResolutionException]-style error at build time rather than
/// silently doing nothing or falling back to any kind of dynamic dispatch.
class ActionRegistry {
  ActionRegistry({ActionRegistry? parent}) : _parent = parent;

  final ActionRegistry? _parent;
  final Map<String, DynamicActionCallback> _actions =
      <String, DynamicActionCallback>{};

  /// Registers [name] so `action("$name")` in source text resolves to
  /// [callback]. Overwrites any existing registration for [name].
  void register(String name, DynamicActionCallback callback) {
    _actions[name] = callback;
  }

  /// Removes a registration, if present.
  void unregister(String name) => _actions.remove(name);

  bool has(String name) =>
      _actions.containsKey(name) || (_parent?.has(name) ?? false);

  DynamicActionCallback? lookup(String name) =>
      _actions[name] ?? _parent?.lookup(name);

  Iterable<String> get names => <String>{..._actions.keys, ...?_parent?.names};

  /// Creates a child registry that falls back to this one for names it
  /// doesn't define itself — useful for scoping a screen-specific action
  /// on top of a shared app-wide registry without mutating it.
  ActionRegistry fork() => ActionRegistry(parent: this);
}
