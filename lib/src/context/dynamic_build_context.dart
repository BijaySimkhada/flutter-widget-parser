import 'package:flutter/widgets.dart';

import '../actions/action_registry.dart';
import '../config/dynamic_parser_config.dart';
import '../expressions/dynamic_data_context.dart';
import '../registry/dynamic_widget_registry.dart';

/// Everything the resolver and widget factory need to turn AST into a real
/// widget tree, bundled together so it can be threaded through recursive
/// `build`/`resolve` calls without long parameter lists.
///
/// This deliberately layers *on top of* Flutter's own [BuildContext]
/// (exposed as [buildContext]) rather than replacing it — generated
/// widgets should use `Theme.of(dynamicContext.buildContext)`,
/// `MediaQuery.of(...)`, etc. exactly like hand-written widgets do. See
/// the README's "Theme integration" section.
class DynamicBuildContext {
  const DynamicBuildContext({
    required this.buildContext,
    required this.registry,
    required this.data,
    required this.actions,
    required this.config,
  });

  final BuildContext buildContext;
  final DynamicWidgetRegistry registry;
  final DynamicDataContext data;
  final ActionRegistry actions;
  final DynamicParserConfig config;

  DynamicBuildContext withBuildContext(BuildContext newBuildContext) {
    return DynamicBuildContext(
      buildContext: newBuildContext,
      registry: registry,
      data: data,
      actions: actions,
      config: config,
    );
  }
}
