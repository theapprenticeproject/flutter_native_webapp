import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/models/class_chat_message_model.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_quiz_cards.dart';

/// After every question the chat shows whether the answer was right and what
/// the correct answer is (team request, 2026-11-18). It is a chat message, not a
/// pop-up that disappears: the tester did not see the pop-up.
Future<void> _pump(WidgetTester tester, Map<String, dynamic> data) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClassQuizFeedbackCard(
            message: ClassChatMessage(
              id: '1',
              stepId: 'AF-QUIZ-FEEDBACK',
              sender: ClassChatSender.bot,
              contentType: ClassChatContentType.quizFeedback,
              data: data,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('a right answer shows the correct answer too', (tester) async {
    await _pump(tester, {'isCorrect': true, 'correctOptionText': 'Paris'});
    // Design M-C21: a party emoji and "Correct Answer!" (the points of each
    // answer are not known: the quiz is sent once, at the end).
    expect(find.text('Correct Answer!'), findsOneWidget);
    expect(find.text('🎉'), findsOneWidget);
    expect(find.text('Correct answer: Paris'), findsOneWidget);
  });

  testWidgets(
    'a wrong answer shows it, and the explanation when there is one',
    (tester) async {
      await _pump(tester, {
        'isCorrect': false,
        'correctOptionText': 'Paris',
        'explanation': 'Paris is the capital.',
      });
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.text('Correct answer: Paris'), findsOneWidget);
      expect(find.text('Paris is the capital.'), findsOneWidget);
    },
  );

  testWidgets('no points are shown: the Worker gives the points (R-41)', (
    tester,
  ) async {
    await _pump(tester, {'isCorrect': true, 'correctOptionText': 'Paris'});
    expect(find.textContaining('points'), findsNothing);
  });
}
