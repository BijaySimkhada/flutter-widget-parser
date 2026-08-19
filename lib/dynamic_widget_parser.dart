/// A production-grade, security-first dynamic Flutter widget parser for
/// server-driven UI.
///
/// See the package README for the full architecture, supported syntax,
/// security model, and extension guide. The main entry point is
/// [DynamicWidgetParser].
library;

export 'src/actions/action_registry.dart';
export 'src/actions/callback_resolver.dart';
export 'src/actions/dynamic_action.dart';
export 'src/ast/ast.dart';
export 'src/cache/dynamic_parser_cache.dart';
export 'src/cache/lru_cache.dart';
export 'src/config/dynamic_error_behavior.dart';
export 'src/config/dynamic_parser_config.dart';
export 'src/context/dynamic_build_context.dart';
export 'src/dynamic_widget_parser_base.dart';
export 'src/errors/dynamic_parser_exception.dart';
export 'src/errors/source_span.dart';
export 'src/expressions/dynamic_data_context.dart';
export 'src/expressions/expression_evaluator.dart';
export 'src/lexer/dynamic_lexer.dart';
export 'src/lexer/token.dart';
export 'src/parser/dynamic_parser.dart';
export 'src/parser/parser_limits.dart';
export 'src/registry/registry.dart';
export 'src/resolver/color_parser.dart';
export 'src/resolver/value_converter.dart';
export 'src/resolver/value_resolver.dart';
export 'src/validation/semantic_validator.dart';
export 'src/validation/validation_result.dart';
export 'src/widgets/builtin/register_builtins.dart';
export 'src/widgets/widget_factory.dart';
