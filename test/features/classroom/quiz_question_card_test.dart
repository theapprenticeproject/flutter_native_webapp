import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/models/class_chat_message_model.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_quiz_cards.dart';

/// Figma M-C21: the question is a card, and each answer is its own full-width
/// row under it (343 wide, 52 high, 16 apart). Colours: selected lavender
/// (#E8E8FB, purple border), wrong orange (#FCEFD6, #E8A13B), right green
/// (#E4F5EA, #2FA866). QA: the answers were narrow, inside the card.
final _message = ClassChatMessage(
  id: 'q1',
  stepId: 'AF-QUIZ-QUESTION',
  sender: ClassChatSender.bot,
  contentType: ClassChatContentType.quizQuestion,
  data: {
    'questionIndex': 0,
    'totalQuestions': 5,
    'question': 'Which of these can you make in ScratchJr?',
    'options': {'1': 'A story', '2': 'A game', '3': 'A dance'},
    'answerKey': '2',
  },
);

Future<List<String>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final answers = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ClassQuizQuestionCard(
            message: _message,
            awaiting: true,
            onAnswer: answers.add,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return answers;
}

BoxDecoration _decoration(WidgetTester tester, String key) =>
    tester
            .widget<Container>(
              find.descendant(
                of: find.byKey(ValueKey('quiz-option-$key')),
                matching: find.byType(Container),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  testWidgets(
    'the question and the answers are in the same column, full width',
    (tester) async {
      await _pump(tester);
      expect(
        find.text('Q1. Which of these can you make in ScratchJr?'),
        findsOneWidget,
      );
      final card = tester.getRect(find.byKey(const ValueKey('quiz-question')));
      final option = tester.getRect(
        find.byKey(const ValueKey('quiz-option-1')),
      );
      expect(
        option.width,
        card.width,
        reason: 'the answer is as wide as the card',
      );
      expect(option.height, greaterThanOrEqualTo(52));
      final second = tester.getRect(
        find.byKey(const ValueKey('quiz-option-2')),
      );
      expect(second.top - option.bottom, 16);
      expect(find.textContaining('Question 1 of'), findsNothing);
    },
  );

  testWidgets('a chosen answer is lavender with a purple border', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('A game'));
    await tester.pump();
    final d = _decoration(tester, '2');
    expect(d.color, const Color(0xFFE8E8FB));
    expect((d.border! as Border).top.color, const Color(0xFF5B5BD6));
  });

  testWidgets(
    'Confirm sends the answer; then right is green, wrong is orange',
    (tester) async {
      final answers = await _pump(tester);
      await tester.tap(find.text('A story')); // a wrong answer
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(answers, ['1']);
      expect(
        _decoration(tester, '2').color,
        const Color(0xFFE4F5EA),
      ); // the right one
      expect(
        _decoration(tester, '1').color,
        const Color(0xFFFCEFD6),
      ); // the wrong one
      expect(
        ((_decoration(tester, '1')).border! as Border).top.color,
        const Color(0xFFE8A13B),
      );
    },
  );

  testWidgets('Confirm waits for an answer', (tester) async {
    await _pump(tester);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
