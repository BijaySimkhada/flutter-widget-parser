import 'package:flutter/material.dart';

import '../../actions/callback_resolver.dart';
import '../../actions/dynamic_action.dart';
import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import '../../resolver/value_converter.dart';
import 'common_properties.dart';

ButtonStyle? _simpleButtonStyle(Color? background, Color? foreground) {
  if (background == null && foreground == null) return null;
  return ButtonStyle(
    backgroundColor:
        background == null ? null : WidgetStatePropertyAll<Color>(background),
    foregroundColor:
        foreground == null ? null : WidgetStatePropertyAll<Color>(foreground),
  );
}

List<PropertyDefinition> _textButtonProperties() => <PropertyDefinition>[
      actionProp('onPressed'),
      colorProp('backgroundColor'),
      colorProp('foregroundColor'),
      childProp(required: true),
    ];

/// Registers the modern Material buttons (`ElevatedButton`, `FilledButton`,
/// `OutlinedButton`, `TextButton`, `IconButton`, `FloatingActionButton`)
/// plus a simplified `DropdownButton<String>`.
///
/// `ButtonStyle` support is intentionally limited to `backgroundColor`/
/// `foregroundColor` — the full `ButtonStyle` API (shapes, elevation,
/// per-`WidgetState` overrides, ...) is large enough that an application
/// needing it should register a custom widget wrapping its own theme.
void registerButtonWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ElevatedButton',
    properties: _textButtonProperties(),
    builder: (context, args) => ElevatedButton(
      onPressed: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onPressed'), context),
      style: _simpleButtonStyle(args.get<Color>('backgroundColor'),
          args.get<Color>('foregroundColor')),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'FilledButton',
    properties: _textButtonProperties(),
    builder: (context, args) => FilledButton(
      onPressed: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onPressed'), context),
      style: _simpleButtonStyle(args.get<Color>('backgroundColor'),
          args.get<Color>('foregroundColor')),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'OutlinedButton',
    properties: _textButtonProperties(),
    builder: (context, args) => OutlinedButton(
      onPressed: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onPressed'), context),
      style: _simpleButtonStyle(args.get<Color>('backgroundColor'),
          args.get<Color>('foregroundColor')),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'TextButton',
    properties: _textButtonProperties(),
    builder: (context, args) => TextButton(
      onPressed: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onPressed'), context),
      style: _simpleButtonStyle(args.get<Color>('backgroundColor'),
          args.get<Color>('foregroundColor')),
      child: args.get<Widget>('child')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'IconButton',
    properties: <PropertyDefinition>[
      actionProp('onPressed'),
      colorProp('color'),
      doubleProp('iconSize'),
      const PropertyDefinition(name: 'icon', type: Widget, isRequired: true),
    ],
    builder: (context, args) => IconButton(
      onPressed: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onPressed'), context),
      color: args.get<Color>('color'),
      iconSize: args.get<double>('iconSize') ?? 24.0,
      icon: args.get<Widget>('icon')!,
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'FloatingActionButton',
    properties: <PropertyDefinition>[
      actionProp('onPressed'),
      colorProp('backgroundColor'),
      colorProp('foregroundColor'),
      nullableChildProp(),
    ],
    builder: (context, args) => FloatingActionButton(
      onPressed: CallbackResolver.voidCallback(
          args.get<DynamicAction>('onPressed'), context),
      backgroundColor: args.get<Color>('backgroundColor'),
      foregroundColor: args.get<Color>('foregroundColor'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'DropdownButton',
    properties: <PropertyDefinition>[
      PropertyDefinition(
          name: 'items',
          type: List,
          isRequired: true,
          converter: ValueConverter.toList<String>),
      const PropertyDefinition(name: 'value', type: String),
      actionProp('onChanged'),
      const PropertyDefinition(name: 'hint', type: Widget),
    ],
    builder: (context, args) {
      final List<String> items = args.get<List<String>>('items')!;
      return DropdownButton<String>(
        value: args.get<String>('value'),
        hint: args.get<Widget>('hint'),
        items: <DropdownMenuItem<String>>[
          for (final String item in items)
            DropdownMenuItem<String>(value: item, child: Text(item)),
        ],
        onChanged: CallbackResolver.valueChanged<String?>(
            args.get<DynamicAction>('onChanged'), context),
      );
    },
  ));
}
