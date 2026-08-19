import 'package:dynamic_widget_parser_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(registerActions);

  testWidgets('example app renders the server-driven screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('View Profile'), findsOneWidget);

    await tester.tap(find.text('View Profile'));
    await tester.pump();
    expect(find.text('Opening profile…'), findsOneWidget);
  });

  testWidgets('playground tab renders live-edited source', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Live playground'));
    await tester.pumpAndSettle();

    expect(
      find.text('Edit the source on the left and watch this update.'),
      findsOneWidget,
    );
  });
}
