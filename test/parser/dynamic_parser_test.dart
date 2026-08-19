import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter_test/flutter_test.dart';

WidgetNode parseWidget(String source) =>
    DynamicParser(source).parseToAst() as WidgetNode;

void main() {
  group('widgets', () {
    test('simple widget with no args', () {
      final WidgetNode node = parseWidget('Spacer()');
      expect(node.name, 'Spacer');
      expect(node.constructorName, isNull);
      expect(node.properties, isEmpty);
      expect(node.positionalArguments, isEmpty);
    });

    test('named constructor', () {
      final WidgetNode node = parseWidget('EdgeInsets.all(16)');
      expect(node.name, 'EdgeInsets');
      expect(node.constructorName, 'all');
      expect(node.fullName, 'EdgeInsets.all');
      expect((node.positionalArguments.single as IntValueNode).value, 16);
    });

    test('named arguments', () {
      final WidgetNode node =
          parseWidget('Container(color: Colors.blue, width: 10)');
      expect(node.properties.map((PropertyNode p) => p.name),
          <String>['color', 'width']);
    });

    test('positional and named arguments together', () {
      final WidgetNode node = parseWidget('Text("Hello", style: null)');
      expect(
          (node.positionalArguments.single as StringValueNode).value, 'Hello');
      expect(node.properties.single.name, 'style');
    });

    test('nested widgets', () {
      final WidgetNode node = parseWidget('Container(child: Text("hi"))');
      final ValueNode child = node.property('child')!.value;
      expect(child, isA<WidgetNode>());
      expect((child as WidgetNode).name, 'Text');
    });

    test('children list', () {
      final WidgetNode node =
          parseWidget('Row(children: [Text("A"), Text("B")])');
      final ListValueNode children =
          node.property('children')!.value as ListValueNode;
      expect(children.items, hasLength(2));
    });

    test('deeply nested widgets to a reasonable depth', () {
      final StringBuffer source = StringBuffer();
      const int depth = 30;
      for (int i = 0; i < depth; i++) {
        source.write('Container(child: ');
      }
      source.write('Text("leaf")');
      source.write(')' * depth);
      final WidgetNode node = parseWidget(source.toString());
      expect(node.name, 'Container');
      expect(node.depth, greaterThan(depth));
    });

    test('trailing comma in argument list', () {
      final WidgetNode node =
          parseWidget('Container(\n  padding: EdgeInsets.all(8),\n)');
      expect(node.properties.single.name, 'padding');
    });

    test('no trailing comma works identically', () {
      final WidgetNode node =
          parseWidget('Container(\n  padding: EdgeInsets.all(8)\n)');
      expect(node.properties.single.name, 'padding');
    });

    test('trailing comma in list', () {
      final WidgetNode node =
          parseWidget('Row(children: [Text("A"), Text("B"),])');
      expect((node.property('children')!.value as ListValueNode).items,
          hasLength(2));
    });
  });

  group('lists and maps', () {
    test('empty list', () {
      final ListValueNode node =
          DynamicParser('[]').parseToAst() as ListValueNode;
      expect(node.items, isEmpty);
    });

    test('nested lists', () {
      final ListValueNode node =
          DynamicParser('[[1, 2], [3]]').parseToAst() as ListValueNode;
      expect(node.items, hasLength(2));
      expect((node.items[0] as ListValueNode).items, hasLength(2));
    });

    test('map with string keys', () {
      final MapValueNode node = DynamicParser('{"id": 123, "name": "John"}')
          .parseToAst() as MapValueNode;
      expect(node.entries, hasLength(2));
      expect((node.entries[0].key as StringValueNode).value, 'id');
      expect((node.entries[0].value as IntValueNode).value, 123);
    });

    test('trailing comma in map', () {
      final MapValueNode node =
          DynamicParser('{"a": 1,}').parseToAst() as MapValueNode;
      expect(node.entries, hasLength(1));
    });
  });

  group('literals', () {
    test('all primitive literal kinds', () {
      expect(DynamicParser('null').parseToAst(), isA<NullValueNode>());
      expect(DynamicParser('true').parseToAst(), isA<BoolValueNode>());
      expect(DynamicParser('42').parseToAst(), isA<IntValueNode>());
      expect(DynamicParser('4.2').parseToAst(), isA<DoubleValueNode>());
      expect(DynamicParser('"s"').parseToAst(), isA<StringValueNode>());
    });

    test('negative number literal', () {
      final IntValueNode node =
          DynamicParser('-8').parseToAst() as IntValueNode;
      expect(node.value, -8);
    });

    test('negative double literal', () {
      final DoubleValueNode node =
          DynamicParser('-8.5').parseToAst() as DoubleValueNode;
      expect(node.value, -8.5);
    });
  });

  group('identifier paths', () {
    test('dotted enum path', () {
      final IdentifierPathValueNode node =
          DynamicParser('MainAxisAlignment.center').parseToAst()
              as IdentifierPathValueNode;
      expect(node.path, <String>['MainAxisAlignment', 'center']);
    });

    test('multi-segment shade path', () {
      final IdentifierPathValueNode node = DynamicParser('Colors.blue.shade200')
          .parseToAst() as IdentifierPathValueNode;
      expect(node.joined, 'Colors.blue.shade200');
    });
  });

  group('expressions', () {
    ExpressionNode expr(String source) {
      final WidgetNode node = parseWidget('Text(style: $source)');
      return node.property('style')!.value as ExpressionNode;
    }

    test('variable path', () {
      final VariablePathExpressionNode node =
          expr(r'$user.name') as VariablePathExpressionNode;
      expect(node.path, <String>['user', 'name']);
    });

    test('ternary', () {
      final ConditionalExpressionNode node =
          expr(r'$user.isLoggedIn ? "Logout" : "Login"')
              as ConditionalExpressionNode;
      expect(node.condition, isA<VariablePathExpressionNode>());
    });

    test('operator precedence: && binds tighter than ||', () {
      final BinaryExpressionNode node =
          expr(r'$a || $b && $c') as BinaryExpressionNode;
      expect(node.operator, BinaryOperator.or);
      expect((node.right as BinaryExpressionNode).operator, BinaryOperator.and);
    });

    test('operator precedence: comparisons bind tighter than equality', () {
      final BinaryExpressionNode node =
          expr(r'$a > 1 == $b') as BinaryExpressionNode;
      expect(node.operator, BinaryOperator.equal);
      expect(
          (node.left as BinaryExpressionNode).operator, BinaryOperator.greater);
    });

    test('arithmetic precedence', () {
      final BinaryExpressionNode node =
          expr(r'$a + $b * $c') as BinaryExpressionNode;
      expect(node.operator, BinaryOperator.add);
      expect((node.right as BinaryExpressionNode).operator,
          BinaryOperator.multiply);
    });

    test('unary not and negate', () {
      final UnaryExpressionNode node = expr(r'!$a') as UnaryExpressionNode;
      expect(node.operator, UnaryOperator.not);
    });

    test('parenthesized grouping overrides precedence', () {
      final BinaryExpressionNode node =
          expr(r'($a + $b) * $c') as BinaryExpressionNode;
      expect(node.operator, BinaryOperator.multiply);
      expect((node.left as BinaryExpressionNode).operator, BinaryOperator.add);
    });

    test('null-coalescing', () {
      final BinaryExpressionNode node =
          expr(r'$a ?? $b') as BinaryExpressionNode;
      expect(node.operator, BinaryOperator.nullCoalesce);
    });
  });

  group('syntax errors', () {
    test('unterminated argument list', () {
      expect(() => DynamicParser('Container(child: Text("hi")').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('unexpected trailing content', () {
      expect(() => DynamicParser('Container() Container()').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('missing colon in named argument', () {
      expect(() => DynamicParser('Container(color Colors.blue)').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('duplicate named argument', () {
      expect(
          () =>
              DynamicParser('Container(color: Colors.blue, color: Colors.red)')
                  .parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('unclosed list', () {
      expect(() => DynamicParser('[1, 2').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('unclosed map', () {
      expect(() => DynamicParser('{"a": 1').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('bad expression syntax', () {
      expect(() => DynamicParser(r'Text(style: $a $b)').parseToAst(),
          throwsA(isA<SyntaxException>()));
    });

    test('completely invalid input still throws a DynamicParserException', () {
      expect(() => DynamicParser(')(*&^%').parseToAst(),
          throwsA(isA<DynamicParserException>()));
    });
  });

  group('resource limits', () {
    test('exceeding max AST depth throws SyntaxException', () {
      final StringBuffer source = StringBuffer();
      const int depth = 50;
      for (int i = 0; i < depth; i++) {
        source.write('Container(child: ');
      }
      source.write('Text("leaf")');
      source.write(')' * depth);
      final DynamicParser parser = DynamicParser(
        source.toString(),
        limits: const DynamicParserLimits(maxAstDepth: 10),
      );
      expect(parser.parseToAst, throwsA(isA<SyntaxException>()));
    });

    test('exceeding max list length throws SyntaxException', () {
      final String source =
          'Row(children: [${List<String>.filled(20, 'Text("x")').join(',')}])';
      final DynamicParser parser = DynamicParser(source,
          limits: const DynamicParserLimits(maxListLength: 5));
      expect(parser.parseToAst, throwsA(isA<SyntaxException>()));
    });

    test('exceeding max source length throws SyntaxException', () {
      final DynamicParser parser = DynamicParser('Container()',
          limits: const DynamicParserLimits(maxSourceLength: 5));
      expect(parser.parseToAst, throwsA(isA<SyntaxException>()));
    });

    test('exceeding max widget count throws SyntaxException', () {
      final String source =
          'Row(children: [${List<String>.filled(50, 'Text("x")').join(',')}])';
      final DynamicParser parser = DynamicParser(source,
          limits: const DynamicParserLimits(maxWidgetCount: 20));
      expect(parser.parseToAst, throwsA(isA<SyntaxException>()));
    });
  });
}
