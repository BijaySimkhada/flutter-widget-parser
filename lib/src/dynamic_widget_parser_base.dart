import 'package:flutter/widgets.dart';

import 'actions/action_registry.dart';
import 'ast/ast_node.dart';
import 'ast/value_node.dart';
import 'cache/dynamic_parser_cache.dart';
import 'config/dynamic_parser_config.dart';
import 'context/dynamic_build_context.dart';
import 'errors/dynamic_parser_exception.dart';
import 'expressions/dynamic_data_context.dart';
import 'parser/dynamic_parser.dart';
import 'registry/dynamic_widget_registry.dart';
import 'validation/semantic_validator.dart';
import 'validation/validation_result.dart';
import 'widgets/builtin/register_builtins.dart';
import 'widgets/widget_factory.dart';

/// Public entry point for the package: turns Flutter-like DSL source text
/// into a real widget tree.
///
/// ```dart
/// final Widget widget = DynamicWidgetParser.parse(
///   source: incomingString,
///   context: context,
/// );
/// ```
///
/// The four static methods mirror the pipeline's stages so each can be used
/// independently — [parseToAst] and [buildFromAst] are split out from
/// [parse] specifically to support caching, testing, debugging, and
/// validating a payload before ever touching a [BuildContext] (see
/// [validate]).
class DynamicWidgetParser {
  const DynamicWidgetParser._();

  /// Shared registry pre-populated with every built-in widget/value/
  /// constructor. Fork it (`DynamicWidgetParser.defaultRegistry.fork()`) or
  /// register directly onto it at app startup to add custom widgets
  /// without passing a `registry:` argument to every [parse] call.
  static final DynamicWidgetRegistry defaultRegistry = createStandardRegistry();

  /// Shared action registry used when no `actions:` argument is given.
  static final ActionRegistry defaultActions = ActionRegistry();

  static DynamicParserCache? _defaultCache;

  static DynamicParserCache _defaultCacheFor(DynamicParserConfig config) {
    final DynamicParserCache? existing = _defaultCache;
    if (existing != null && existing.maxEntries == config.astCacheMaxEntries) {
      return existing;
    }
    final DynamicParserCache created =
        DynamicParserCache(maxEntries: config.astCacheMaxEntries);
    _defaultCache = created;
    return created;
  }

  /// Lexes and parses [source] into an AST, applying [DynamicParserConfig.limits].
  /// Always throws (never recovers) on malformed input — [LexerException] or
  /// [SyntaxException] — since there's no widget tree yet to substitute a
  /// fallback into; see [validate] for a non-throwing alternative.
  ///
  /// When [DynamicParserConfig.enableAstCache] is true (the default), the
  /// parsed AST is cached by exact source text so re-parsing identical
  /// payloads is free. Pass an explicit [cache] to use your own instance
  /// instead of the package's shared default.
  static AstNode parseToAst(
    String source, {
    DynamicParserConfig config = const DynamicParserConfig(),
    DynamicParserCache? cache,
  }) {
    final DynamicParserCache? effectiveCache =
        config.enableAstCache ? (cache ?? _defaultCacheFor(config)) : null;
    final ValueNode? cached = effectiveCache?.get(source);
    if (cached != null) {
      if (config.enableDebugLogging) {
        debugPrint(
            '[dynamic_widget_parser] AST cache hit (${source.length} chars).');
      }
      return cached;
    }
    if (config.enableDebugLogging) {
      debugPrint('[dynamic_widget_parser] parsing ${source.length} chars.');
    }
    final ValueNode ast =
        DynamicParser(source, limits: config.limits).parseToAst();
    effectiveCache?.put(source, ast);
    return ast;
  }

  /// Builds a widget tree from an already-parsed [ast] (from [parseToAst]
  /// or a cached value). Per-node error recovery is applied according to
  /// [DynamicParserConfig.errorBehavior] — a failure deep in the tree can
  /// replace just that subtree instead of aborting the whole build.
  static Widget buildFromAst(
    AstNode ast, {
    required BuildContext context,
    DynamicDataContext data = DynamicDataContext.empty,
    DynamicWidgetRegistry? registry,
    ActionRegistry? actions,
    DynamicParserConfig config = const DynamicParserConfig(),
  }) {
    if (ast is! ValueNode) {
      throw ValidationException(
        'buildFromAst expects the root of a value/widget AST, got ${ast.runtimeType}.',
        span: ast.span,
      );
    }
    final DynamicBuildContext buildContext = DynamicBuildContext(
      buildContext: context,
      registry: registry ?? defaultRegistry,
      data: data,
      actions: actions ?? defaultActions,
      config: config,
    );
    return const WidgetFactory().build(ast, buildContext);
  }

  /// Parses [source] and builds it into a widget tree in one call — the
  /// common case. Equivalent to `buildFromAst(parseToAst(source, ...), ...)`.
  static Widget parse({
    required String source,
    required BuildContext context,
    DynamicDataContext? data,
    DynamicWidgetRegistry? registry,
    ActionRegistry? actions,
    DynamicParserConfig? config,
    DynamicParserCache? cache,
  }) {
    final DynamicParserConfig effectiveConfig =
        config ?? const DynamicParserConfig();
    final AstNode ast =
        parseToAst(source, config: effectiveConfig, cache: cache);
    return buildFromAst(
      ast,
      context: context,
      data: data ?? DynamicDataContext.empty,
      registry: registry,
      actions: actions,
      config: effectiveConfig,
    );
  }

  /// Validates [source] against [registry]/[actions] *without* requiring a
  /// [BuildContext] and without building any widgets — suitable for
  /// checking a payload the moment it arrives from a server, before it's
  /// ever handed to [parse]. Returns every issue found, not just the
  /// first; see [ValidationResult] for what it does and doesn't catch.
  static ValidationResult validate(
    String source, {
    DynamicWidgetRegistry? registry,
    ActionRegistry? actions,
    DynamicParserConfig config = const DynamicParserConfig(),
    DynamicParserCache? cache,
  }) {
    try {
      final AstNode ast = parseToAst(source, config: config, cache: cache);
      if (ast is! ValueNode) {
        return ValidationResult(<ValidationIssue>[
          ValidationIssue(
            message: 'The top-level value must be a widget constructor call.',
            severity: ValidationSeverity.error,
            span: ast.span,
          ),
        ]);
      }
      return const SemanticValidator().validate(
        ast,
        registry: registry ?? defaultRegistry,
        actions: actions ?? defaultActions,
      );
    } on DynamicParserException catch (e) {
      return ValidationResult(<ValidationIssue>[
        ValidationIssue(
          message: e.message,
          severity: ValidationSeverity.error,
          span: e.span,
          widget: e.widget,
          property: e.property,
          suggestion: e.suggestion,
        ),
      ]);
    }
  }
}
