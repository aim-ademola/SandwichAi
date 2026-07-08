// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sandwich_ai/main.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';

void main() {
  testWidgets('App builds the production shell', (WidgetTester tester) async {
    AppEnvironment.configure(AppEnvironment.prod());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
