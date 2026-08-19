import 'source_span.dart';

/// Base type for every error raised by the dynamic widget parser pipeline.
///
/// Every exception carries as much structured context as is available so
/// that host applications (and developers authoring remote UI payloads) get
/// actionable diagnostics instead of a bare message.
abstract class DynamicParserException implements Exception {
  DynamicParserException(
    this.message, {
    this.span,
    this.expected,
    this.actual,
    this.widget,
    this.property,
    this.suggestion,
  });

  /// Human readable description of what went wrong.
  final String message;

  /// Where in the original source this error occurred, if known.
  final SourceSpan? span;

  /// What the parser/resolver expected to find.
  final String? expected;

  /// What was actually found.
  final String? actual;

  /// The widget/constructor name this error relates to, if any.
  final String? widget;

  /// The property name this error relates to, if any.
  final String? property;

  /// An optional "did you mean X?" suggestion for typos.
  final String? suggestion;

  /// Short machine-friendly category name, e.g. `LexerException`.
  String get category => runtimeType.toString();

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer()..writeln('$category: $message');
    if (widget != null) buffer.writeln('  Widget: $widget');
    if (property != null) buffer.writeln('  Property: $property');
    if (expected != null) buffer.writeln('  Expected: $expected');
    if (actual != null) buffer.writeln('  Actual: $actual');
    if (suggestion != null) buffer.writeln('  Did you mean: $suggestion?');
    final SourceSpan? s = span;
    if (s != null) {
      buffer
        ..writeln('  Location: ${s.start}')
        ..writeln('  ---')
        ..writeln('  ${s.caretSnippet()}')
        ..writeln('  ---');
    }
    return buffer.toString().trimRight();
  }
}

/// Raised while tokenizing malformed source (bad escape sequence,
/// unterminated string, invalid character, etc).
class LexerException extends DynamicParserException {
  LexerException(
    super.message, {
    super.span,
    super.expected,
    super.actual,
  });
}

/// Raised while turning tokens into an AST (unexpected token, unbalanced
/// brackets, malformed argument list, depth limit exceeded, etc).
class SyntaxException extends DynamicParserException {
  SyntaxException(
    super.message, {
    super.span,
    super.expected,
    super.actual,
  });
}

/// Raised by the semantic validation pass: unknown widgets/properties,
/// wrong types, missing required properties, exceeded limits.
class ValidationException extends DynamicParserException {
  ValidationException(
    super.message, {
    super.span,
    super.expected,
    super.actual,
    super.widget,
    super.property,
    super.suggestion,
  });
}

/// Raised when a widget or value-constructor name cannot be resolved
/// against the registry (i.e. it is not allowlisted).
class WidgetResolutionException extends DynamicParserException {
  WidgetResolutionException(
    super.message, {
    super.span,
    super.widget,
    super.suggestion,
  });
}

/// Raised when a specific property's value cannot be resolved/converted
/// to the type the target widget/constructor expects.
class PropertyResolutionException extends DynamicParserException {
  PropertyResolutionException(
    super.message, {
    super.span,
    super.expected,
    super.actual,
    super.widget,
    super.property,
    super.suggestion,
  });
}

/// Raised while parsing or evaluating a `$variable.path` expression.
class ExpressionException extends DynamicParserException {
  ExpressionException(
    super.message, {
    super.span,
    super.expected,
    super.actual,
  });
}
