import 'package:dynamic_widget_parser/dynamic_widget_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpDsl(
  WidgetTester tester,
  String source, {
  DynamicDataContext? data,
  DynamicParserConfig? config,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return DynamicWidgetParser.parse(
                source: source, context: context, data: data, config: config);
          },
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    DynamicWidgetParser.defaultActions.register(
        'tapped', (BuildContext context, Map<String, Object?> args) {});
  });

  testWidgets('Text renders its data and style', (WidgetTester tester) async {
    await pumpDsl(tester,
        'Text("Hello World", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))');
    final Text widget = tester.widget(find.text('Hello World'));
    expect(widget.style!.fontSize, 20);
    expect(widget.style!.fontWeight, FontWeight.bold);
  });

  testWidgets('Container applies padding and color',
      (WidgetTester tester) async {
    await pumpDsl(tester,
        'Container(padding: EdgeInsets.all(16), color: Colors.blue, child: Text("x"))');
    final Container widget = tester.widget(find.byType(Container));
    expect(widget.padding, const EdgeInsets.all(16));
    expect(widget.color, Colors.blue);
  });

  testWidgets('Column lays out children in order', (WidgetTester tester) async {
    await pumpDsl(
        tester, 'Column(children: [Text("A"), Text("B"), Text("C")])');
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('Row renders children horizontally', (WidgetTester tester) async {
    await pumpDsl(tester,
        'Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("A"), Text("B")])');
    final Row widget = tester.widget(find.byType(Row));
    expect(widget.mainAxisAlignment, MainAxisAlignment.spaceBetween);
  });

  testWidgets('Stack overlays children', (WidgetTester tester) async {
    await pumpDsl(tester,
        'Stack(children: [SizedBox(width: 10, height: 10), Text("on top")])');
    // Ambient framework chrome (Overlay, etc.) also uses Stack, so assert
    // "at least one" rather than an exact count.
    expect(find.byType(Stack), findsWidgets);
    expect(find.text('on top'), findsOneWidget);
  });

  testWidgets('ListView renders items', (WidgetTester tester) async {
    await pumpDsl(
        tester, 'ListView(children: [Text("Item 1"), Text("Item 2")])');
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
  });

  testWidgets('Card wraps its child', (WidgetTester tester) async {
    await pumpDsl(tester, 'Card(child: Text("card content"))');
    expect(
        find.ancestor(
            of: find.text('card content'), matching: find.byType(Card)),
        findsOneWidget);
  });

  testWidgets('ElevatedButton triggers a registered action on tap',
      (WidgetTester tester) async {
    bool tapped = false;
    DynamicWidgetParser.defaultActions.register('recordTap',
        (BuildContext context, Map<String, Object?> args) {
      tapped = true;
    });
    await pumpDsl(tester,
        'ElevatedButton(onPressed: action("recordTap"), child: Text("Go"))');
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('action arguments are passed through, including expressions',
      (WidgetTester tester) async {
    Map<String, Object?>? received;
    DynamicWidgetParser.defaultActions.register('withArgs',
        (BuildContext context, Map<String, Object?> args) {
      received = args;
    });
    await pumpDsl(
      tester,
      r'ElevatedButton(onPressed: action("withArgs", {"userId": $user.id}), child: Text("Go"))',
      data: const DynamicDataContext(values: <String, Object?>{
        'user': <String, Object?>{'id': 42},
      }),
    );
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(received, <String, Object?>{'userId': 42});
  });

  testWidgets('Icon renders a registered icon', (WidgetTester tester) async {
    await pumpDsl(tester, 'Icon(Icons.home, size: 32, color: Colors.red)');
    final Icon widget = tester.widget(find.byType(Icon));
    expect(widget.icon, Icons.home);
    expect(widget.size, 32);
    expect(widget.color, Colors.red);
  });

  testWidgets('Image.network builds with a src and fit',
      (WidgetTester tester) async {
    await pumpDsl(tester,
        'Image.network("https://example.com/a.png", fit: BoxFit.cover)');
    final Image widget = tester.widget(find.byType(Image));
    expect(widget.fit, BoxFit.cover);
    final NetworkImage provider = widget.image as NetworkImage;
    expect(provider.url, 'https://example.com/a.png');
    // The test binding has no real network access, so the image itself
    // fails to decode — that's expected here and orthogonal to what this
    // test checks (that the widget was constructed correctly).
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('CircularProgressIndicator renders', (WidgetTester tester) async {
    await pumpDsl(tester, 'CircularProgressIndicator(value: 0.5)');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Checkbox and Switch reflect their bound value',
      (WidgetTester tester) async {
    await pumpDsl(tester,
        'Column(children: [Checkbox(value: true), Switch(value: false)])');
    final Checkbox checkbox = tester.widget(find.byType(Checkbox));
    final Switch switchWidget = tester.widget(find.byType(Switch));
    expect(checkbox.value, isTrue);
    expect(switchWidget.value, isFalse);
  });

  testWidgets(
      'nested widget-typed properties (child/children) resolve recursively',
      (WidgetTester tester) async {
    await pumpDsl(tester, '''
Padding(
  padding: EdgeInsets.all(8),
  child: Column(
    children: [
      Row(children: [Icon(Icons.star), Text("rating")]),
      Divider(),
    ],
  ),
)
''');
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('rating'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('conditional/responsive expressions affect layout',
      (WidgetTester tester) async {
    await pumpDsl(
      tester,
      r'SizedBox(width: $screen.width > 600 ? 24 : 16, height: 1)',
      data: const DynamicDataContext(values: <String, Object?>{
        'screen': <String, Object?>{'width': 800},
      }),
    );
    final SizedBox widget = tester.widget(find.byType(SizedBox).first);
    expect(widget.width, 24);
  });
}
