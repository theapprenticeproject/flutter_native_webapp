import '../progress/progress_models.dart';

/// How long the student waits before we say "taking longer than expected".
/// Feedback is released at 15:00, 16:30 and 21:00 IST, so the longest normal
/// wait is about 17 hours. The product team decides the final time (A13).
const slowFeedbackAfter = Duration(hours: 24);

/// Where the student's work stands (R-68, R-76, R-83).
enum FeedbackStage {
  /// No submission yet (never sent, or postponed).
  notSent,

  /// Sent, and no feedback yet: "I'm looking at your work, please wait".
  waiting,

  /// Still no feedback after [slowFeedbackAfter].
  slow,

  /// Valid feedback: the Results step opens and so can the next unit.
  valid,

  /// Not valid, and the student can send again.
  notValid,

  /// Not valid, and both attempts are used: the student cannot go on (R-76).
  notValidNoRetry;

  /// The next unit opens only after valid feedback (R-83).
  bool get opensNextUnit => this == FeedbackStage.valid;
}

/// The stage for the newest submission of an assignment. A work is valid only
/// when [SubmissionInfo.isValid] (API contract, section 4). `now` is a
/// parameter so a test can set the time.
FeedbackStage feedbackStage(
  SubmissionInfo? latest, {
  DateTime? now,
  Duration slowAfter = slowFeedbackAfter,
}) {
  if (latest == null) return FeedbackStage.notSent;
  if (latest.isPending) {
    final sent = latest.createdAt;
    final late =
        sent != null && (now ?? DateTime.now()).difference(sent) > slowAfter;
    return late ? FeedbackStage.slow : FeedbackStage.waiting;
  }
  if (latest.isValid) return FeedbackStage.valid;
  return latest.canSendAgain
      ? FeedbackStage.notValid
      : FeedbackStage.notValidNoRetry;
}

/// The newest attempt for [assignmentId] among [rows], or null.
SubmissionInfo? latestFor(String assignmentId, List<SubmissionInfo> rows) {
  SubmissionInfo? latest;
  for (final row in rows) {
    if (row.assignmentId != assignmentId) continue;
    if (latest == null ||
        (row.attemptNumber ?? 0) > (latest.attemptNumber ?? 0)) {
      latest = row;
    }
  }
  return latest;
}
