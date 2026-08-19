/// How the widget factory should react when a node in the AST fails to
/// resolve/build (unknown widget, invalid property, expression error...).
///
/// Recovery is applied *per node*, not just at the top level: a failure
/// deep in the tree only replaces that subtree, so one malformed card in a
/// list doesn't take down an entire remote-UI screen.
enum DynamicErrorBehavior {
  /// Rethrow the error, aborting the whole build. Best for development and
  /// for [DynamicWidgetParser.validate], where you want to know immediately.
  throwError,

  /// Replace the failing subtree with the widget produced by
  /// `DynamicParserConfig.fallbackWidgetBuilder`, and record the error via
  /// `DynamicParserConfig.onError` if provided. The rest of the tree still
  /// renders normally.
  fallback,

  /// Like [fallback], but never calls `onError` — the failure is swallowed
  /// entirely except for debug logging (if enabled). Use sparingly; errors
  /// should normally be observable somewhere.
  ignore,
}
