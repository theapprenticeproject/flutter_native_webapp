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
}
