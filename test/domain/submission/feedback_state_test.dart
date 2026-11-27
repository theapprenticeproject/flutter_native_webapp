import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/progress/progress_models.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';

/// R-68, R-76, R-83, R-92: where the student's work stands.
SubmissionInfo _row({
  String status = 'Completed',
  String? result = 'Success - Original',
  int? score = 78,
  int attempt = 1,
  int left = 1,
  String? createdAt,
}) => SubmissionInfo(
  id: 'S',
  assignmentId: 'AS-1',
  status: status,
  resultStatus: result,
  score: score,
  attemptNumber: attempt,
  attemptsRemaining: left,
  createdAt: createdAt == null ? null : DateTime.parse(createdAt),
);

void main() {
  final now = DateTime.utc(2026, 11, 16, 12);

  test('no submission: not sent', () {
    expect(feedbackStage(null, now: now), FeedbackStage.notSent);
  });

  group('waiting', () {
    test('pending, sent a few hours ago: waiting', () {
      final row = _row(
        status: 'Pending',
        result: 'Pending',
        score: null,
        createdAt: '2026-11-16T08:00:00Z',
      );
      expect(feedbackStage(row, now: now), FeedbackStage.waiting);
    });

    test('processing counts as waiting', () {
      expect(
        feedbackStage(
          _row(status: 'Processing', result: 'Pending'),
          now: now,
        ),
        FeedbackStage.waiting,
      );
    });

    test('pending for more than 24 hours: taking longer than expected', () {
      final row = _row(
        status: 'Pending',
        result: 'Pending',
        createdAt: '2026-11-15T11:59:00Z',
      );
      expect(feedbackStage(row, now: now), FeedbackStage.slow);
    });

    test('exactly at the limit is still waiting', () {
      final row = _row(
        status: 'Pending',
        result: 'Pending',
        createdAt: '2026-11-15T12:00:00Z',
      );
      expect(feedbackStage(row, now: now), FeedbackStage.waiting);
    });

    test('no send time known: waiting, never slow', () {
      final row = _row(status: 'Pending', result: 'Pending');
      expect(feedbackStage(row, now: now), FeedbackStage.waiting);
    });

    test('the slow limit can be changed', () {
      final row = _row(
        status: 'Pending',
        result: 'Pending',
        createdAt: '2026-11-16T08:00:00Z',
      );
      expect(
        feedbackStage(row, now: now, slowAfter: const Duration(hours: 2)),
        FeedbackStage.slow,
      );
    });
  });

  group('result', () {
    test('Success - Original with a score: valid', () {
      expect(feedbackStage(_row(), now: now), FeedbackStage.valid);
    });

    test('flagged, with an attempt left: not valid, can send again', () {
      expect(
        feedbackStage(_row(result: 'Success - Flagged', left: 1), now: now),
        FeedbackStage.notValid,
      );
    });

    test('score 0 is not valid (R-92: the AI failed)', () {
      expect(feedbackStage(_row(score: 0), now: now), FeedbackStage.notValid);
    });

    test('an unknown result value is not valid', () {
      expect(
        feedbackStage(_row(result: 'Needs Retry'), now: now),
        FeedbackStage.notValid,
      );
    });

    // There is no limit on the number of attempts any more: a student sends
    // again until the work is right. Attempt 2, 7 or 20 is never "stuck".
    test('not valid is always "send again", whatever the attempt number', () {
      for (final attempt in [1, 2, 7, 20]) {
        expect(
          feedbackStage(
            _row(result: 'Failed', left: 0, attempt: attempt),
            now: now,
          ),
          FeedbackStage.notValid,
          reason: 'attempt $attempt',
        );
      }
    });

    test('only valid feedback opens the next unit (R-83)', () {
      for (final stage in FeedbackStage.values) {
        expect(
          stage.opensNextUnit,
          stage == FeedbackStage.valid,
          reason: '$stage',
        );
      }
    });
  });

  group('latest submission for an assignment', () {
    test('picks the newest attempt of that assignment only', () {
      final rows = [
        _row(attempt: 1, result: 'Failed'),
        _row(attempt: 2),
        SubmissionInfo(
          id: 'OTHER',
          assignmentId: 'AS-2',
          status: 'Completed',
          attemptNumber: 5,
        ),
      ];
      final latest = latestFor('AS-1', rows);
      expect(latest?.attemptNumber, 2);
      expect(latest?.assignmentId, 'AS-1');
    });

    test('none for that assignment: null', () {
      expect(latestFor('AS-9', [_row()]), isNull);
      expect(latestFor('AS-1', const []), isNull);
    });
  });
}
