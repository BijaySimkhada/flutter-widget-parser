import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../actions/dynamic_action.dart';
import '../errors/dynamic_parser_exception.dart';
import '../errors/suggestion.dart';
import '../registry/dynamic_widget_registry.dart';
import '../registry/property_definition.dart';
import '../registry/widget_definition.dart';
import 'value_converter.dart';

const Color _black = Color(0xFF000000);

/// Registers every built-in, non-widget value constructor: geometry
/// (`EdgeInsets`, `BorderRadius`, `Radius`, `Size`, `Offset`, `Alignment`),
/// `Duration`, `Color` (and its named constructors), decorations
/// (`BorderSide`, `Border`, `BoxShadow`, gradients, `BoxDecoration`),
/// `TextStyle`, `Key`, and the special `action(...)` constructor.
///
/// Every entry here is a normal [ConstructorDefinition] — adding another
/// constructor never requires touching the parser or resolver.
void registerBuiltInConstructors(DynamicWidgetRegistry registry) {
  _registerGeometry(registry);
  _registerColorAndDuration(registry);
  _registerDecorations(registry);
  _registerTextStyle(registry);
  _registerTextSpan(registry);
  _registerKeys(registry);
  _registerAction(registry);
}

void _registerGeometry(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'EdgeInsets.all',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'value',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => EdgeInsets.all(args.positionalAt<double>(0)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'EdgeInsets.symmetric',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'horizontal',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'vertical',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => EdgeInsets.symmetric(
      horizontal: args.getOr<double>('horizontal', 0.0),
      vertical: args.getOr<double>('vertical', 0.0),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'EdgeInsets.only',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'left',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'top',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'right',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'bottom',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => EdgeInsets.only(
      left: args.getOr<double>('left', 0.0),
      top: args.getOr<double>('top', 0.0),
      right: args.getOr<double>('right', 0.0),
      bottom: args.getOr<double>('bottom', 0.0),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'EdgeInsets.fromLTRB',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'left',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'top',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'right',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'bottom',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => EdgeInsets.fromLTRB(
      args.positionalAt<double>(0)!,
      args.positionalAt<double>(1)!,
      args.positionalAt<double>(2)!,
      args.positionalAt<double>(3)!,
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'BorderRadius.circular',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'radius',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) =>
        BorderRadius.circular(args.positionalAt<double>(0)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'BorderRadius.all',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(name: 'radius', type: Radius, isRequired: true),
    ],
    builder: (context, args) => BorderRadius.all(args.positionalAt<Radius>(0)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'BorderRadius.only',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'topLeft', type: Radius, defaultValue: Radius.zero),
      PropertyDefinition.withDefault(
          name: 'topRight', type: Radius, defaultValue: Radius.zero),
      PropertyDefinition.withDefault(
          name: 'bottomLeft', type: Radius, defaultValue: Radius.zero),
      PropertyDefinition.withDefault(
          name: 'bottomRight', type: Radius, defaultValue: Radius.zero),
    ],
    builder: (context, args) => BorderRadius.only(
      topLeft: args.getOr<Radius>('topLeft', Radius.zero),
      topRight: args.getOr<Radius>('topRight', Radius.zero),
      bottomLeft: args.getOr<Radius>('bottomLeft', Radius.zero),
      bottomRight: args.getOr<Radius>('bottomRight', Radius.zero),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Radius.circular',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'radius',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => Radius.circular(args.positionalAt<double>(0)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Size',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'width',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'height',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) =>
        Size(args.positionalAt<double>(0)!, args.positionalAt<double>(1)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Offset',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'dx',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'dy',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) =>
        Offset(args.positionalAt<double>(0)!, args.positionalAt<double>(1)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'BoxConstraints',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'minWidth',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'maxWidth',
          type: double,
          defaultValue: double.infinity,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'minHeight',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'maxHeight',
          type: double,
          defaultValue: double.infinity,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => BoxConstraints(
      minWidth: args.getOr<double>('minWidth', 0.0),
      maxWidth: args.getOr<double>('maxWidth', double.infinity),
      minHeight: args.getOr<double>('minHeight', 0.0),
      maxHeight: args.getOr<double>('maxHeight', double.infinity),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Alignment',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'x',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'y',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) =>
        Alignment(args.positionalAt<double>(0)!, args.positionalAt<double>(1)!),
  ));
}

void _registerColorAndDuration(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'Color',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'value',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
    ],
    builder: (context, args) => Color(args.positionalAt<int>(0)!),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Color.fromARGB',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'a',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
      PropertyDefinition(
          name: 'r',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
      PropertyDefinition(
          name: 'g',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
      PropertyDefinition(
          name: 'b',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
    ],
    builder: (context, args) => Color.fromARGB(
      args.positionalAt<int>(0)!,
      args.positionalAt<int>(1)!,
      args.positionalAt<int>(2)!,
      args.positionalAt<int>(3)!,
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Color.fromRGBO',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'r',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
      PropertyDefinition(
          name: 'g',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
      PropertyDefinition(
          name: 'b',
          type: int,
          isRequired: true,
          converter: ValueConverter.toInt),
      PropertyDefinition(
          name: 'opacity',
          type: double,
          isRequired: true,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => Color.fromRGBO(
      args.positionalAt<int>(0)!,
      args.positionalAt<int>(1)!,
      args.positionalAt<int>(2)!,
      args.positionalAt<double>(3)!,
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Duration',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'days',
          type: int,
          defaultValue: 0,
          converter: ValueConverter.toInt),
      PropertyDefinition.withDefault(
          name: 'hours',
          type: int,
          defaultValue: 0,
          converter: ValueConverter.toInt),
      PropertyDefinition.withDefault(
          name: 'minutes',
          type: int,
          defaultValue: 0,
          converter: ValueConverter.toInt),
      PropertyDefinition.withDefault(
          name: 'seconds',
          type: int,
          defaultValue: 0,
          converter: ValueConverter.toInt),
      PropertyDefinition.withDefault(
          name: 'milliseconds',
          type: int,
          defaultValue: 0,
          converter: ValueConverter.toInt),
    ],
    builder: (context, args) => Duration(
      days: args.getOr<int>('days', 0),
      hours: args.getOr<int>('hours', 0),
      minutes: args.getOr<int>('minutes', 0),
      seconds: args.getOr<int>('seconds', 0),
      milliseconds: args.getOr<int>('milliseconds', 0),
    ),
  ));
}

void _registerDecorations(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'BorderSide',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'color',
          type: Color,
          defaultValue: _black,
          converter: ValueConverter.toColor),
      PropertyDefinition.withDefault(
          name: 'width',
          type: double,
          defaultValue: 1.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'style', type: BorderStyle, defaultValue: BorderStyle.solid),
    ],
    builder: (context, args) => BorderSide(
      color: args.getOr<Color>('color', _black),
      width: args.getOr<double>('width', 1.0),
      style: args.getOr<BorderStyle>('style', BorderStyle.solid),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Border.all',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'color',
          type: Color,
          defaultValue: _black,
          converter: ValueConverter.toColor),
      PropertyDefinition.withDefault(
          name: 'width',
          type: double,
          defaultValue: 1.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'style', type: BorderStyle, defaultValue: BorderStyle.solid),
    ],
    builder: (context, args) => Border.all(
      color: args.getOr<Color>('color', _black),
      width: args.getOr<double>('width', 1.0),
      style: args.getOr<BorderStyle>('style', BorderStyle.solid),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'Border',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'top', type: BorderSide, defaultValue: BorderSide.none),
      PropertyDefinition.withDefault(
          name: 'right', type: BorderSide, defaultValue: BorderSide.none),
      PropertyDefinition.withDefault(
          name: 'bottom', type: BorderSide, defaultValue: BorderSide.none),
      PropertyDefinition.withDefault(
          name: 'left', type: BorderSide, defaultValue: BorderSide.none),
    ],
    builder: (context, args) => Border(
      top: args.getOr<BorderSide>('top', BorderSide.none),
      right: args.getOr<BorderSide>('right', BorderSide.none),
      bottom: args.getOr<BorderSide>('bottom', BorderSide.none),
      left: args.getOr<BorderSide>('left', BorderSide.none),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'BoxShadow',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'color',
          type: Color,
          defaultValue: const Color(0xFF000000),
          converter: ValueConverter.toColor),
      PropertyDefinition.withDefault(
          name: 'offset', type: Offset, defaultValue: Offset.zero),
      PropertyDefinition.withDefault(
          name: 'blurRadius',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'spreadRadius',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
    ],
    builder: (context, args) => BoxShadow(
      color: args.getOr<Color>('color', _black),
      offset: args.getOr<Offset>('offset', Offset.zero),
      blurRadius: args.getOr<double>('blurRadius', 0.0),
      spreadRadius: args.getOr<double>('spreadRadius', 0.0),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'LinearGradient',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'colors',
          type: List<Color>,
          isRequired: true,
          converter: ValueConverter.toList<Color>),
      PropertyDefinition.withDefault(
          name: 'begin', type: Alignment, defaultValue: Alignment.centerLeft),
      PropertyDefinition.withDefault(
          name: 'end', type: Alignment, defaultValue: Alignment.centerRight),
      PropertyDefinition(
          name: 'stops',
          type: List,
          converter: ValueConverter.toNullableList<double>),
    ],
    builder: (context, args) => LinearGradient(
      colors: args.get<List<Color>>('colors')!,
      begin: args.getOr<Alignment>('begin', Alignment.centerLeft),
      end: args.getOr<Alignment>('end', Alignment.centerRight),
      stops: args.get<List<double>>('stops'),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'RadialGradient',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'colors',
          type: List<Color>,
          isRequired: true,
          converter: ValueConverter.toList<Color>),
      PropertyDefinition.withDefault(
          name: 'center', type: Alignment, defaultValue: Alignment.center),
      PropertyDefinition.withDefault(
          name: 'radius',
          type: double,
          defaultValue: 0.5,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'stops',
          type: List,
          converter: ValueConverter.toNullableList<double>),
    ],
    builder: (context, args) => RadialGradient(
      colors: args.get<List<Color>>('colors')!,
      center: args.getOr<Alignment>('center', Alignment.center),
      radius: args.getOr<double>('radius', 0.5),
      stops: args.get<List<double>>('stops'),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'SweepGradient',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'colors',
          type: List<Color>,
          isRequired: true,
          converter: ValueConverter.toList<Color>),
      PropertyDefinition.withDefault(
          name: 'center', type: Alignment, defaultValue: Alignment.center),
      PropertyDefinition.withDefault(
          name: 'startAngle',
          type: double,
          defaultValue: 0.0,
          converter: ValueConverter.toDouble),
      PropertyDefinition.withDefault(
          name: 'endAngle',
          type: double,
          defaultValue: 6.283185307179586,
          converter: ValueConverter.toDouble),
      PropertyDefinition(
          name: 'stops',
          type: List,
          converter: ValueConverter.toNullableList<double>),
    ],
    builder: (context, args) => SweepGradient(
      colors: args.get<List<Color>>('colors')!,
      center: args.getOr<Alignment>('center', Alignment.center),
      startAngle: args.getOr<double>('startAngle', 0.0),
      endAngle: args.getOr<double>('endAngle', 6.283185307179586),
      stops: args.get<List<double>>('stops'),
    ),
  ));

  registry.registerConstructor(ConstructorDefinition(
    name: 'BoxDecoration',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'color',
          type: Color,
          converter: ValueConverter.toNullableColor),
      PropertyDefinition(name: 'borderRadius', type: BorderRadius),
      PropertyDefinition(name: 'border', type: BoxBorder),
      PropertyDefinition(
          name: 'boxShadow',
          type: List,
          converter: ValueConverter.toNullableList<BoxShadow>),
      PropertyDefinition(name: 'gradient', type: Gradient),
      PropertyDefinition.withDefault(
          name: 'shape', type: BoxShape, defaultValue: BoxShape.rectangle),
    ],
    builder: (context, args) => BoxDecoration(
      color: args.get<Color>('color'),
      borderRadius: args.get<BorderRadius>('borderRadius'),
      border: args.get<BoxBorder>('border'),
      boxShadow: args.get<List<BoxShadow>>('boxShadow'),
      gradient: args.get<Gradient>('gradient'),
      shape: args.getOr<BoxShape>('shape', BoxShape.rectangle),
    ),
  ));
}

