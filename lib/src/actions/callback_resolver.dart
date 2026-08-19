import 'package:flutter/widgets.dart';

import '../context/dynamic_build_context.dart';
import 'dynamic_action.dart';

/// Binds a resolved [DynamicAction] value to a real Flutter callback,
/// looked up against [DynamicBuildContext.actions] at call time.
///
/// Used inside widget builders (not as a [PropertyConverter], since binding
/// needs [DynamicBuildContext] — the current [BuildContext] plus the action
/// registry — which a plain value converter doesn't have access to):
/// ```dart
/// onPressed: CallbackResolver.voidCallback(args.get<DynamicAction>('onPressed'), context),
/// ```
///
/// The action name is already validated against the registry when
/// `action(...)` is resolved (see `built_in_constructors.dart`), so a
/// missing registration surfaces immediately as a build-time error rather
/// than silently doing nothing when tapped.
class CallbackResolver {
  const CallbackResolver._();

  static VoidCallback? voidCallback(
      DynamicAction? action, DynamicBuildContext context) {
    if (action == null) return null;
    return () {
      context.actions
          .lookup(action.name)
          ?.call(context.buildContext, action.arguments);
    };
  }

  static ValueChanged<T>? valueChanged<T>(
      DynamicAction? action, DynamicBuildContext context) {
    if (action == null) return null;
    return (T newValue) {
      context.actions.lookup(action.name)?.call(
        context.buildContext,
        <String, Object?>{...action.arguments, 'value': newValue},
      );
    };
  }
}
