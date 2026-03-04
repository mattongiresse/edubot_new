// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:edubot_new/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Vérifie que ça commence à 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Simule un tap sur le bouton +
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Vérifie que c'est passé à 1
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