void _registerTextStyle(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'TextStyle',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'color',
          type: Color,
          converter: ValueConverter.toNullableColor),
      PropertyDefinition(
          name: 'backgroundColor',
          type: Color,
          converter: ValueConverter.toNullableColor),
      PropertyDefinition(
          name: 'fontSize',
          type: double,
          converter: ValueConverter.toNullableDouble),
      PropertyDefinition(name: 'fontWeight', type: FontWeight),
      PropertyDefinition(name: 'fontStyle', type: FontStyle),
      PropertyDefinition(
          name: 'letterSpacing',
          type: double,
          converter: ValueConverter.toNullableDouble),
      PropertyDefinition(
          name: 'wordSpacing',
          type: double,
          converter: ValueConverter.toNullableDouble),
      PropertyDefinition(
          name: 'height',
          type: double,
          converter: ValueConverter.toNullableDouble),
      PropertyDefinition(name: 'decoration', type: TextDecoration),
      PropertyDefinition(
          name: 'fontFamily',
          type: String,
          converter: (Object? v) =>
              v == null ? null : ValueConverter.toStringValue(v)),
    ],
    builder: (context, args) => TextStyle(
      color: args.get<Color>('color'),
      backgroundColor: args.get<Color>('backgroundColor'),
      fontSize: args.get<double>('fontSize'),
      fontWeight: args.get<FontWeight>('fontWeight'),
      fontStyle: args.get<FontStyle>('fontStyle'),
      letterSpacing: args.get<double>('letterSpacing'),
      wordSpacing: args.get<double>('wordSpacing'),
      height: args.get<double>('height'),
      decoration: args.get<TextDecoration>('decoration'),
      fontFamily: args.get<String>('fontFamily'),
    ),
  ));
}

