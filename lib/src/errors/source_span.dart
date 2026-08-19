/// A single point in the original source string.
class SourceLocation {
  const SourceLocation({
    required this.offset,
    required this.line,
    required this.column,
  });

  /// Zero-based absolute character offset into the source.
  final int offset;

  /// One-based line number.
  final int line;

  /// One-based column number.
  final int column;

  @override
  String toString() => 'line $line, column $column';
}

/// A range in the original source string, used to attach precise
/// diagnostics (errors, debug output) back to the text that produced them.
class SourceSpan {
  const SourceSpan({
    required this.start,
    required this.end,
    required this.source,
  });

  final SourceLocation start;
  final SourceLocation end;

  /// The full original source string, kept so errors can render a snippet.
  final String source;

  /// Returns the line of source text containing [start], for error display.
  String get sourceLine {
    final int lineStart =
        source.lastIndexOf('\n', (start.offset - 1).clamp(0, source.length)) +
            1;
    int lineEnd = source.indexOf('\n', start.offset);
    if (lineEnd == -1) lineEnd = source.length;
    return source.substring(lineStart, lineEnd);
  }

  /// A caret-annotated snippet, e.g.:
  /// ```
  ///   color: Colors.blrequarg,
  ///          ^
  /// ```
  String caretSnippet() {
    final String line = sourceLine;
    final String caret = ' ' * (start.column - 1) + '^';
    return '$line\n$caret';
  }

  @override
  String toString() => '${start.line}:${start.column}';
}
