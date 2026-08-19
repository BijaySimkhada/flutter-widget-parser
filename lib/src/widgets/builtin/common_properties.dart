import 'package:flutter/widgets.dart';

import '../../actions/dynamic_action.dart';
import '../../registry/property_definition.dart';
import '../../resolver/value_converter.dart';

/// Small factory helpers for [PropertyDefinition]s that recur across dozens
/// of built-in widget registrations (`child`, `children`, colors, doubles,
/// action-bound callbacks...). Keeps registration files declarative instead
/// of re-deriving the same converter/default boilerplate everywhere.

PropertyDefinition childProp({bool required = false}) =>
    PropertyDefinition(name: 'child', type: Widget, isRequired: required);

PropertyDefinition nullableChildProp() =>
    const PropertyDefinition(name: 'child', type: Widget);

PropertyDefinition childrenProp({bool required = false}) => PropertyDefinition(
      name: 'children',
      type: List,
      isRequired: required,
      hasDefault: !required,
      defaultValue: required ? null : const <Widget>[],
      converter: ValueConverter.toWidgetList,
    );

PropertyDefinition colorProp(String name,
        {Color? defaultValue}) =>
    defaultValue == null
        ? PropertyDefinition(
            name: name, type: Color, converter: ValueConverter.toNullableColor)
        : PropertyDefinition.withDefault(
            name: name,
            type: Color,
            defaultValue: defaultValue,
            converter: ValueConverter.toColor);

PropertyDefinition doubleProp(String name,
        {double? defaultValue, bool required = false}) =>
    required
        ? PropertyDefinition(
            name: name,
            type: double,
            isRequired: true,
            converter: ValueConverter.toDouble)
        : (defaultValue == null
            ? PropertyDefinition(
                name: name,
                type: double,
                converter: ValueConverter.toNullableDouble)
            : PropertyDefinition.withDefault(
                name: name,
                type: double,
                defaultValue: defaultValue,
                converter: ValueConverter.toDouble));

PropertyDefinition intProp(String name,
        {int? defaultValue}) =>
    defaultValue == null
        ? PropertyDefinition(
            name: name, type: int, converter: ValueConverter.toNullableInt)
        : PropertyDefinition.withDefault(
            name: name,
            type: int,
            defaultValue: defaultValue,
            converter: ValueConverter.toInt);

PropertyDefinition boolProp(String name,
        {bool? defaultValue}) =>
    defaultValue == null
        ? PropertyDefinition(
            name: name,
            type: bool,
            converter: (Object? v) =>
                v == null ? null : ValueConverter.toBool(v))
        : PropertyDefinition.withDefault(
            name: name,
            type: bool,
            defaultValue: defaultValue,
            converter: ValueConverter.toBool);

PropertyDefinition stringProp(String name,
        {String? defaultValue, bool required = false}) =>
    required
        ? PropertyDefinition(
            name: name,
            type: String,
            isRequired: true,
            converter: ValueConverter.toStringValue)
        : (defaultValue == null
            ? PropertyDefinition(
                name: name,
                type: String,
                converter: (Object? v) =>
                    v == null ? null : ValueConverter.toStringValue(v))
            : PropertyDefinition.withDefault(
                name: name,
                type: String,
                defaultValue: defaultValue,
                converter: ValueConverter.toStringValue));

/// A callback-typed property (`onPressed`, `onTap`, ...). Values must be
/// produced by the `action(...)` constructor; binding to a real callback
/// happens in the widget's builder via `CallbackResolver`, since that needs
/// the current [DynamicBuildContext], not just the raw value.
PropertyDefinition actionProp(String name) =>
    PropertyDefinition(name: name, type: DynamicAction);

PropertyDefinition enumProp(String name, Type type, {Object? defaultValue}) =>
    defaultValue == null
        ? PropertyDefinition(name: name, type: type)
        : PropertyDefinition.withDefault(
            name: name, type: type, defaultValue: defaultValue);

PropertyDefinition keyProp() =>
    const PropertyDefinition(name: 'key', type: Key);
