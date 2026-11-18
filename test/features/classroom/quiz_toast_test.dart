import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/providers/class_chat_controller.dart';

void main() {
  test(
    'the correct answer is shown after a right and after a wrong answer',
    () {
      const right = ClassQuizToast(
        id: 1,
        isCorrect: true,
        correctAnswer: 'Paris',
      );
      const wrong = ClassQuizToast(
        id: 2,
        isCorrect: false,
        correctAnswer: 'Paris',
      );
      expect(right.message, 'Correct! Correct answer: Paris');
      expect(wrong.message, 'Not quite. Correct answer: Paris');
    },
  );
}
