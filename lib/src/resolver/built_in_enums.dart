import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../registry/dynamic_widget_registry.dart';

/// Registers every built-in Dart/Flutter enum the DSL understands, keyed
/// as `EnumName.memberName` (e.g. `MainAxisAlignment.center`). Adding
/// support for another enum is a one-line addition here — never a change
/// to the parser or resolver.
void registerBuiltInEnums(DynamicWidgetRegistry registry) {
  registry
    ..registerEnum<MainAxisAlignment>(
        'MainAxisAlignment', MainAxisAlignment.values)
    ..registerEnum<CrossAxisAlignment>(
        'CrossAxisAlignment', CrossAxisAlignment.values)
    ..registerEnum<MainAxisSize>('MainAxisSize', MainAxisSize.values)
    ..registerEnum<VerticalDirection>(
        'VerticalDirection', VerticalDirection.values)
    ..registerEnum<TextAlign>('TextAlign', TextAlign.values)
    ..registerEnum<TextDirection>('TextDirection', TextDirection.values)
    ..registerEnum<TextOverflow>('TextOverflow', TextOverflow.values)
    ..registerEnum<FontStyle>('FontStyle', FontStyle.values)
    ..registerEnum<BoxFit>('BoxFit', BoxFit.values)
    ..registerEnum<Axis>('Axis', Axis.values)
    ..registerEnum<Clip>('Clip', Clip.values)
    ..registerEnum<StackFit>('StackFit', StackFit.values)
    ..registerEnum<WrapAlignment>('WrapAlignment', WrapAlignment.values)
    ..registerEnum<WrapCrossAlignment>(
        'WrapCrossAlignment', WrapCrossAlignment.values)
    ..registerEnum<ImageRepeat>('ImageRepeat', ImageRepeat.values)
    ..registerEnum<TileMode>('TileMode', TileMode.values)
    ..registerEnum<BoxShape>('BoxShape', BoxShape.values)
    ..registerEnum<BorderStyle>('BorderStyle', BorderStyle.values)
    ..registerEnum<FlexFit>('FlexFit', FlexFit.values);

  // FontWeight and TextDecoration are classes with static const instances,
  // not Dart `enum`s, so they're registered as individual values instead
  // of via `registerEnum`.
  const Map<String, FontWeight> fontWeights = <String, FontWeight>{
    'w100': FontWeight.w100,
    'w200': FontWeight.w200,
    'w300': FontWeight.w300,
    'w400': FontWeight.w400,
    'w500': FontWeight.w500,
    'w600': FontWeight.w600,
    'w700': FontWeight.w700,
    'w800': FontWeight.w800,
    'w900': FontWeight.w900,
    'normal': FontWeight.normal,
    'bold': FontWeight.bold,
  };
  fontWeights.forEach((String name, FontWeight value) {
    registry.registerValue('FontWeight.$name', () => value);
  });

  const Map<String, TextDecoration> decorations = <String, TextDecoration>{
    'none': TextDecoration.none,
    'underline': TextDecoration.underline,
    'overline': TextDecoration.overline,
    'lineThrough': TextDecoration.lineThrough,
  };
  decorations.forEach((String name, TextDecoration value) {
    registry.registerValue('TextDecoration.$name', () => value);
  });

  const Map<String, Alignment> alignments = <String, Alignment>{
    'topLeft': Alignment.topLeft,
    'topCenter': Alignment.topCenter,
    'topRight': Alignment.topRight,
    'centerLeft': Alignment.centerLeft,
    'center': Alignment.center,
    'centerRight': Alignment.centerRight,
    'bottomLeft': Alignment.bottomLeft,
    'bottomCenter': Alignment.bottomCenter,
    'bottomRight': Alignment.bottomRight,
  };
  alignments.forEach((String name, Alignment value) {
    registry.registerValue('Alignment.$name', () => value);
  });
}
