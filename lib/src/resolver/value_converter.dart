import 'package:flutter/widgets.dart';

import 'color_parser.dart';

/// Centralized, reusable type coercion for property values — the *only*
/// place numeric widening, list re-typing, and color-string parsing
/// happen. [PropertyDefinition.converter] hooks are almost always one of
/// these static methods; individual widget registrations should not
/// reimplement conversion logic.
class ValueConverter {
  const ValueConverter._();

  /// `num -> double`. Accepts a numeric string as a convenience for
  /// server-driven payloads that serialize everything as text.
  static double toDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final double? parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected a number, got ${_describe(value)}.');
  }

  static double? toNullableDouble(Object? value) =>
      value == null ? null : toDouble(value);

  /// `num -> int`. Truncates a `double` with no fractional part; rejects
  /// fractional doubles rather than silently truncating them.
  static int toInt(Object? value) {
    if (value is int) return value;
    if (value is double && value == value.roundToDouble()) return value.toInt();
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected an integer, got ${_describe(value)}.');
  }

  static int? toNullableInt(Object? value) =>
      value == null ? null : toInt(value);

  static bool toBool(Object? value) {
    if (value is bool) return value;
    throw FormatException('Expected a boolean, got ${_describe(value)}.');
  }

  static String toStringValue(Object? value) {
    if (value is String) return value;
    throw FormatException('Expected a string, got ${_describe(value)}.');
  }

  /// Accepts a [Color] as-is (the common case — `Colors.red` already
  /// resolves to a real `Color` via the value registry) or a hex/`rgb()`/
  /// `rgba()` string (see [ColorParser]).
  static Color toColor(Object? value) {
    if (value is Color) return value;
    if (value is String) {
      final Color? parsed = ColorParser.tryParse(value);
      if (parsed != null) return parsed;
      throw FormatException(
          '"$value" is not a recognized color format (#hex, rgb(), rgba()).');
    }
    throw FormatException('Expected a Color, got ${_describe(value)}.');
  }

  static Color? toNullableColor(Object? value) =>
      value == null ? null : toColor(value);

  /// Re-types a loosely-typed `List<Object?>` (the natural output of
  /// generic value resolution) into a properly-typed `List<T>`, which
  /// Flutter's invariant generic list checks require.
  static List<T> toList<T>(Object? value) {
    if (value is! List) {
      throw FormatException('Expected a list, got ${_describe(value)}.');
    }
    return value.cast<T>().toList(growable: false);
  }

  static List<T>? toNullableList<T>(Object? value) =>
      value == null ? null : toList<T>(value);

  /// `List<Object?> -> List<Widget>`, needed because Dart's generic lists
  /// are invariant: a `List<Object?>` containing only `Widget`s cannot be
  /// cast to `List<Widget>` with a bare `as`.
  static List<Widget> toWidgetList(Object? value) => toList<Widget>(value);

  static Map<String, Object?> toStringMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map(
          (Object? k, Object? v) => MapEntry<String, Object?>(k as String, v));
    }
    throw FormatException('Expected a map, got ${_describe(value)}.');
  }

  static String _describe(Object? value) =>
      value == null ? 'null' : '${value.runtimeType} ($value)';
}
