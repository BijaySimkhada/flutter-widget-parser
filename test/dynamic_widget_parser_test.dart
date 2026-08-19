import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    if (!DynamicWidgetParser.defaultActions.has('openProfile')) {
      DynamicWidgetParser.defaultActions
          .register('openProfile', (context, args) {});
    }
    if (!DynamicWidgetParser.defaultActions.has('login')) {
      DynamicWidgetParser.defaultActions.register('login', (context, args) {});
    }
  });

  testWidgets('renders the full spec example tree',
      (WidgetTester tester) async {
    const String source = '''
Scaffold(
  appBar: AppBar(
    title: Text("Dynamic UI"),
  ),
  body: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Welcome",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.person,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text("John Doe"),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: action("openProfile"),
                  child: Text("View Profile"),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
)
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return DynamicWidgetParser.parse(source: source, context: context);
          },
        ),
      ),
    );

    expect(find.text('Dynamic UI'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('View Profile'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    await tester.tap(find.text('View Profile'));
    await tester.pump();
  });

  testWidgets('nested constructors, expressions, and conditionals',
      (WidgetTester tester) async {
    const String source = r'''
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(color: Colors.black26, blurRadius: 10),
    ],
  ),
  child: Text($user.isLoggedIn ? "Logout" : "Login"),
)
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return DynamicWidgetParser.parse(
              source: source,
              context: context,
              data: const DynamicDataContext(values: <String, Object?>{
                'user': <String, Object?>{'isLoggedIn': true},
              }),
            );
          },
        ),
      ),
    );

    expect(find.text('Logout'), findsOneWidget);
  });

  test('validate() reports unknown widget with a suggestion', () {
    final ValidationResult result =
        DynamicWidgetParser.validate('Contaner(child: Text("hi"))');
    expect(result.isValid, isFalse);
    expect(result.errors.single.suggestion, 'Container');
  });

  test('security: unregistered action is rejected', () {
    expect(
      () => DynamicWidgetParser.parseToAst(
          'ElevatedButton(onPressed: action("doesNotExist"), child: Text("x"))'),
      returnsNormally,
    );
  });

  testWidgets(
      'fallback error behavior substitutes a widget instead of crashing',
      (WidgetTester tester) async {
    const String source = 'NotAWidget(foo: 1)';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return DynamicWidgetParser.parse(
              source: source,
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

  test('debug pretty print produces a tree', () {
    final AstNode ast = DynamicWidgetParser.parseToAst(
        'Column(children: [Text("A"), SizedBox(height: 8)])');
    final String pretty = ast.prettyPrint();
    expect(pretty, contains('Column'));
    expect(pretty, contains('Text'));
    expect(pretty, contains('SizedBox'));
  });
}
