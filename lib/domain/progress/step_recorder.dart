import '../../core/network/api_exception.dart';
import 'idempotency_key.dart';
import 'progress_repository.dart';

/// What the Worker said about one recorded step.
class StepRecord {
  const StepRecord({
    required this.pointsAwarded,
    required this.pointsTotal,
    required this.alreadyRecorded,
  });

  /// The points the Worker gave for this step. The app shows this number and
  /// never works it out itself (R-41).
  final int pointsAwarded;

  /// The student's new total, when the Worker said it.
  final int? pointsTotal;

  /// The Worker had recorded this step before (a repeat key, or `CONFLICT`).
  final bool alreadyRecorded;
}

/// Records the steps of one unit on the Worker, one call for each step (the
/// video, then the quiz).
///
/// It keeps one idempotency key for each step until the step works, so a retry
/// after a network failure sends the SAME key and cannot give points twice. A
/// step that worked is remembered, so asking again makes no call.
class StepRecorder {
  StepRecorder(this._progress, {required this.studentId});

  final ProgressRepository _progress;
  final String studentId;

  final Map<String, String> _keys = {};
  final Map<String, StepRecord> _done = {};

  Future<StepRecord> recordVideo({
    required String unitId,
    required String videoId,
  }) => _record(
    step: 'video:$unitId:$videoId',
    keyKind: 'video',
    keyTarget: videoId,
    send: (key) => _progress.submitVideo(
      unitId: unitId,
      videoId: videoId,
      watched: true,
      idempotencyKey: key,
    ),
  );

  /// Sends the answers of the unit quiz once. Only the first scored attempt is
  /// sent (decided 2026-11-13): a retake is checked on the phone and never
  /// sent, so asking again returns the first result and makes no call.
  Future<StepRecord> recordQuiz({
    required String unitId,
    required String quizId,
    required List<QuizAnswer> answers,
  }) => _record(
    step: 'quiz:$unitId:$quizId',
    keyKind: 'quiz',
    keyTarget: quizId,
    send: (key) => _progress.submitQuiz(
      unitId: unitId,
      quizId: quizId,
      answers: answers,
      idempotencyKey: key,
    ),
  );

  Future<StepRecord> _record({
    required String step,
    required String keyKind,
    required String keyTarget,
    required Future<ProgressResult> Function(String key) send,
  }) async {
    final done = _done[step];
    if (done != null) return done;

    final key = _keys.putIfAbsent(
      step,
      () => newIdempotencyKey(keyKind, studentId, keyTarget),
    );
    try {
      final result = await send(key);
      return _done[step] = StepRecord(
        pointsAwarded: result.pointsAwarded,
        pointsTotal: result.pointsTotal,
        alreadyRecorded: result.isRepeat,
      );
    } on ApiException catch (e) {
      // Recorded before (a cap was reached). The contract says: go on.
      if (e.code == 'CONFLICT') {
        return _done[step] = const StepRecord(
          pointsAwarded: 0,
          pointsTotal: null,
          alreadyRecorded: true,
        );
      }
      rethrow;
    }
  }
}
