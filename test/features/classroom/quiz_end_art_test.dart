import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/providers/quiz_end_art.dart';

/// QA bug 19: the "WOW CHAMP" celebration was shown even for 0 out of 5. The
/// design shows it for a good score (4 of 5, C22) and has no picture for a low
/// one, so for now a score of 0 gets no celebration picture.
void main() {
  test('some answers right: the WOW CHAMP picture', () {
    expect(
      quizEndArt(correct: 4, total: 5),
      'assets/class-screen/won-champ.png',
    );
    expect(
      quizEndArt(correct: 5, total: 5),
      'assets/class-screen/won-champ.png',
    );
    expect(
      quizEndArt(correct: 1, total: 5),
      'assets/class-screen/won-champ.png',
    );
  });

  test('nothing right: no celebration picture', () {
    expect(quizEndArt(correct: 0, total: 5), isNull);
  });

  test('a quiz with no questions has no picture either', () {
    expect(quizEndArt(correct: 0, total: 0), isNull);
  });
}
