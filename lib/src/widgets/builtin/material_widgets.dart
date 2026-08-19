import 'package:flutter/material.dart';

import '../../actions/callback_resolver.dart';
import '../../actions/dynamic_action.dart';
import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import 'common_properties.dart';

/// Registers commonly-used Material widgets: `Card`, `ListTile`, `Divider`,
/// `VerticalDivider`, `AppBar`, `Scaffold`, progress indicators, `Chip`,
/// `Tooltip`, and `Badge`.
void registerMaterialWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Card',
    properties: <PropertyDefinition>[
      colorProp('color'),
      doubleProp('elevation'),
      const PropertyDefinition(name: 'margin', type: EdgeInsets),
      nullableChildProp(),
    ],
    builder: (context, args) => Card(
      color: args.get<Color>('color'),
      elevation: args.get<double>('elevation'),
      margin: args.get<EdgeInsets>('margin'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ListTile',
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'leading', type: Widget),
      const PropertyDefinition(name: 'title', type: Widget),
      const PropertyDefinition(name: 'subtitle', type: Widget),
      const PropertyDefinition(name: 'trailing', type: Widget),
      boolProp('selected', defaultValue: false),
      actionProp('onTap'),
    ],
    builder: (context, args) => ListTile(
      leading: args.get<Widget>('leading'),
      title: args.get<Widget>('title'),
      subtitle: args.get<Widget>('subtitle'),
      trailing: args.get<Widget>('trailing'),
      selected: args.getOr<bool>('selected', false),
      onTap: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onTap'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Divider',
    properties: <PropertyDefinition>[
      doubleProp('height'),
      doubleProp('thickness'),
      doubleProp('indent'),
      doubleProp('endIndent'),
      colorProp('color'),
    ],
    builder: (context, args) => Divider(
      height: args.get<double>('height'),
      thickness: args.get<double>('thickness'),
      indent: args.get<double>('indent'),
      endIndent: args.get<double>('endIndent'),
      color: args.get<Color>('color'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'VerticalDivider',
    properties: <PropertyDefinition>[
      doubleProp('width'),
      doubleProp('thickness'),
      doubleProp('indent'),
      doubleProp('endIndent'),
      colorProp('color'),
    ],
    builder: (context, args) => VerticalDivider(
      width: args.get<double>('width'),
      thickness: args.get<double>('thickness'),
      indent: args.get<double>('indent'),
      endIndent: args.get<double>('endIndent'),
      color: args.get<Color>('color'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'AppBar',
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'title', type: Widget),
      colorProp('backgroundColor'),
      doubleProp('elevation'),
      boolProp('centerTitle'),
      PropertyDefinition(
          name: 'actions',
          type: List,
          converter: (Object? v) =>
              v == null ? null : (v as List).cast<Widget>()),
    ],
    builder: (context, args) => AppBar(
      title: args.get<Widget>('title'),
      backgroundColor: args.get<Color>('backgroundColor'),
      elevation: args.get<double>('elevation'),
      centerTitle: args.get<bool>('centerTitle'),
      actions: args.get<List<Widget>>('actions'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Scaffold',
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'appBar', type: PreferredSizeWidget),
      const PropertyDefinition(name: 'body', type: Widget),
      colorProp('backgroundColor'),
      const PropertyDefinition(name: 'floatingActionButton', type: Widget),
      const PropertyDefinition(name: 'bottomNavigationBar', type: Widget),
      const PropertyDefinition(name: 'drawer', type: Widget),
    ],
    builder: (context, args) => Scaffold(
      appBar: args.get<PreferredSizeWidget>('appBar'),
      body: args.get<Widget>('body'),
      backgroundColor: args.get<Color>('backgroundColor'),
      floatingActionButton: args.get<Widget>('floatingActionButton'),
      bottomNavigationBar: args.get<Widget>('bottomNavigationBar'),
      drawer: args.get<Widget>('drawer'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'CircularProgressIndicator',
    properties: <PropertyDefinition>[
      doubleProp('value'),
      colorProp('color'),
      doubleProp('strokeWidth', defaultValue: 4.0)
    ],
    builder: (context, args) => CircularProgressIndicator(
      value: args.get<double>('value'),
      color: args.get<Color>('color'),
      strokeWidth: args.getOr<double>('strokeWidth', 4.0),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'LinearProgressIndicator',
    properties: <PropertyDefinition>[
      doubleProp('value'),
      colorProp('color'),
      colorProp('backgroundColor'),
      doubleProp('minHeight'),
    ],
    builder: (context, args) => LinearProgressIndicator(
      value: args.get<double>('value'),
      color: args.get<Color>('color'),
      backgroundColor: args.get<Color>('backgroundColor'),
      minHeight: args.get<double>('minHeight'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Chip',
    properties: <PropertyDefinition>[
      PropertyDefinition(name: 'label', type: Widget, isRequired: true),
      const PropertyDefinition(name: 'avatar', type: Widget),
      colorProp('backgroundColor'),
      actionProp('onDeleted'),
    ],
    builder: (context, args) => Chip(
      label: args.get<Widget>('label')!,
      avatar: args.get<Widget>('avatar'),
      backgroundColor: args.get<Color>('backgroundColor'),
      onDeleted: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onDeleted'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Tooltip',
    properties: <PropertyDefinition>[
      stringProp('message', required: true),
      childProp(required: true)
    ],
    builder: (context, args) => Tooltip(
      message: args.get<String>('message')!,
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Badge',
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'label', type: Widget),
      colorProp('backgroundColor'),
      nullableChildProp(),
    ],
    builder: (context, args) => Badge(
      label: args.get<Widget>('label'),
      backgroundColor: args.get<Color>('backgroundColor'),
      child: args.get<Widget>('child'),
    ),
  ));
}
