import '../errors/source_span.dart';

enum ValidationSeverity { error, warning }

/// One structured finding from [SemanticValidator]/`DynamicWidgetParser.validate`.
/// Deliberately mirrors the shape of [DynamicParserException] so the two
/// present errors consistently whether you validated ahead of time or hit
/// an error during an actual build.
class ValidationIssue {
  const ValidationIssue({
    required this.message,
    required this.severity,
    this.span,
    this.widget,
    this.property,
    this.suggestion,
  });

  final String message;
  final ValidationSeverity severity;
  final SourceSpan? span;
  final String? widget;
  final String? property;
  final String? suggestion;

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('[${severity.name}] $message');
    if (widget != null) buffer.write(' (widget: $widget)');
    if (property != null) buffer.write(' (property: $property)');
    if (suggestion != null) buffer.write(' — did you mean "$suggestion"?');
    if (span != null) buffer.write(' at ${span!.start}');
    return buffer.toString();
  }
}

/// The result of validating a source string against a registry *before*
/// attempting to build a widget tree from it — useful for server-driven UI
/// pipelines that want to reject or flag a malformed payload up front.
///
/// Validation only catches what's staticallly knowable: unknown
/// widgets/constructors/values, unknown/missing/duplicate properties, and
/// unregistered action names (when the name is a literal string, not a
/// computed `$expression`). It does not evaluate `$expression`s (there's no
/// `DynamicDataContext` yet) and does not run property-level
/// converters/validators (e.g. "opacity must be between 0 and 1") — those
/// still run at build time. See the README's "Validation API" section.
class ValidationResult {
  const ValidationResult(this.issues);

  final List<ValidationIssue> issues;

  bool get isValid => errors.isEmpty;

  List<ValidationIssue> get errors => issues
      .where((ValidationIssue i) => i.severity == ValidationSeverity.error)
      .toList(growable: false);

  List<ValidationIssue> get warnings => issues
      .where((ValidationIssue i) => i.severity == ValidationSeverity.warning)
      .toList(growable: false);

  @override
  String toString() =>
      issues.map((ValidationIssue i) => i.toString()).join('\n');
}
