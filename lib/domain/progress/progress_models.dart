// Answers of the v1 Worker's progress routes. Only the fields v1 uses are read.

int? _int(Object? v) => (v as num?)?.toInt();

/// The answer of `submit_video` and `submit_quiz`.
class ProgressResult {
  const ProgressResult({
    required this.pointsAwarded,
    required this.pointsTotal,
    required this.pointsTier,
    required this.updatedAt,
    required this.isRepeat,
    this.correctCount,
    this.totalCount,
  });

  final int pointsAwarded;
  final int pointsTotal;
  final String? pointsTier;
  final int? updatedAt;

  /// The Worker already had this idempotency key, so it gave no new points.
  final bool isRepeat;

  /// Quiz only.
  final int? correctCount;
  final int? totalCount;

  factory ProgressResult.fromJson(Map<String, dynamic> json) => ProgressResult(
    pointsAwarded: _int(json['points_awarded']) ?? 0,
    pointsTotal: _int(json['points_total']) ?? 0,
    pointsTier: json['points_tier'] as String?,
    updatedAt: _int(json['updated_at']),
    isRepeat: json['repeat'] == true,
    correctCount: _int(json['correct_count']),
    totalCount: _int(json['total_count']),
  );
}

/// A submission as `sync`, `last_submission` and `submission/list` return it.
///
/// The Worker spells the status "Pending" and "Completed" today, and the API
/// doc once used lower case. Both are read the same way.
class SubmissionInfo {
  const SubmissionInfo({
    required this.id,
    this.assignmentId,
    required this.status,
    this.resultStatus,
    this.viewUrl,
    this.score,
    this.feedback,
    this.feedbackAudioUrl,
    this.attemptNumber,
    this.attemptsRemaining,
    this.updatedAt,
    this.createdAt,
  });

  final String id;
  final String? assignmentId;
  final String status;
  final String? resultStatus;
  final String? viewUrl;
  final int? score;
  final String? feedback;
  final String? feedbackAudioUrl;
  final int? attemptNumber;
  final int? attemptsRemaining;
  final int? updatedAt;

  /// When the work was sent.
  final DateTime? createdAt;

  String get _status => status.toLowerCase();

  bool get isPending => _status == 'pending' || _status == 'processing';
  bool get isGraded => _status == 'completed';

  /// The work counts (API contract section 4): `Success - Original` and a score
  /// above 0. Flagged, failed, pending, a score of 0 (the AI could not judge)
  /// and any value we do not know are not valid.
  bool get isValid =>
      (resultStatus ?? '').toLowerCase() == 'success - original' &&
      (score ?? 0) > 0;

  /// The student may send another photo or video (2 attempts in all).
  bool get canSendAgain => (attemptsRemaining ?? 0) > 0;

  factory SubmissionInfo.fromJson(Map<String, dynamic> json) => SubmissionInfo(
    // shortcut: the test Worker still says "name". Use only submission_id once
    // it is fixed.
    id: ((json['submission_id'] ?? json['name']) as String?) ?? '',
    assignmentId: json['assignment_id_link'] as String?,
    status: (json['status'] as String?) ?? '',
    resultStatus: json['result_status'] as String?,
    viewUrl: json['view_url'] as String?,
    score: _int(json['score']),
    feedback: json['overall_feedback_translated'] as String?,
    feedbackAudioUrl: json['overall_feedback_audio_url'] as String?,
    attemptNumber: _int(json['attempt_number']),
    attemptsRemaining: _int(json['attempts_remaining']),
    updatedAt: _int(json['updated_at']),
    createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
  );
}

/// The answer of `/progress/sync`: has anything changed since [updatedAt]?
class SyncResult {
  const SyncResult({
    required this.changed,
    required this.updatedAt,
    this.points,
    this.pointsTier,
    this.currentLearningUnit,
    this.lastActivityType,
    this.lastSubmission,
  });

  final bool changed;
  final int? updatedAt;
  final int? points;
  final String? pointsTier;
  final String? currentLearningUnit;
  final String? lastActivityType;

