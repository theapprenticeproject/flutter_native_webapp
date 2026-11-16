import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/picture_pieces.dart';

/// R-69: today's picture has 4 pieces. One unlocks for each step the student
/// finishes. The 4th unlocks only after valid feedback.
void main() {
  int pieces({
    bool video = false,
    bool work = false,
    bool quiz = false,
    bool valid = false,
  }) => unlockedPieces(
    videoDone: video,
    workSent: work,
    quizDone: quiz,
    feedbackValid: valid,
  );

  test('nothing done: 0 of 4', () {
    expect(pieces(), 0);
  });

  test('the usual order: video 1, work 2, quiz 3, valid feedback 4', () {
    expect(pieces(video: true), 1);
    expect(pieces(video: true, work: true), 2);
    expect(pieces(video: true, work: true, quiz: true), 3);
    expect(pieces(video: true, work: true, quiz: true, valid: true), 4);
  });

  test('Make postponed: the quiz gives 2 of 4 and the work then gives 3', () {
    expect(pieces(video: true, quiz: true), 2);
    expect(pieces(video: true, quiz: true, work: true), 3);
  });

  test('work sent but the feedback is not valid: it stays at 3 of 4', () {
    expect(pieces(video: true, work: true, quiz: true, valid: false), 3);
  });

  test('the 4th piece needs valid feedback, whatever else is done', () {
    expect(pieces(valid: true), 1, reason: 'only the feedback piece counts');
    expect(pieces(video: true, work: true, quiz: true, valid: true), 4);
  });

  test('the picture is revealed in quarters', () {
    expect([0, 1, 2, 3, 4].map(pieceFraction), [0.0, 0.25, 0.5, 0.75, 1.0]);
  });
}
