import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Object? resolve(String source, {BuildContext? buildContext}) {
    final WidgetNode wrapper =
        DynamicParser('Text(style: $source)').parseToAst() as WidgetNode;
    final ValueNode valueNode = wrapper.property('style')!.value;
    final DynamicBuildContext context = DynamicBuildContext(
      buildContext: buildContext ?? _FakeBuildContext(),
      registry: DynamicWidgetParser.defaultRegistry,
      data: DynamicDataContext.empty,
      actions: DynamicWidgetParser.defaultActions,
      config: const DynamicParserConfig(),
    );
    return const ValueResolver().resolve(valueNode, context);
  }

  group('colors', () {
    test('named color', () => expect(resolve('Colors.blue'), Colors.blue));
    test('accent color',
        () => expect(resolve('Colors.redAccent'), Colors.redAccent));
    test('transparent',
        () => expect(resolve('Colors.transparent'), Colors.transparent));
    test('numbered shade',
        () => expect(resolve('Colors.blue.shade200'), Colors.blue.shade200));
    test('Color(0x...) constructor',
        () => expect(resolve('Color(0xFF2196F3)'), const Color(0xFF2196F3)));
    test(
        'Color.fromARGB',
        () => expect(resolve('Color.fromARGB(255, 33, 150, 243)'),
            const Color(0xFF2196F3)));
    test('unknown color throws WidgetResolutionException', () {
      expect(() => resolve('Colors.notAColor'),
          throwsA(isA<WidgetResolutionException>()));
    });
    test('unknown color suggests the closest match', () {
      try {
        resolve('Colors.blu');
        fail('expected to throw');
      } on WidgetResolutionException catch (e) {
        expect(e.suggestion, 'Colors.blue');
      }
    });
  });

  group('enums', () {
    test(
        'MainAxisAlignment',
        () => expect(
            resolve('MainAxisAlignment.center'), MainAxisAlignment.center));
    test(
        'CrossAxisAlignment',
        () => expect(
            resolve('CrossAxisAlignment.stretch'), CrossAxisAlignment.stretch));
    test('FontWeight (not a real enum, value-registered)',
        () => expect(resolve('FontWeight.bold'), FontWeight.bold));
    test('TextAlign',
        () => expect(resolve('TextAlign.center'), TextAlign.center));
    test('BoxFit', () => expect(resolve('BoxFit.cover'), BoxFit.cover));
    test('Axis', () => expect(resolve('Axis.horizontal'), Axis.horizontal));
  });

  group('geometry constructors', () {
    test('EdgeInsets.all',
        () => expect(resolve('EdgeInsets.all(16)'), const EdgeInsets.all(16)));
    test('EdgeInsets.symmetric', () {
      expect(
        resolve('EdgeInsets.symmetric(horizontal: 16, vertical: 8)'),
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    });
    test('EdgeInsets.only', () {
      expect(resolve('EdgeInsets.only(left: 8, top: 4)'),
          const EdgeInsets.only(left: 8, top: 4));
    });
    test(
        'BorderRadius.circular',
        () => expect(
            resolve('BorderRadius.circular(12)'), BorderRadius.circular(12)));
    test('Size', () => expect(resolve('Size(100, 50)'), const Size(100, 50)));
    test('Offset', () => expect(resolve('Offset(0, 10)'), const Offset(0, 10)));
    test('int is widened to double for double-typed args', () {
      // `16` (an int literal) into EdgeInsets.all's double parameter.
      expect(resolve('EdgeInsets.all(16)'), const EdgeInsets.all(16.0));
    });
  });

  group('TextStyle', () {
    test('builds with all documented properties', () {
      final TextStyle style = resolve(
        'TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5, letterSpacing: 0.5)',
      ) as TextStyle;
      expect(style.color, Colors.white);
      expect(style.fontSize, 20.0);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.height, 1.5);
      expect(style.letterSpacing, 0.5);
    });
  });

  group('decorations', () {
    test('BoxDecoration with nested BorderRadius and BoxShadow list', () {
      final BoxDecoration decoration = resolve('''
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
)
''') as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.blurRadius, 10.0);
    });

    test('LinearGradient', () {
      final LinearGradient gradient =
          resolve('LinearGradient(colors: [Colors.red, Colors.blue])')
              as LinearGradient;
      expect(gradient.colors, <Color>[Colors.red, Colors.blue]);
    });
  });

  group('property validation errors', () {
    test('unknown property produces a suggestion', () {
      final WidgetNode node =
          DynamicParser('TextStyle(fontSiz: 12)').parseToAst() as WidgetNode;
      final DynamicBuildContext context = DynamicBuildContext(
        buildContext: _FakeBuildContext(),
        registry: DynamicWidgetParser.defaultRegistry,
        data: DynamicDataContext.empty,
        actions: DynamicWidgetParser.defaultActions,
        config: const DynamicParserConfig(),
      );
      try {
        const ValueResolver().resolve(node, context);
        fail('expected PropertyResolutionException');
      } on PropertyResolutionException catch (e) {
        expect(e.property, 'fontSiz');
        expect(e.suggestion, 'fontSize');
      }
    });

    test('missing required property throws with the property name', () {
      final WidgetNode node =
          DynamicParser('Padding()').parseToAst() as WidgetNode;
      final DynamicBuildContext context = DynamicBuildContext(
        buildContext: _FakeBuildContext(),
        registry: DynamicWidgetParser.defaultRegistry,
        data: DynamicDataContext.empty,
        actions: DynamicWidgetParser.defaultActions,
        config: const DynamicParserConfig(),
      );
      expect(
        () => const ValueResolver().resolveWidgetNode(node, context),
        throwsA(isA<PropertyResolutionException>().having(
            (PropertyResolutionException e) => e.property,
            'property',
            'padding')),
      );
    });
  });
}

/// A `BuildContext` that satisfies the type system without a real widget
/// tree behind it. None of the built-in constructors/widgets dereference
/// `DynamicBuildContext.buildContext` while merely *constructing* a widget
/// (as opposed to when Flutter later builds/lays it out), so this is safe
/// for resolver-level unit tests that never actually pump the widget.
class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
