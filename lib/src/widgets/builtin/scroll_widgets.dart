import 'package:flutter/widgets.dart';

import '../../registry/dynamic_widget_registry.dart';
import '../../registry/property_definition.dart';
import '../../registry/widget_definition.dart';
import 'common_properties.dart';

/// Registers scrollable containers: `ListView`, `SingleChildScrollView`,
/// `GridView.count`, and `PageView`.
///
/// Not included: `ListView.builder`/`GridView.builder` (they take an
/// `itemBuilder` closure, which has no safe representation in the DSL —
/// see the README's "Limitations" section) and `CustomScrollView` (sliver
/// composition is out of scope for the initial widget set but can be
/// added by an application via `registry.registerWidget`).
void registerScrollWidgets(DynamicWidgetRegistry registry) {
  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'ListView',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'scrollDirection', type: Axis, defaultValue: Axis.vertical),
      boolProp('shrinkWrap', defaultValue: false),
      boolProp('reverse', defaultValue: false),
      const PropertyDefinition(name: 'padding', type: EdgeInsets),
      childrenProp(),
    ],
    builder: (context, args) => ListView(
      scrollDirection: args.getOr<Axis>('scrollDirection', Axis.vertical),
      shrinkWrap: args.getOr<bool>('shrinkWrap', false),
      reverse: args.getOr<bool>('reverse', false),
      padding: args.get<EdgeInsets>('padding'),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'SingleChildScrollView',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'scrollDirection', type: Axis, defaultValue: Axis.vertical),
      boolProp('reverse', defaultValue: false),
      const PropertyDefinition(name: 'padding', type: EdgeInsets),
      childProp(),
    ],
    builder: (context, args) => SingleChildScrollView(
      scrollDirection: args.getOr<Axis>('scrollDirection', Axis.vertical),
      reverse: args.getOr<bool>('reverse', false),
      padding: args.get<EdgeInsets>('padding'),
      child: args.get<Widget>('child'),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'GridView.count',
    properties: <PropertyDefinition>[
      intProp('crossAxisCount', defaultValue: 2),
      doubleProp('mainAxisSpacing', defaultValue: 0),
      doubleProp('crossAxisSpacing', defaultValue: 0),
      doubleProp('childAspectRatio', defaultValue: 1.0),
      boolProp('shrinkWrap', defaultValue: false),
      const PropertyDefinition(name: 'padding', type: EdgeInsets),
      childrenProp(),
    ],
    builder: (context, args) => GridView.count(
      crossAxisCount: args.getOr<int>('crossAxisCount', 2),
      mainAxisSpacing: args.getOr<double>('mainAxisSpacing', 0),
      crossAxisSpacing: args.getOr<double>('crossAxisSpacing', 0),
      childAspectRatio: args.getOr<double>('childAspectRatio', 1.0),
      shrinkWrap: args.getOr<bool>('shrinkWrap', false),
      padding: args.get<EdgeInsets>('padding'),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));

  registry.registerWidgetDefinition(WidgetDefinition(
    name: 'PageView',
    properties: <PropertyDefinition>[
      const PropertyDefinition.withDefault(
          name: 'scrollDirection', type: Axis, defaultValue: Axis.horizontal),
      childrenProp(),
    ],
    builder: (context, args) => PageView(
      scrollDirection: args.getOr<Axis>('scrollDirection', Axis.horizontal),
      children: args.getOr<List<Widget>>('children', const <Widget>[]),
    ),
  ));
}
