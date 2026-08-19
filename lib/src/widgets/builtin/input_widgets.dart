import 'package:flutter/material.dart';

import '../../actions/callback_resolver.dart';
import '../../actions/dynamic_action.dart';
import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import 'common_properties.dart';

/// Registers basic form/input widgets: `TextField`, `TextFormField`,
/// `Checkbox`, `Switch`, `Slider`, and a simplified `Radio<String>`.
///
/// **Stateful widgets and controllers**: none of these are wired to a
/// `TextEditingController` — the DSL has no safe way to hand back a
/// controller reference to remote source text, and controllers need a
/// `State` object to own their lifecycle, which a stateless AST->Widget
/// pass doesn't have. Instead, `value`/`onChanged` are plain properties:
/// the host application owns state (typically via `DynamicDataContext` for
/// the current value, and an `action(...)` callback to receive changes),
/// exactly like a controlled component in other declarative UI systems.
/// Selection/cursor position and text composition state are not
/// preserved across rebuilds — see the README's "Limitations" section.
void registerInputWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'TextField',
    properties: <PropertyDefinition>[
      stringProp('hintText'),
      stringProp('labelText'),
      boolProp('obscureText', defaultValue: false),
      boolProp('enabled', defaultValue: true),
      actionProp('onChanged'),
      actionProp('onSubmitted'),
    ],
    builder: (context, args) => TextField(
      decoration: InputDecoration(
          hintText: args.get<String>('hintText'),
          labelText: args.get<String>('labelText')),
      obscureText: args.getOr<bool>('obscureText', false),
      enabled: args.getOr<bool>('enabled', true),
      onChanged: CallbackResolver.valueChanged<String>(
          args.get<DynamicAction>('onChanged'), context),
      onSubmitted: CallbackResolver.valueChanged<String>(
          args.get<DynamicAction>('onSubmitted'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'TextFormField',
    properties: <PropertyDefinition>[
      stringProp('hintText'),
      stringProp('labelText'),
      stringProp('initialValue'),
      boolProp('obscureText', defaultValue: false),
      actionProp('onChanged'),
      actionProp('onSubmitted'),
    ],
    builder: (context, args) => TextFormField(
      initialValue: args.get<String>('initialValue'),
      decoration: InputDecoration(
          hintText: args.get<String>('hintText'),
          labelText: args.get<String>('labelText')),
      obscureText: args.getOr<bool>('obscureText', false),
      onChanged: CallbackResolver.valueChanged<String>(
          args.get<DynamicAction>('onChanged'), context),
      onFieldSubmitted: CallbackResolver.valueChanged<String>(
          args.get<DynamicAction>('onSubmitted'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Checkbox',
    properties: <PropertyDefinition>[
      PropertyDefinition(name: 'value', type: bool, isRequired: true),
      actionProp('onChanged'),
    ],
    builder: (context, args) => Checkbox(
      value: args.get<bool>('value')!,
      onChanged: CallbackResolver.valueChanged<bool?>(
          args.get<DynamicAction>('onChanged'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Switch',
    properties: <PropertyDefinition>[
      PropertyDefinition(name: 'value', type: bool, isRequired: true),
      actionProp('onChanged'),
    ],
    builder: (context, args) => Switch(
      value: args.get<bool>('value')!,
      onChanged: CallbackResolver.valueChanged<bool>(
          args.get<DynamicAction>('onChanged'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Slider',
    properties: <PropertyDefinition>[
      doubleProp('value', required: true),
      doubleProp('min', defaultValue: 0.0),
      doubleProp('max', defaultValue: 1.0),
      actionProp('onChanged'),
    ],
    builder: (context, args) => Slider(
      value: args.get<double>('value')!,
      min: args.getOr<double>('min', 0.0),
      max: args.getOr<double>('max', 1.0),
      onChanged: CallbackResolver.valueChanged<double>(
          args.get<DynamicAction>('onChanged'), context),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'Radio',
    properties: <PropertyDefinition>[
      stringProp('value', required: true),
      stringProp('groupValue'),
      actionProp('onChanged'),
    ],
    // `groupValue`/`onChanged` are deprecated in favor of a `RadioGroup`
    // ancestor, which has no equivalent in this DSL's per-call construction
    // model (there's no way to declare an ancestor that injects group
    // state into descendants from source text). The direct API still
    // works and is what this simplified, single-widget registration uses.
    // ignore: deprecated_member_use
    builder: (context, args) => Radio<String>(
      value: args.get<String>('value')!,
      // ignore: deprecated_member_use
      groupValue: args.get<String>('groupValue'),
      // ignore: deprecated_member_use
      onChanged: CallbackResolver.valueChanged<String?>(
          args.get<DynamicAction>('onChanged'), context),
    ),
  ));
}
