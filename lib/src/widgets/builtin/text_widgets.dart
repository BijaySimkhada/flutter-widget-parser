import 'package:flutter/material.dart';

import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import '../../resolver/value_converter.dart';
import 'common_properties.dart';

/// Registers `Text`, `RichText`, `SelectableText`, and `DefaultTextStyle`.
/// `RichText`'s `text:` property expects a `TextSpan(...)` value (see the
/// `TextSpan` constructor in `built_in_constructors.dart`), so nested spans
/// compose exactly like they would in hand-written Dart.
void registerTextWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Text',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'data',
          type: String,
          isRequired: true,
          converter: ValueConverter.toStringValue),
    ],
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'style', type: TextStyle),
      const PropertyDefinition(name: 'textAlign', type: TextAlign),
      const PropertyDefinition(name: 'overflow', type: TextOverflow),
      intProp('maxLines'),
      boolProp('softWrap'),
    ],
    builder: (context, args) => Text(
      args.positionalAt<String>(0)!,
      style: args.get<TextStyle>('style'),
      textAlign: args.get<TextAlign>('textAlign'),
      overflow: args.get<TextOverflow>('overflow'),
      maxLines: args.get<int>('maxLines'),
      softWrap: args.get<bool>('softWrap'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'SelectableText',
    positionalParameters: <PropertyDefinition>[
      PropertyDefinition(
          name: 'data',
          type: String,
          isRequired: true,
          converter: ValueConverter.toStringValue),
    ],
    properties: <PropertyDefinition>[
      const PropertyDefinition(name: 'style', type: TextStyle),
      const PropertyDefinition(name: 'textAlign', type: TextAlign),
      intProp('maxLines'),
    ],
    builder: (context, args) => SelectableText(
      args.positionalAt<String>(0)!,
      style: args.get<TextStyle>('style'),
      textAlign: args.get<TextAlign>('textAlign'),
      maxLines: args.get<int>('maxLines'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'RichText',
    properties: <PropertyDefinition>[
      const PropertyDefinition(
          name: 'text', type: InlineSpan, isRequired: true),
      const PropertyDefinition.withDefault(
          name: 'textAlign', type: TextAlign, defaultValue: TextAlign.start),
    ],
    builder: (context, args) => RichText(
      text: args.get<InlineSpan>('text')!,
      textAlign: args.getOr<TextAlign>('textAlign', TextAlign.start),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'DefaultTextStyle',
    properties: <PropertyDefinition>[
      PropertyDefinition(name: 'style', type: TextStyle, isRequired: true),
      childProp(required: true),
    ],
    builder: (context, args) => DefaultTextStyle(
      style: args.get<TextStyle>('style')!,
      child: args.get<Widget>('child')!,
    ),
  ));
}
