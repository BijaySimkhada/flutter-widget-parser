import '../errors/source_span.dart';

/// Every kind of lexeme the DSL understands. Kept intentionally small and
/// closed — the language is a controlled subset of Dart, not all of Dart.
enum TokenType {
  identifier,
  numberInt,
  numberDouble,
  string,
  booleanLiteral,
  nullLiteral,

  comma,
  colon,
  dot,
  question,
  questionQuestion,
  dollar,

  lParen,
  rParen,
  lBracket,
  rBracket,
  lBrace,
  rBrace,

  equalEqual,
  notEqual,
  greater,
  less,
  greaterEqual,
  lessEqual,
  andAnd,
  orOr,
  bang,
  plus,
  minus,
  star,
  slash,

  eof,
}

/// A single string-literal segment: either a literal chunk of text, or a
/// `$identifier.path` / `${expression}` interpolation hole. The parser turns
/// the `expression` segments into real [ExpressionNode]s.
class StringInterpolationPart {
  const StringInterpolationPart.literal(this.text)
      : isExpression = false,
        isBraced = false;

  /// `$identifier.path` form — always a bare variable path, no operators.
  const StringInterpolationPart.variablePath(this.text)
      : isExpression = true,
        isBraced = false;

  /// `${ ... }` form — arbitrary expression source, may contain operators
  /// and its own `$variable` references.
  const StringInterpolationPart.bracedExpression(this.text)
      : isExpression = true,
        isBraced = true;

  final bool isExpression;
  final bool isBraced;
  final String text;
}

/// A lexed token, carrying enough position information to build precise
/// [SourceSpan]s for downstream errors.
class Token {
  const Token({
    required this.type,
    required this.lexeme,
    required this.start,
    required this.end,
    this.stringValue,
    this.interpolationParts,
    this.numValue,
  });

  final TokenType type;

  /// The raw source text that produced this token.
  final String lexeme;

  final SourceLocation start;
  final SourceLocation end;

  /// Decoded string value (escapes resolved) for [TokenType.string] tokens
  /// that contain no interpolation.
  final String? stringValue;

  /// Populated instead of [stringValue] when the string literal contains
  /// `$name` / `${expr}` interpolation.
  final List<StringInterpolationPart>? interpolationParts;

  /// Decoded numeric value for [TokenType.numberInt]/[TokenType.numberDouble].
  final num? numValue;

  SourceSpan span(String source) =>
      SourceSpan(start: start, end: end, source: source);

  @override
  String toString() => '${type.name}(${lexeme.replaceAll('\n', '\\n')})';
}
