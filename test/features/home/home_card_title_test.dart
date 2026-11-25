import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/home/presentation/widgets/quiz_pending_card.dart';
import 'package:tapapp/features/home/presentation/widgets/send_project_card.dart';
import 'package:tapapp/features/home/presentation/widgets/start_activity_card.dart';
import 'package:tapapp/features/home/presentation/widgets/submission_pending_card.dart';

/// The Home design (M-F2-01): the card has only the activity title, bold, about
/// 24. Ours had an extra line "Core 003 1" above a lighter, larger title.
const _title = 'Get Ready For ScratchJr';

Future<void> _pump(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = const Size(412, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: card)),
      ),
    ),
  );
  await tester.pump();
  tester.takeException(); // the test font is wider than Inter
}

void main() {
  final cards = <String, Widget>{
    'start activity': StartActivityCard(
      courseDisplay: '003',
      unitName: _title,
      thumbnailAsset: 'assets/none.webp',
      onStart: () {},
    ),
    'quiz pending': QuizPendingCard(
      courseDisplay: '003',
      unitName: _title,
      onStartQuiz: () {},
    ),
    'send project': SendProjectCard(
      courseDisplay: '003',
      unitName: _title,
      onSend: () {},
    ),
    'submission pending': const SubmissionPendingCard(
      courseDisplay: '003',
      unitName: _title,
      slow: false,
    ),
  };

  for (final entry in cards.entries) {
    testWidgets(
      '${entry.key}: the title is bold 24 and there is no "Core" line',
      (tester) async {
        await _pump(tester, entry.value);
        final style = tester.widget<Text>(find.text(_title)).style;
        expect(style?.fontSize, 24);
        expect(style?.fontWeight, FontWeight.w700);
        expect(find.textContaining('Core'), findsNothing);
      },
    );
  }
}
