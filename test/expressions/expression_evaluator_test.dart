import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Object? evalIn(String expressionSource, Map<String, Object?> values) {
  final WidgetNode node = DynamicParser('Text(style: $expressionSource)')
      .parseToAst() as WidgetNode;
  final ExpressionNode expr = node.property('style')!.value as ExpressionNode;
  return ExpressionEvaluator(DynamicDataContext(values: values)).evaluate(expr);
}

void main() {
  group('variable lookup', () {
    test('top-level variable', () {
      expect(evalIn(r'$name', <String, Object?>{'name': 'Ada'}), 'Ada');
    });

    test('nested map property lookup', () {
      expect(
        evalIn(r'$user.profile.name', <String, Object?>{
          'user': <String, Object?>{
            'profile': <String, Object?>{'name': 'Grace'},
          },
        }),
        'Grace',
      );
    });

    test('missing variable resolves to null, not an error', () {
      expect(evalIn(r'$missing.deeply.nested', <String, Object?>{}), isNull);
    });

    test('list index path segment', () {
      expect(
        evalIn(r'$items.1', <String, Object?>{
          'items': <Object?>['a', 'b', 'c'],
        }),
        'b',
      );
    });

    test('DynamicExposable object traversal', () {
      expect(
          evalIn(r'$user.isLoggedIn', <String, Object?>{'user': _FakeUser()}),
          isTrue);
    });
  });

  group('operators', () {
    test(
        '==',
        () => expect(
            evalIn(r'$a == $b', <String, Object?>{'a': 1, 'b': 1}), isTrue));
    test(
        '!=',
        () => expect(
            evalIn(r'$a != $b', <String, Object?>{'a': 1, 'b': 2}), isTrue));
    test(
        '>',
        () => expect(
            evalIn(r'$a > $b', <String, Object?>{'a': 2, 'b': 1}), isTrue));
    test(
        '<',
        () => expect(
            evalIn(r'$a < $b', <String, Object?>{'a': 1, 'b': 2}), isTrue));
    test(
        '>=',
        () => expect(
            evalIn(r'$a >= $b', <String, Object?>{'a': 2, 'b': 2}), isTrue));
    test(
        '<=',
        () => expect(
            evalIn(r'$a <= $b', <String, Object?>{'a': 2, 'b': 2}), isTrue));
    test(
        '&&',
        () => expect(
            evalIn(r'$a && $b', <String, Object?>{'a': true, 'b': false}),
            isFalse));
    test(
        '||',
        () => expect(
            evalIn(r'$a || $b', <String, Object?>{'a': false, 'b': true}),
            isTrue));
    test('!',
        () => expect(evalIn(r'!$a', <String, Object?>{'a': false}), isTrue));
    test(
        '?? uses right when left is null',
        () => expect(
            evalIn(r'$a ?? $b', <String, Object?>{'a': null, 'b': 'fallback'}),
            'fallback'));
    test(
        '?? uses left when present',
        () => expect(
            evalIn(
                r'$a ?? $b', <String, Object?>{'a': 'value', 'b': 'fallback'}),
            'value'));
    test('+',
        () => expect(evalIn(r'$a + $b', <String, Object?>{'a': 1, 'b': 2}), 3));
    test(
        '+ concatenates strings',
        () => expect(
            evalIn(r'$a + $b', <String, Object?>{'a': 'foo', 'b': 'bar'}),
            'foobar'));
    test('-',
        () => expect(evalIn(r'$a - $b', <String, Object?>{'a': 5, 'b': 3}), 2));
    test(
        '*',
        () =>
            expect(evalIn(r'$a * $b', <String, Object?>{'a': 3, 'b': 4}), 12));
    test(
        '/',
        () =>
            expect(evalIn(r'$a / $b', <String, Object?>{'a': 6, 'b': 3}), 2.0));

    test('short-circuit && does not evaluate right when left is false', () {
      // Right side references a variable that isn't a bool, which would
      // throw a type error if evaluated; short-circuiting must skip it.
      expect(
          evalIn(r'$a && $b', <String, Object?>{'a': false, 'b': 'not a bool'}),
          isFalse);
    });

    test('short-circuit || does not evaluate right when left is true', () {
      expect(
          evalIn(r'$a || $b', <String, Object?>{'a': true, 'b': 'not a bool'}),
          isTrue);
    });
  });

  group('ternary', () {
    test('selects true branch', () {
      expect(
          evalIn(r'$ok ? "yes" : "no"', <String, Object?>{'ok': true}), 'yes');
    });

    test('selects false branch', () {
      expect(
          evalIn(r'$ok ? "yes" : "no"', <String, Object?>{'ok': false}), 'no');
    });

    test('only evaluates the taken branch', () {
      // The untaken branch is a variable path, which never throws even if
      // missing, so this mainly documents the short-circuit contract.
      expect(
          evalIn(r'$ok ? "yes" : $missing.path', <String, Object?>{'ok': true}),
          'yes');
    });
  });

  group('type errors are deterministic and reported', () {
    test('comparing non-numbers throws ExpressionException', () {
      expect(() => evalIn(r'$a > $b', <String, Object?>{'a': 'x', 'b': 'y'}),
          throwsA(isA<ExpressionException>()));
    });

    test('&& with non-bool operand throws ExpressionException', () {
      expect(() => evalIn(r'$a && $b', <String, Object?>{'a': 1, 'b': true}),
          throwsA(isA<ExpressionException>()));
    });

    test('ternary with non-bool condition throws ExpressionException', () {
      expect(
          () => evalIn(r'$a ? "x" : "y"', <String, Object?>{'a': 'not bool'}),
          throwsA(isA<ExpressionException>()));
    });
  });

  group('responsive expressions', () {
    test('arithmetic on screen width', () {
      expect(
          evalIn(r'$screen.width * 0.8', <String, Object?>{
            'screen': <String, Object?>{'width': 400}
          }),
          320.0);
    });

    test('conditional breakpoint', () {
      expect(
        evalIn(r'$screen.width > 600 ? 24 : 16', <String, Object?>{
          'screen': <String, Object?>{'width': 800},
        }),
        24,
      );
    });
  });
}

class _FakeUser implements DynamicExposable {
  @override
  Map<String, Object?> toDynamicValues() =>
      <String, Object?>{'isLoggedIn': true};
}
