import 'package:flutter/material.dart';

import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import 'common_properties.dart';

/// Registers `Image.network`, `Image.asset`, `CircleAvatar`, and `Icon`.
///
/// Security note: `Image.network`'s `src` is whatever URL the payload
/// contains, and Flutter will fetch it — exactly like an `<img src>` in
/// server-rendered HTML. That's an explicit, opt-in capability of
/// registering this widget, not something the parser does on its own; if
/// your threat model requires restricting which hosts can be fetched,
/// register a narrower replacement (e.g. via a `PropertyDefinition`
/// `validator` on `src` that checks an allowlist) instead of the built-in.
void registerImageAndIconWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Image.network',
    positionalParameters: <PropertyDefinition>[
      stringProp('src', required: true)
    ],
    properties: <PropertyDefinition>[
      doubleProp('width'),
      doubleProp('height'),
      const PropertyDefinition.withDefault(
          name: 'fit', type: BoxFit, defaultValue: BoxFit.contain),
      colorProp('color'),
      PropertyDefinition(
        name: 'opacity',
        type: double,
        converter: (Object? v) =>
            v == null ? null : AlwaysStoppedAnimation<double>(v as double),
      ),
    ],
    builder: (context, args) => Image.network(
      args.positionalAt<String>(0)!,
      width: args.get<double>('width'),
      height: args.get<double>('height'),
      fit: args.getOr<BoxFit>('fit', BoxFit.contain),
      color: args.get<Color>('color'),
      opacity: args.get<Animation<double>>('opacity'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Image.asset',
    positionalParameters: <PropertyDefinition>[
      stringProp('name', required: true)
    ],
    properties: <PropertyDefinition>[
      doubleProp('width'),
      doubleProp('height'),
      const PropertyDefinition.withDefault(
          name: 'fit', type: BoxFit, defaultValue: BoxFit.contain),
      colorProp('color'),
    ],
    builder: (context, args) => Image.asset(
      args.positionalAt<String>(0)!,
      width: args.get<double>('width'),
      height: args.get<double>('height'),
      fit: args.getOr<BoxFit>('fit', BoxFit.contain),
      color: args.get<Color>('color'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'CircleAvatar',
    properties: <PropertyDefinition>[
      colorProp('backgroundColor'),
      colorProp('foregroundColor'),
      doubleProp('radius', defaultValue: 20.0),
      nullableChildProp(),
    ],
    builder: (context, args) => CircleAvatar(
      backgroundColor: args.get<Color>('backgroundColor'),
      foregroundColor: args.get<Color>('foregroundColor'),
      radius: args.getOr<double>('radius', 20.0),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Icon',
    positionalParameters: <PropertyDefinition>[
      const PropertyDefinition(name: 'icon', type: IconData, isRequired: true),
    ],
    properties: <PropertyDefinition>[doubleProp('size'), colorProp('color')],
    builder: (context, args) => Icon(
      args.positionalAt<IconData>(0)!,
      size: args.get<double>('size'),
      color: args.get<Color>('color'),
    ),
  ));
}
