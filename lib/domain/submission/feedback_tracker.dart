import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../progress/progress_models.dart';
import 'feedback_state.dart';
import 'submission_repository.dart';

/// The state of the work and, when the Worker answered, the submission itself
/// (for the Results chat).
class FeedbackCheck {
  const FeedbackCheck(this.stage, [this.submission]);

  final FeedbackStage stage;
  final SubmissionInfo? submission;
}

/// Asks the Worker where a student's work stands, and keeps the last known
/// answer on the phone. The Worker is the truth (contract section 7). The saved
/// copy is only used when the Worker cannot be reached.
class FeedbackTracker {
  FeedbackTracker(this._repo, this._cache);

  final SubmissionRepository _repo;
  final LocalCache _cache;

  /// Asks the Worker. If that fails, the saved state. If there is none, null:
  /// we do not know, which is not the same as "not sent".
  Future<FeedbackCheck?> check(
    String learnerId,
    String assignmentId, {
    DateTime? now,
  }) async {
    try {
      final latest = await _repo.latest(assignmentId);
      final stage = feedbackStage(latest, now: now);
      await _save(learnerId, assignmentId, stage, latest?.createdAt);
      return FeedbackCheck(stage, latest);
    } catch (_) {
      final saved = cached(learnerId, assignmentId, now: now);
      return saved == null ? null : FeedbackCheck(saved.stage);
    }
  }

  /// The work was just sent: it is waiting for feedback, even before the
  /// Worker's list shows it.
  Future<void> markSent(
    String learnerId,
    String assignmentId, {
    DateTime? now,
  }) => _save(
    learnerId,
    assignmentId,
    FeedbackStage.waiting,
    now ?? DateTime.now(),
  );

  FeedbackCheck? cached(
    String learnerId,
    String assignmentId, {
    DateTime? now,
  }) {
    final raw = _cache.getForeverRaw(
      CacheKeys.feedback(learnerId, assignmentId),
    );
    if (raw == null) return null;
    final name = raw['stage'] as String?;
    final stage = FeedbackStage.values.where((s) => s.name == name).firstOrNull;
    if (stage == null) return null;

    // A waiting state turns slow with time, also while the phone is offline.
    final sent = DateTime.tryParse((raw['sent_at'] as String?) ?? '');
    if (stage == FeedbackStage.waiting && sent != null) {
      final late = (now ?? DateTime.now()).difference(sent) > slowFeedbackAfter;
      if (late) return const FeedbackCheck(FeedbackStage.slow);
    }
    return FeedbackCheck(stage);
  }

  Future<void> _save(
    String learnerId,
    String assignmentId,
    FeedbackStage stage,
    DateTime? sentAt,
  ) => _cache.setForeverRaw(CacheKeys.feedback(learnerId, assignmentId), {
    'stage': stage.name,
    'sent_at': sentAt?.toUtc().toIso8601String(),
  });
}
