import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/home/presentation/widgets/quiz_pending_card.dart';
import 'package:tapapp/features/home/presentation/widgets/send_project_card.dart';
import 'package:tapapp/features/home/presentation/widgets/start_activity_card.dart';

/// R-41: points belong to the Worker. A Home card must not advertise a number
/// taken from the content file ("You'll earn 20 Points"), because the Worker
/// gives other points (video 10, work 25, quiz 1 for each right answer, and 10
/// for valid feedback). The card shows the activity, not a made-up number.
void main() {
  Future<void> pump(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: card)),
      ),
    );
    await tester.pump();
    tester.takeException(); // the test font is wider than Inter (layout only)
  }

  testWidgets('Start activity: name and button, no points promise', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      StartActivityCard(
        courseDisplay: 'Science',
        unitName: 'Glowing LED Card',
        thumbnailAsset: 'assets/none.webp',
        onStart: () => taps++,
      ),
    );
    expect(find.text('Glowing LED Card'), findsOneWidget);
    expect(find.textContaining("You'll earn"), findsNothing);
    expect(find.textContaining('Points'), findsNothing);
    await tester.tap(find.text('Start Activity'));
    expect(taps, 1);
  });

  testWidgets('Send project: name and button, no points promise', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      SendProjectCard(
        courseDisplay: 'Science',
        unitName: 'Glowing LED Card',
        onSend: () => taps++,
      ),
    );
    expect(find.text('Glowing LED Card'), findsOneWidget);
    expect(find.textContaining("You'll earn"), findsNothing);
    expect(find.textContaining('Points'), findsNothing);
    await tester.tap(find.text('Send my project'));
    expect(taps, 1);
  });

  testWidgets('Quiz pending: name and button, no points promise', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      QuizPendingCard(
        courseDisplay: 'Science',
        unitName: 'Glowing LED Card',
        onStartQuiz: () => taps++,
      ),
    );
    expect(find.text('Glowing LED Card'), findsOneWidget);
    expect(find.textContaining("You'll earn"), findsNothing);
    expect(find.textContaining('Points'), findsNothing);
    await tester.tap(find.text('Start Quiz'));
    expect(taps, 1);
  });

  test('no screen takes display points from the content file', () {
    final found = <String>[];
    final forbidden = RegExp(
      r"videoPoints|submissionPoints|totalPoints|nextUnitPoints|You'll earn",
    );
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains('/onboarding/')) continue;
      for (final line in f.readAsLinesSync()) {
        if (forbidden.hasMatch(line)) found.add('${f.path}: ${line.trim()}');
      }
    }
    expect(found, isEmpty);
  });
}
