import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/home/presentation/widgets/send_project_card.dart';

/// R-4: the Home card "send project". v1 has no timer on an activity (R-72) and
/// no gems (R-39). The card once showed made-up text under the button:
/// "Send in 2days 15hrs and earn extra 2💎".
void main() {
  testWidgets('shows the button and no made-up timer or gems', (tester) async {
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SendProjectCard(
              courseDisplay: 'Science',
              unitName: 'Glowing LED Card',
              points: 5,
              onSend: () => sent++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // The test font is wider than Inter, so the points chip may report a small
    // layout overflow here. This test is about the words, not the layout.
    tester.takeException();

    expect(find.text('Send my project'), findsOneWidget);
    await tester.tap(find.text('Send my project'));
    expect(sent, 1);

    for (final word in [
      'Send in',
      'days',
      'hrs',
      '💎',
      'extra',
      'earn extra',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    expect(find.textContaining('Glowing LED Card'), findsOneWidget);
  });

  test('no screen in lib/ has a made-up deadline or a gem', () {
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains('/onboarding/')) continue; // removed with onboarding
      final text = f.readAsStringSync();
      if (text.contains('💎') ||
          RegExp(r"'\d+\s*days?\s*\d*\s*hrs").hasMatch(text)) {
        found.add(f.path);
      }
    }
    expect(found, isEmpty);
  });
}
