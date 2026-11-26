import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/home/presentation/widgets/activity_card.dart';
import 'package:tapapp/features/home/presentation/widgets/quiz_pending_card.dart';
import 'package:tapapp/features/home/presentation/widgets/send_project_card.dart';
import 'package:tapapp/features/home/presentation/widgets/start_activity_card.dart';
import 'package:tapapp/features/home/presentation/widgets/submission_pending_card.dart';

/// QA: "Home > Submit Project and Quiz: buttons and UI colours are inconsistent
/// and do not match the design". Figma has one activity card (M-F2-01): a
/// thumbnail, the title, a chip (#FCEFD6) and a 56 high primary button
/// (#5B5BD6). The four Home cards must all look like it.
const _title = 'Get Ready For ScratchJr';
const _thumb = 'assets/none.webp';

Future<void> _pump(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = const Size(412, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: card,
          ),
        ),
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
      thumbnailAsset: _thumb,
      onStart: () {},
    ),
    'quiz pending': QuizPendingCard(
      courseDisplay: '003',
      unitName: _title,
      thumbnailAsset: _thumb,
      onStartQuiz: () {},
    ),
    'send project': SendProjectCard(
      courseDisplay: '003',
      unitName: _title,
      thumbnailAsset: _thumb,
      onSend: () {},
    ),
    'submission pending': const SubmissionPendingCard(
      courseDisplay: '003',
      unitName: _title,
      thumbnailAsset: _thumb,
      slow: false,
    ),
  };

  for (final entry in cards.entries) {
    testWidgets('${entry.key}: thumbnail, a 56 high purple button', (
      tester,
    ) async {
      await _pump(tester, entry.value);
      expect(find.byKey(const ValueKey('activity-thumb')), findsOneWidget);
      final button = find.byType(ElevatedButton);
      expect(tester.getSize(button).height, 56);
      final style = tester.widget<ElevatedButton>(button).style!;
      expect(style.backgroundColor!.resolve({}), const Color(0xFF5B5BD6));
    });
  }

  for (final name in ['quiz pending', 'send project', 'submission pending']) {
    testWidgets('$name: the chip has the design colours', (tester) async {
      await _pump(tester, cards[name]!);
      final chip = tester.widget<Container>(
        find.byKey(const ValueKey('activity-chip')),
      );
      expect(
        (chip.decoration! as BoxDecoration).color,
        const Color(0xFFFCEFD6),
      );
    });
  }

  testWidgets('the start card has no chip (no points to show yet)', (
    tester,
  ) async {
    await _pump(tester, cards['start activity']!);
    expect(find.byKey(const ValueKey('activity-chip')), findsNothing);
  });

  testWidgets('the title and the button sit in the same place on every card', (
    tester,
  ) async {
    final titles = <Offset>[];
    final buttons = <Rect>[];
    final gapsToBottom = <double>[];
    for (final card in cards.values) {
      await _pump(tester, card);
      titles.add(tester.getTopLeft(find.text(_title)));
      final button = tester.getRect(find.byType(ElevatedButton));
      buttons.add(button);
      // A card with an explanation (the waiting card) is taller, so the button
      // is compared with the bottom of its own card.
      gapsToBottom.add(
        tester.getRect(find.byType(ActivityCard)).bottom - button.bottom,
      );
    }
    expect(titles.map((o) => o.dx).toSet().length, 1, reason: '$titles');
    expect(titles.map((o) => o.dy).toSet().length, 1, reason: '$titles');
    expect(buttons.map((r) => r.left).toSet().length, 1, reason: '$buttons');
    expect(buttons.map((r) => r.width).toSet().length, 1, reason: '$buttons');
    expect(gapsToBottom.toSet().length, 1, reason: '$gapsToBottom');
  });
}
