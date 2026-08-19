/// Resource limits enforced by the lexer and parser to keep untrusted
/// source text from exhausting memory, stack, or CPU time.
///
/// This type is pure Dart (no Flutter dependency) so the lexer/parser
/// layer stays independently testable and reusable outside Flutter.
class DynamicParserLimits {
  const DynamicParserLimits({
    this.maxSourceLength = 200000,
    this.maxAstDepth = 64,
    this.maxWidgetCount = 5000,
    this.maxListLength = 2000,
    this.maxExpressionDepth = 32,
    this.maxStringLength = 20000,
    this.maxParseDuration = const Duration(seconds: 2),
  });

  /// Maximum number of characters accepted in the source string.
  final int maxSourceLength;

  /// Maximum nesting depth of the AST (widgets within widgets within
  /// lists...). Prevents stack exhaustion from pathological input.
  final int maxAstDepth;

  /// Maximum total number of AST nodes (a proxy for total widget/value
  /// count) accepted in a single parse.
  final int maxWidgetCount;

  /// Maximum number of elements allowed in a single list literal.
  final int maxListLength;

  /// Maximum nesting depth of a single expression (`$a.b`, `1 + 2 * 3`...).
  final int maxExpressionDepth;

  /// Maximum length of a single string literal.
  final int maxStringLength;

  /// Best-effort wall-clock budget for a single parse. Checked between
  /// parser productions (not preemptive) so it bounds pathological inputs
  /// without needing an isolate.
  final Duration maxParseDuration;

  static const DynamicParserLimits unrestricted = DynamicParserLimits(
    maxSourceLength: 1 << 30,
    maxAstDepth: 1 << 20,
    maxWidgetCount: 1 << 20,
    maxListLength: 1 << 20,
    maxExpressionDepth: 1 << 20,
    maxStringLength: 1 << 30,
    maxParseDuration: Duration(minutes: 10),
  );
}