void _registerTextSpan(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'TextSpan',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'text',
          type: String,
          converter: (Object? v) =>
              v == null ? null : ValueConverter.toStringValue(v)),
      const PropertyDefinition(name: 'style', type: TextStyle),
      PropertyDefinition(
          name: 'children',
          type: List,
          converter: (Object? v) =>
              v == null ? null : ValueConverter.toList<InlineSpan>(v)),
    ],
    builder: (context, args) => TextSpan(
      text: args.get<String>('text'),
      style: args.get<TextStyle>('style'),
      children: args.get<List<InlineSpan>>('children'),
    ),
  ));
}

void _registerKeys(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'Key',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'value',
          type: String,
          isRequired: true,
          converter: ValueConverter.toStringValue),
    ],
    builder: (context, args) => ValueKey<String>(args.positionalAt<String>(0)!),
  ));
  registry.registerAlias('ValueKey', 'Key');
}

void _registerAction(DynamicWidgetRegistry registry) {
  registry.registerConstructor(ConstructorDefinition(
    name: 'action',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'name',
          type: String,
          isRequired: true,
          converter: ValueConverter.toStringValue),
      PropertyDefinition.withDefault(
          name: 'arguments',
          type: Map,
          defaultValue: <String, Object?>{},
          converter: ValueConverter.toStringMap),
    ],
    builder: (context, args) {
      final String name = args.positionalAt<String>(0)!;
      if (!context.actions.has(name)) {
        final String? suggestion =
            findClosestMatch(name, context.actions.names);
        throw WidgetResolutionException(
          'Unknown action "$name". Actions must be explicitly registered via '
          'ActionRegistry.register() before they can be referenced from source.',
          widget: 'action',
          suggestion: suggestion,
        );
      }
      final Map<String, Object?> arguments =
          args.positionalAt<Map<String, Object?>>(1) ??
              const <String, Object?>{};
      return DynamicAction(name, arguments);
    },
  ));
}
