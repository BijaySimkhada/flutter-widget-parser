import 'package:flutter/material.dart';

import '../registry/dynamic_widget_registry.dart';

/// Registers `Colors.*` (including numbered shades, e.g.
/// `Colors.blue.shade200`) as resolvable values. Every entry maps directly
/// to the real `package:flutter/material.dart` constant — nothing here is
/// reimplemented or approximated.
void registerBuiltInColors(DynamicWidgetRegistry registry) {
  const Map<String, Color> flatColors = <String, Color>{
    'transparent': Colors.transparent,
    'black': Colors.black,
    'black87': Colors.black87,
    'black54': Colors.black54,
    'black45': Colors.black45,
    'black38': Colors.black38,
    'black26': Colors.black26,
    'black12': Colors.black12,
    'white': Colors.white,
    'white70': Colors.white70,
    'white60': Colors.white60,
    'white54': Colors.white54,
    'white38': Colors.white38,
    'white30': Colors.white30,
    'white24': Colors.white24,
    'white12': Colors.white12,
    'white10': Colors.white10,
    'red': Colors.red,
    'redAccent': Colors.redAccent,
    'pink': Colors.pink,
    'pinkAccent': Colors.pinkAccent,
    'purple': Colors.purple,
    'purpleAccent': Colors.purpleAccent,
    'deepPurple': Colors.deepPurple,
    'deepPurpleAccent': Colors.deepPurpleAccent,
    'indigo': Colors.indigo,
    'indigoAccent': Colors.indigoAccent,
    'blue': Colors.blue,
    'blueAccent': Colors.blueAccent,
    'lightBlue': Colors.lightBlue,
    'lightBlueAccent': Colors.lightBlueAccent,
    'cyan': Colors.cyan,
    'cyanAccent': Colors.cyanAccent,
    'teal': Colors.teal,
    'tealAccent': Colors.tealAccent,
    'green': Colors.green,
    'greenAccent': Colors.greenAccent,
    'lightGreen': Colors.lightGreen,
    'lightGreenAccent': Colors.lightGreenAccent,
    'lime': Colors.lime,
    'limeAccent': Colors.limeAccent,
    'yellow': Colors.yellow,
    'yellowAccent': Colors.yellowAccent,
    'amber': Colors.amber,
    'amberAccent': Colors.amberAccent,
    'orange': Colors.orange,
    'orangeAccent': Colors.orangeAccent,
    'deepOrange': Colors.deepOrange,
    'deepOrangeAccent': Colors.deepOrangeAccent,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'blueGrey': Colors.blueGrey,
    'blueGray': Colors.blueGrey,
  };

  flatColors.forEach((String name, Color value) {
    registry.registerValue('Colors.$name', () => value);
  });

  const Map<String, MaterialColor> swatches = <String, MaterialColor>{
    'red': Colors.red,
    'pink': Colors.pink,
    'purple': Colors.purple,
    'deepPurple': Colors.deepPurple,
    'indigo': Colors.indigo,
    'blue': Colors.blue,
    'lightBlue': Colors.lightBlue,
    'cyan': Colors.cyan,
    'teal': Colors.teal,
    'green': Colors.green,
    'lightGreen': Colors.lightGreen,
    'lime': Colors.lime,
    'yellow': Colors.yellow,
    'amber': Colors.amber,
    'orange': Colors.orange,
    'deepOrange': Colors.deepOrange,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'blueGrey': Colors.blueGrey,
  };
  const List<int> shadeKeys = <int>[
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900
  ];

  swatches.forEach((String name, MaterialColor swatch) {
    for (final int shade in shadeKeys) {
      final Color? shadeColor = swatch[shade];
      if (shadeColor != null) {
        registry.registerValue('Colors.$name.shade$shade', () => shadeColor);
      }
    }
  });

  const Map<String, MaterialAccentColor> accentSwatches =
      <String, MaterialAccentColor>{
    'red': Colors.redAccent,
    'pink': Colors.pinkAccent,
    'purple': Colors.purpleAccent,
    'deepPurple': Colors.deepPurpleAccent,
    'indigo': Colors.indigoAccent,
    'blue': Colors.blueAccent,
    'lightBlue': Colors.lightBlueAccent,
    'cyan': Colors.cyanAccent,
    'teal': Colors.tealAccent,
    'green': Colors.greenAccent,
    'lightGreen': Colors.lightGreenAccent,
    'lime': Colors.limeAccent,
    'yellow': Colors.yellowAccent,
    'amber': Colors.amberAccent,
    'orange': Colors.orangeAccent,
    'deepOrange': Colors.deepOrangeAccent,
  };
  const List<int> accentShadeKeys = <int>[100, 200, 400, 700];
  accentSwatches.forEach((String name, MaterialAccentColor swatch) {
    for (final int shade in accentShadeKeys) {
      final Color? shadeColor = swatch[shade];
      if (shadeColor != null) {
        registry.registerValue(
            'Colors.${name}Accent.shade$shade', () => shadeColor);
      }
    }
  });
}
