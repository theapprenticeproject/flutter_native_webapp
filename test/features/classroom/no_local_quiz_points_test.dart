import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R-41 and the API contract: the app shows the points the Worker gives (+1 for
/// each right answer, in the `submit_quiz` answer). It never works them out.
/// The old prototype gave 5 points for each right answer on the phone.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('no code gives points for a right answer', () {
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        final text = read(f.path);
        if (text.contains('_quizPointsPerCorrectAnswer') ||
            text.contains('{{quiz_points}}')) {
          found.add(f.path);
        }
      }
    }
    expect(found, isEmpty);
  });

  test(
    'the flow text does not promise quiz points before the Worker answers',
    () {
      for (final f in Directory('assets/flows').listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.json')) {
          expect(read(f.path).contains('quiz_points'), isFalse, reason: f.path);
        }
      }
    },
  );

  test('the right-answer message shows no points', () {
    final text = read('lib/features/classroom/presentation/class_screen.dart');
    expect(text.contains(r'+${toast.points}'), isFalse);
  });

  test('the quiz is sent to the Worker', () {
    final text = read(
      'lib/features/classroom/providers/class_chat_controller.dart',
    );
    expect(text.contains('recordQuiz('), isTrue);
  });

  test('submission points are the Worker points, not the content file xp', () {
    final text = read(
      'lib/features/classroom/providers/class_chat_controller.dart',
    );
    expect(text.contains('_saveSubmissionProgress(_currentUnit.xp)'), isFalse);
    expect(text.contains('explicitPoints: _currentUnit.xp'), isFalse);
    expect(text.contains("'points': _currentUnit.xp"), isFalse);
  });

  test('a photo or video goes to the Worker through WorkSubmitter', () {
    final text = read(
      'lib/features/classroom/providers/class_chat_controller.dart',
    );
    expect(text.contains('_workSubmitter.submit('), isTrue);
  });

  test('sending the work does not mark the submission step as done (R-83)', () {
    final text = read(
      'lib/features/classroom/providers/class_chat_controller.dart',
    );
    expect(text.contains('submissionSentOnly: sentOnly'), isTrue);
    expect(text.contains('_feedbackAllowsCompletion'), isTrue);
  });

  test(
    'the Results chat closes the unit, and not the first valid check (R-68)',
    () {
      final text = read(
        'lib/features/classroom/providers/class_chat_controller.dart',
      );
      // The submission step is marked done only when the chat is over.
      expect('applyValidFeedback('.allMatches(text).length, 1);
      expect(text.contains("case 'results_done'"), isTrue);
      expect(text.contains('startNewAttempt('), isTrue, reason: 'send again');
    },
  );
}
