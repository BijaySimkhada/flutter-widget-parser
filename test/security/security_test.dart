import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rejects unregistered constructs', () {
    test('unknown/arbitrary "class" name is rejected, not instantiated', () {
      expect(
        () => DynamicWidgetParser.parseToAst('EvilClass(payload: "rm -rf /")'),
        returnsNormally, // parses fine as an AST — it's just structure
      );
      // ...but resolving it against the registry must fail: nothing named
      // "EvilClass" was ever registered, so it cannot be built.
      final result =
          DynamicWidgetParser.validate('EvilClass(payload: "rm -rf /")');
      expect(result.isValid, isFalse);
      expect(result.errors.single.message, contains('EvilClass'));
    });

    test('unknown constructor is rejected', () {
      final result = DynamicWidgetParser.validate(
          'Container(padding: SomeUnknownThing.magic(1))');
      expect(result.isValid, isFalse);
    });

    test('unregistered action is rejected at build time', () {
      final BuildContext dummy = _FakeBuildContext();
      expect(
        () => DynamicWidgetParser.buildFromAst(
          DynamicWidgetParser.parseToAst(
              'ElevatedButton(onPressed: action("notRegistered"), child: Text("x"))'),
          context: dummy,
        ),
        throwsA(isA<DynamicParserException>().having(
          (DynamicParserException e) => e.message,
          'message',
          contains('notRegistered'),
        )),
      );
    });

    test('unregistered action is rejected by validate() too', () {
      final ActionRegistry actions = ActionRegistry();
      final result = DynamicWidgetParser.validate(
        'ElevatedButton(onPressed: action("notRegistered"), child: Text("x"))',
        actions: actions,
      );
      expect(result.isValid, isFalse);
      expect(
          result.errors
              .any((ValidationIssue i) => i.message.contains('notRegistered')),
          isTrue);
    });

    test('unknown color/enum value is rejected, not guessed at', () {
      final result = DynamicWidgetParser.validate(
          'Container(color: Colors.definitelyNotARealColor)');
      expect(result.isValid, isFalse);
    });

    test(
        'unregistered variable in an expression resolves to null rather than throwing or reaching app internals',
        () {
      final BuildContext dummy = _FakeBuildContext();
      // No exception: an unknown variable is simply absent data, not a
      // reflective lookup into arbitrary application state.
      expect(
        () => DynamicWidgetParser.buildFromAst(
          DynamicWidgetParser.parseToAst(
              r'Text($totallyUndefined.secret ?? "fallback")'),
          context: dummy,
        ),
        returnsNormally,
      );
    });
  });

  group('no code execution primitives exist in the grammar', () {
    test(
        'there is no way to reference a bare function call without a widget/constructor name',
        () {
      expect(() => DynamicParser('(1, 2, 3)').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('field/method access syntax beyond dotted enum paths is not supported',
        () {
      // `$x.foo()` — calling a method on a variable — is not part of the
      // expression grammar; only dotted *path* lookups are.
      expect(
        () => DynamicParser(r'Text(style: $x.foo())').parseToAst(),
        throwsA(isA<SyntaxException>()),
      );
    });

    test('import/package syntax is rejected as garbage input', () {
      expect(() => DynamicParser("import 'dart:io';").parseToAst(),
          throwsA(isA<DynamicParserException>()));
    });
  });

  group('resource limits defend against pathological input', () {
    test('very deep nesting is rejected instead of overflowing the stack', () {
      final StringBuffer source = StringBuffer();
      const int depth = 5000;
      for (int i = 0; i < depth; i++) {
        source.write('Container(child:');
      }
      source.write('Text("x")');
      source.write(')' * depth);
      expect(
        () => DynamicParser(source.toString(),
                limits: const DynamicParserLimits())
            .parseToAst(),
        throwsA(isA<SyntaxException>()),
      );
    });

    test(
        'a very long flat chain of binary operators is rejected under default limits',
        () {
      // Precedence-climbing loops are O(1) in call-stack depth regardless
      // of chain length, so length has to be bounded separately from
      // nesting depth — this asserts that it is (via maxWidgetCount).
      final String chain = List<String>.filled(20000, r'$a').join(' + ');
      final String source = 'Text(style: $chain)';
      expect(
        () => DynamicParser(source).parseToAst(),
        throwsA(isA<SyntaxException>()),
      );
    });

    test(
        'deeply chained unary operators are rejected under default limits instead of overflowing the parser stack',
        () {
      final String bangs = '!' * 20000;
      final String source = 'Text(style: $bangs\$a)';
      expect(
        () => DynamicParser(source).parseToAst(),
        throwsA(isA<SyntaxException>()),
      );
    });

    test('an oversized source string is rejected before lexing', () {
      final String source = 'Text("${'a' * 300000}")';
      expect(
        () => DynamicParser(source, limits: const DynamicParserLimits())
            .parseToAst(),
        throwsA(isA<SyntaxException>()),
      );
    });

    test('an excessively long single string literal is rejected', () {
      final String source = 'Text("${'a' * 50000}")';
      expect(
        () => DynamicParser(source,
                limits: const DynamicParserLimits(maxStringLength: 1000))
            .parseToAst(),
        throwsA(isA<LexerException>()),
      );
    });
  });

  group('fallback error behavior never crashes the host app', () {
    testWidgets(
        'malformed remote payload renders a fallback instead of throwing',
        (WidgetTester tester) async {
      const String malicious = 'TotallyUnknownWidget(anything: "goes")';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return DynamicWidgetParser.parse(
                source: malicious,
                context: context,
                config: const DynamicParserConfig(
                    errorBehavior: DynamicErrorBehavior.fallback),
              );
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
