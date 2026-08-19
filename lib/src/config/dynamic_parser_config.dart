import 'package:flutter/widgets.dart';

import '../parser/parser_limits.dart';
import 'dynamic_error_behavior.dart';

/// Signature for a widget substituted in place of a subtree that failed to
/// build, when [DynamicParserConfig.errorBehavior] is [DynamicErrorBehavior.fallback]
/// or [DynamicErrorBehavior.ignore].
typedef DynamicFallbackWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// Signature for observing errors encountered during build, independent of
/// how they're visually recovered from. Never throws from the parser's
/// perspective — this is purely a reporting hook (logging, analytics,
/// crash reporting).
typedef DynamicErrorObserver = void Function(
    Object error, StackTrace? stackTrace);

/// Top-level configuration for a single [DynamicWidgetParser] invocation:
/// resource limits, error-recovery policy, caching, and debug tracing.
///
/// This is intentionally the *only* Flutter-aware configuration type in the
/// parsing pipeline — [DynamicParserLimits] (lexer/parser resource limits)
/// stays pure Dart so those layers remain testable without Flutter.
class DynamicParserConfig {
  const DynamicParserConfig({
    this.limits = const DynamicParserLimits(),
    this.errorBehavior = DynamicErrorBehavior.throwError,
    this.fallbackWidgetBuilder = _defaultFallbackBuilder,
    this.onError,
    this.enableDebugLogging = false,
    this.enableAstCache = true,
    this.astCacheMaxEntries = 100,
  });

  /// Resource limits enforced by the lexer/parser.
  final DynamicParserLimits limits;

  /// What to do when a node fails to resolve/build.
  final DynamicErrorBehavior errorBehavior;

  /// Widget used to replace a failing subtree. Only consulted when
  /// [errorBehavior] is [DynamicErrorBehavior.fallback] or
  /// [DynamicErrorBehavior.ignore].
  final DynamicFallbackWidgetBuilder fallbackWidgetBuilder;

  /// Optional error-reporting hook. Called for every recovered error when
  /// [errorBehavior] is [DynamicErrorBehavior.fallback] (never for
  /// [DynamicErrorBehavior.ignore], and irrelevant for
  /// [DynamicErrorBehavior.throwError] since that propagates instead).
  final DynamicErrorObserver? onError;

  /// When true, the parser logs lexing/parsing/build tracing via
  /// `debugPrint`. Off by default — noisy, development-only.
  final bool enableDebugLogging;

  /// Whether [DynamicWidgetParser.parse] should cache parsed ASTs keyed by
  /// source text, avoiding re-lexing/re-parsing unchanged remote UI.
  final bool enableAstCache;

  /// Maximum number of distinct source strings kept in the AST cache.
  final int astCacheMaxEntries;

  static Widget _defaultFallbackBuilder(
      BuildContext context, Object error, StackTrace? stackTrace) {
    return const SizedBox.shrink();
  }

  DynamicParserConfig copyWith({
    DynamicParserLimits? limits,
    DynamicErrorBehavior? errorBehavior,
    DynamicFallbackWidgetBuilder? fallbackWidgetBuilder,
    DynamicErrorObserver? onError,
    bool? enableDebugLogging,
    bool? enableAstCache,
    int? astCacheMaxEntries,
  }) {
    return DynamicParserConfig(
      limits: limits ?? this.limits,
      errorBehavior: errorBehavior ?? this.errorBehavior,
      fallbackWidgetBuilder:
          fallbackWidgetBuilder ?? this.fallbackWidgetBuilder,
      onError: onError ?? this.onError,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      enableAstCache: enableAstCache ?? this.enableAstCache,
      astCacheMaxEntries: astCacheMaxEntries ?? this.astCacheMaxEntries,
    );
  }
}