  /// Present only when the newest submission is graded and newer than asked.
  final SubmissionInfo? lastSubmission;

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
    changed: json['changed'] == true,
    updatedAt: _int(json['updated_at']),
    points: _int(json['points']),
    pointsTier: json['points_tier'] as String?,
    currentLearningUnit: json['current_learning_unit'] as String?,
    lastActivityType: json['last_activity_type'] as String?,
    lastSubmission: json['last_submission'] is Map
        ? SubmissionInfo.fromJson(
            Map<String, dynamic>.from(json['last_submission'] as Map),
          )
        : null,
  );
}

/// The answer of `/profile/get_profile`. (The Worker names the field `name1`.)
class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.name,
    required this.grade,
    this.language,
    this.courseId,
  });

  final String studentId;
  final String name;
  final String grade;
  final String? language;
  final String? courseId;

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    studentId: (json['student_id'] as String?) ?? '',
    name: (json['name1'] as String?) ?? (json['name'] as String?) ?? '',
    grade: (json['grade'] ?? '').toString(),
    language: json['language'] as String?,
    courseId: json['course_id'] as String?,
  );
}

/// The answer of `/app/config`: the rules the Worker owns, so the app does not
/// hardcode them (R-41).
class AppConfig {
  const AppConfig({
    required this.uploadMaxBytesImage,
    required this.uploadMaxBytesVideo,
    required this.pointTiers,
    this.rules = const PointRules(),
  });

  final int uploadMaxBytesImage;

  /// The points of each step (R-41: they are the server's settings).
  final PointRules rules;
  final int uploadMaxBytesVideo;

  /// `(id, min)` sorted by `min`.
  final List<({String id, int min})> pointTiers;

  /// The tier for [points]: the highest tier whose minimum is reached.
  String? tierFor(int points) {
    String? tier;
    for (final t in pointTiers) {
      if (points >= t.min) tier = t.id;
    }
    return tier;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final tiers =
        // shortcut: the test Worker says `tiers`, the contract says
        // `point_tiers`. Read only the contract name once the Worker follows it.
        ((json['point_tiers'] ?? json['tiers']) as List? ?? const [])
            .whereType<Map>()
            .map((t) => (id: t['id'] as String, min: _int(t['min']) ?? 0))
            .toList()
          ..sort((a, b) => a.min.compareTo(b.min));
    return AppConfig(
      uploadMaxBytesImage: _int(json['upload_max_bytes_image']) ?? 0,
      uploadMaxBytesVideo: _int(json['upload_max_bytes_video']) ?? 0,
      pointTiers: tiers,
      rules: PointRules.fromJson(json),
    );
  }
}

/// How many points each step is worth, from `/app/config`. They are settings on
/// the server and can change, so the app does not keep them in code (R-41).
class PointRules {
  const PointRules({
    this.video = 0,
    this.quizPerCorrect = 0,
    this.submissionFirstAttempt = 0,
    this.reviewValid = 0,
  });

  /// The video marked as watched.
  final int video;

  /// Each correct quiz answer.
  final int quizPerCorrect;

  /// The work sent, first attempt (the second attempt gives none).
  final int submissionFirstAttempt;

  /// The work was graded valid.
  final int reviewValid;

  /// The server sent at least one rule. An older config has none.
  bool get known =>
      video > 0 ||
      quizPerCorrect > 0 ||
      submissionFirstAttempt > 0 ||
      reviewValid > 0;

  /// What a whole activity can earn: the video, the work (first attempt), a valid
  /// review and every quiz question right. Null when the rules are not known.
  int? activityPoints({required int quizQuestions}) => known
      ? video +
            submissionFirstAttempt +
            reviewValid +
            quizPerCorrect * quizQuestions
      : null;

  factory PointRules.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> part(String key) =>
        (json[key] as Map?)?.cast<String, dynamic>() ?? const {};
    return PointRules(
      video: _int(part('video')['points_complete']) ?? 0,
      quizPerCorrect: _int(part('quiz')['points_per_correct_answer']) ?? 0,
      submissionFirstAttempt:
          _int(part('submission')['points_first_attempt']) ?? 0,
      reviewValid: _int(part('submission')['points_review_valid']) ?? 0,
    );
  }
}
