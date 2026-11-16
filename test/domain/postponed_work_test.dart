import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/postponed_work.dart';

/// R-66: "I'll do it later" on the Make step.
void main() {
  group('what happens after "do it later"', () {
    test('the quiz is not done yet: go on to the quiz', () {
      expect(afterDoItLater(quizDone: false), PostponeNext.quiz);
    });

    test('the quiz is already done: nothing is left today, leave', () {
      expect(afterDoItLater(quizDone: true), PostponeNext.leave);
    });
  });

  group('asking again to share the work after the quiz', () {
    test('postponed, quiz done, work not sent: ask', () {
      expect(
        shouldAskToShareWork(postponed: true, quizDone: true, workSent: false),
        isTrue,
      );
    });

    test('the student never postponed: do not ask', () {
      expect(
        shouldAskToShareWork(postponed: false, quizDone: true, workSent: false),
        isFalse,
      );
    });

    test('the work is already sent: do not ask', () {
      expect(
        shouldAskToShareWork(postponed: true, quizDone: true, workSent: true),
        isFalse,
      );
    });

    test('the quiz is not done: do not ask yet', () {
      expect(
        shouldAskToShareWork(postponed: true, quizDone: false, workSent: false),
        isFalse,
      );
    });
  });
}
