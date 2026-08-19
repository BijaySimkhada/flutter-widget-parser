import 'package:flutter/painting.dart';

/// Parses the color formats documented in the README's "Colors" section:
///  * `#RGB`, `#RRGGBB`, `#AARRGGBB` (hex, `#` required)
///  * `rgb(r, g, b)` with `r`/`g`/`b` in 0-255
///  * `rgba(r, g, b, a)` with `a` in 0.0-1.0
///
/// Named colors (`Colors.red`) are *not* handled here — those resolve
/// through the value registry as `Color` objects directly. This parser
/// only covers the textual formats a server payload might send instead.
class ColorParser {
  const ColorParser._();

  static final RegExp _hex =
      RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
  static final RegExp _rgb =
      RegExp(r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$');
  static final RegExp _rgba = RegExp(
      r'^rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*([0-9]*\.?[0-9]+)\s*\)$');

  /// Returns the parsed [Color], or `null` if [input] matches none of the
  /// supported formats.
  static Color? tryParse(String input) {
    final String text = input.trim();

    final RegExpMatch? hexMatch = _hex.firstMatch(text);
    if (hexMatch != null) {
      return _parseHex(hexMatch.group(1)!);
    }

    final RegExpMatch? rgbMatch = _rgb.firstMatch(text);
    if (rgbMatch != null) {
      final int? r = _byte(rgbMatch.group(1)!);
      final int? g = _byte(rgbMatch.group(2)!);
      final int? b = _byte(rgbMatch.group(3)!);
      if (r == null || g == null || b == null) return null;
      return Color.fromARGB(255, r, g, b);
    }

    final RegExpMatch? rgbaMatch = _rgba.firstMatch(text);
    if (rgbaMatch != null) {
      final int? r = _byte(rgbaMatch.group(1)!);
      final int? g = _byte(rgbaMatch.group(2)!);
      final int? b = _byte(rgbaMatch.group(3)!);
      final double? a = double.tryParse(rgbaMatch.group(4)!);
      if (r == null || g == null || b == null || a == null || a < 0 || a > 1) {
        return null;
      }
      return Color.fromARGB((a * 255).round(), r, g, b);
    }

    return null;
  }

  static int? _byte(String s) {
    final int? v = int.tryParse(s);
    if (v == null || v < 0 || v > 255) return null;
    return v;
  }

  static Color? _parseHex(String hex) {
    String normalized = hex;
    if (normalized.length == 3) {
      normalized = normalized.split('').map((String c) => '$c$c').join();
    }
    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }
    if (normalized.length != 8) return null;
    final int? value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
