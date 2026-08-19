import 'package:flutter/widgets.dart';

import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import '../../resolver/value_converter.dart';
import 'common_properties.dart';

/// Registers single-child layout primitives (`Container`, `Padding`,
/// `Align`, `Center`, `Expanded`, ...) and multi-child layout widgets
/// (`Row`, `Column`, `Stack`, `Wrap`, `IndexedStack`).
void registerLayoutWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Container',
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'padding', type: EdgeInsets),
      const PropertyDefinition(name: 'margin', type: EdgeInsets),
      colorProp('color'),
      doubleProp('width'),
      doubleProp('height'),
      const PropertyDefinition(name: 'alignment', type: Alignment),
      const PropertyDefinition(name: 'decoration', type: BoxDecoration),
      childProp(),
    ],
    builder: (context, args) => Container(
      padding: args.get<EdgeInsets>('padding'),
      margin: args.get<EdgeInsets>('margin'),
      color: args.get<Color>('color'),
      width: args.get<double>('width'),
      height: args.get<double>('height'),
      alignment: args.get<Alignment>('alignment'),
      decoration: args.get<BoxDecoration>('decoration'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'SizedBox',
    properties: <PropertyDefinition>[
      doubleProp('width'),
      doubleProp('height'),
      childProp()
    ],
    builder: (context, args) => SizedBox(
      width: args.get<double>('width'),
      height: args.get<double>('height'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ConstrainedBox',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'constraints',
          type: BoxConstraints,
          defaultValue: const BoxConstraints()),
      childProp(required: true),
    ],
    builder: (context, args) => ConstrainedBox(
      constraints:
          args.getOr<BoxConstraints>('constraints', const BoxConstraints()),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'LimitedBox',
    properties: <PropertyDefinition>[
      doubleProp('maxWidth', defaultValue: double.infinity),
      doubleProp('maxHeight', defaultValue: double.infinity),
      childProp(),
    ],
    builder: (context, args) => LimitedBox(
      maxWidth: args.getOr<double>('maxWidth', double.infinity),
      maxHeight: args.getOr<double>('maxHeight', double.infinity),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'FractionallySizedBox',
    properties: <PropertyDefinition>[
      doubleProp('widthFactor'),
      doubleProp('heightFactor'),
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.center),
      childProp(),
    ],
    builder: (context, args) => FractionallySizedBox(
      widthFactor: args.get<double>('widthFactor'),
      heightFactor: args.get<double>('heightFactor'),
      alignment: args.getOr<Alignment>('alignment', Alignment.center),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'OverflowBox',
    properties: <PropertyDefinition>[
      doubleProp('minWidth'),
      doubleProp('maxWidth'),
      doubleProp('minHeight'),
      doubleProp('maxHeight'),
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.center),
      childProp(),
    ],
    builder: (context, args) => OverflowBox(
      minWidth: args.get<double>('minWidth'),
      maxWidth: args.get<double>('maxWidth'),
      minHeight: args.get<double>('minHeight'),
      maxHeight: args.get<double>('maxHeight'),
      alignment: args.getOr<Alignment>('alignment', Alignment.center),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Padding',
    properties: <PropertyDefinition>[
      PropertyDefinition(name: 'padding', type: EdgeInsets, isRequired: true),
      childProp(),
    ],
    builder: (context, args) => Padding(
      padding: args.get<EdgeInsets>('padding')!,
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Align',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.center),
      doubleProp('widthFactor'),
      doubleProp('heightFactor'),
      childProp(),
    ],
    builder: (context, args) => Align(
      alignment: args.getOr<Alignment>('alignment', Alignment.center),
      widthFactor: args.get<double>('widthFactor'),
      heightFactor: args.get<double>('heightFactor'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Center',
    properties: <PropertyDefinition>[
      doubleProp('widthFactor'),
      doubleProp('heightFactor'),
      childProp()
    ],
    builder: (context, args) => Center(
      widthFactor: args.get<double>('widthFactor'),
      heightFactor: args.get<double>('heightFactor'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Expanded',
    properties: <PropertyDefinition>[
      intProp('flex', defaultValue: 1),
      childProp(required: true)
    ],
    builder: (context, args) => Expanded(
      flex: args.getOr<int>('flex', 1),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Flexible',
    properties: <PropertyDefinition>[
      intProp('flex', defaultValue: 1),
      const PropertyDefinition.withDefault(
          name: 'fit', type: FlexFit, defaultValue: FlexFit.loose),
      childProp(required: true),
    ],
    builder: (context, args) => Flexible(
      flex: args.getOr<int>('flex', 1),
      fit: args.getOr<FlexFit>('fit', FlexFit.loose),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Spacer',
    properties: <PropertyDefinition>[intProp('flex', defaultValue: 1)],
    builder: (context, args) => Spacer(flex: args.getOr<int>('flex', 1)),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'AspectRatio',
    properties: <PropertyDefinition>[
      doubleProp('aspectRatio', required: true),
      childProp()
    ],
    builder: (context, args) => AspectRatio(
      aspectRatio: args.get<double>('aspectRatio')!,
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'FittedBox',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'fit', type: BoxFit, defaultValue: BoxFit.contain),
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.center),
      childProp(),
    ],
    builder: (context, args) => FittedBox(
      fit: args.getOr<BoxFit>('fit', BoxFit.contain),
      alignment: args.getOr<Alignment>('alignment', Alignment.center),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Transform.rotate',
    properties: <PropertyDefinition>[
      doubleProp('angle', required: true),
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.center),
      childProp(),
    ],
    builder: (context, args) => Transform.rotate(
      angle: args.get<double>('angle')!,
      alignment: args.getOr<Alignment>('alignment', Alignment.center),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Transform.scale',
    properties: <PropertyDefinition>[
      doubleProp('scale', required: true),
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.center),
      childProp(),
    ],
    builder: (context, args) => Transform.scale(
      scale: args.get<double>('scale')!,
      alignment: args.getOr<Alignment>('alignment', Alignment.center),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Transform.translate',
    properties: <PropertyDefinition>[
      PropertyDefinition(name: 'offset', type: Offset, isRequired: true),
      childProp(),
    ],
    builder: (context, args) => Transform.translate(
      offset: args.get<Offset>('offset')!,
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'DecoratedBox',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'decoration', type: BoxDecoration, isRequired: true),
      childProp(),
    ],
    builder: (context, args) => DecoratedBox(
      decoration: args.get<BoxDecoration>('decoration')!,
      child: args.get<Widget>('child') ?? const SizedBox.shrink(),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ColoredBox',
    properties: <PropertyDefinition>[
      colorProp('color', defaultValue: const Color(0x00000000)),
      childProp()
    ],
    builder: (context, args) => ColoredBox(
      color: args.getOr<Color>('color', const Color(0x00000000)),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Opacity',
    properties: <PropertyDefinition>[
      PropertyDefinition(
        name: 'opacity',
        type: double,
        isRequired: true,
        converter: ValueConverter.toDouble,
        validator: (Object? v) => (v as double) < 0 || v > 1
            ? 'opacity must be between 0.0 and 1.0'
            : null,
      ),
      childProp(),
    ],
    builder: (context, args) => Opacity(
      opacity: args.get<double>('opacity')!,
      child: args.get<Widget>('child') ?? const SizedBox.shrink(),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Visibility',
    properties: <PropertyDefinition>[
      boolProp('visible', defaultValue: true),
      childProp(required: true)
    ],
    builder: (context, args) => Visibility(
      visible: args.getOr<bool>('visible', true),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Offstage',
    properties: <PropertyDefinition>[
      boolProp('offstage', defaultValue: true),
      childProp()
    ],
    builder: (context, args) => Offstage(
      offstage: args.getOr<bool>('offstage', true),
      child: args.get<Widget>('child') ?? const SizedBox.shrink(),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ClipRect',
    properties: <PropertyDefinition>[childProp()],
    builder: (context, args) => ClipRect(child: args.get<Widget>('child')),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ClipRRect',
    properties: <PropertyDefinition>[
      PropertyDefinition.withDefault(
          name: 'borderRadius',
          type: BorderRadius,
          defaultValue: BorderRadius.zero),
      childProp(),
    ],
    builder: (context, args) => ClipRRect(
      borderRadius: args.getOr<BorderRadius>('borderRadius', BorderRadius.zero),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ClipOval',
    properties: <PropertyDefinition>[childProp()],
    builder: (context, args) => ClipOval(child: args.get<Widget>('child')),
  ));

  // -- Multi-child layout --------------------------------------------

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Row',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'mainAxisAlignment',
          type: MainAxisAlignment,
          defaultValue: MainAxisAlignment.start),
      const PropertyDefinition.withDefault(
          name: 'crossAxisAlignment',
          type: CrossAxisAlignment,
          defaultValue: CrossAxisAlignment.center),
      const PropertyDefinition.withDefault(
          name: 'mainAxisSize',
          type: MainAxisSize,
          defaultValue: MainAxisSize.max),
      childrenProp(),
    ],
    builder: (context, args) => Row(
      mainAxisAlignment: args.getOr<MainAxisAlignment>(
          'mainAxisAlignment', MainAxisAlignment.start),
      crossAxisAlignment: args.getOr<CrossAxisAlignment>(
          'crossAxisAlignment', CrossAxisAlignment.center),
      mainAxisSize: args.getOr<MainAxisSize>('mainAxisSize', MainAxisSize.max),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Column',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'mainAxisAlignment',
          type: MainAxisAlignment,
          defaultValue: MainAxisAlignment.start),
      const PropertyDefinition.withDefault(
          name: 'crossAxisAlignment',
          type: CrossAxisAlignment,
          defaultValue: CrossAxisAlignment.center),
      const PropertyDefinition.withDefault(
          name: 'mainAxisSize',
          type: MainAxisSize,
          defaultValue: MainAxisSize.max),
      childrenProp(),
    ],
    builder: (context, args) => Column(
      mainAxisAlignment: args.getOr<MainAxisAlignment>(
          'mainAxisAlignment', MainAxisAlignment.start),
      crossAxisAlignment: args.getOr<CrossAxisAlignment>(
          'crossAxisAlignment', CrossAxisAlignment.center),
      mainAxisSize: args.getOr<MainAxisSize>('mainAxisSize', MainAxisSize.max),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Stack',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.topLeft),
      const PropertyDefinition.withDefault(
          name: 'fit', type: StackFit, defaultValue: StackFit.loose),
      childrenProp(),
    ],
    builder: (context, args) => Stack(
      alignment: args.getOr<Alignment>('alignment', Alignment.topLeft),
      fit: args.getOr<StackFit>('fit', StackFit.loose),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'IndexedStack',
    properties: <PropertyDefinition>[
      intProp('index', defaultValue: 0),
      const PropertyDefinition.withDefault(
          name: 'alignment', type: Alignment, defaultValue: Alignment.topLeft),
      childrenProp(),
    ],
    builder: (context, args) => IndexedStack(
      index: args.getOr<int>('index', 0),
      alignment: args.getOr<Alignment>('alignment', Alignment.topLeft),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Wrap',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'direction', type: Axis, defaultValue: Axis.horizontal),
      const PropertyDefinition.withDefault(
          name: 'alignment',
          type: WrapAlignment,
          defaultValue: WrapAlignment.start),
      const PropertyDefinition.withDefault(
          name: 'crossAxisAlignment',
          type: WrapCrossAlignment,
          defaultValue: WrapCrossAlignment.start),
      doubleProp('spacing', defaultValue: 0),
      doubleProp('runSpacing', defaultValue: 0),
      childrenProp(),
    ],
    builder: (context, args) => Wrap(
      direction: args.getOr<Axis>('direction', Axis.horizontal),
      alignment: args.getOr<WrapAlignment>('alignment', WrapAlignment.start),
      crossAxisAlignment: args.getOr<WrapCrossAlignment>(
          'crossAxisAlignment', WrapCrossAlignment.start),
      spacing: args.getOr<double>('spacing', 0),
      runSpacing: args.getOr<double>('runSpacing', 0),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));
}
