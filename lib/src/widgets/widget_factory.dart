import 'package:flutter/widgets.dart';

import '../ast/value_node.dart';
import '../context/dynamic_build_context.dart';
import '../resolver/value_resolver.dart';

/// The final stage of the pipeline: turns an AST (already validated) into a
/// real Flutter [Widget] tree. A thin, stateless facade over [ValueResolver]
/// — kept as its own type so the architecture's stages
/// (lexer/parser/AST/registry/resolver/**factory**) each have a concrete,
/// documented entry point, matching `buildFromAst` in the public API.
class WidgetFactory {
  const WidgetFactory();

  static const ValueResolver _resolver = ValueResolver();

  Widget build(ValueNode ast, DynamicBuildContext context) =>
      _resolver.buildRoot(ast, context);
}
