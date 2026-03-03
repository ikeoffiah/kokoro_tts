// Smoke test for the Kokoro TTS example app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kokoro_tts_example/main.dart';

void main() {
  testWidgets('Example app shows TTS UI', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Kokoro TTS Example'), findsWidgets);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
