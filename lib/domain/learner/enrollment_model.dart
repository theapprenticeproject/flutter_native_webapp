class EnrollmentModel {
  const EnrollmentModel({
    this.course,
    this.status,
    this.videosCompleted = 0,
    this.quizzesCompleted = 0,
    this.submissionIndex = 0,
    this.enrolledOn,
  });

  final String? course;
  final String? status;
  final int videosCompleted;
  final int quizzesCompleted;
  final int submissionIndex;
  final String? enrolledOn;

  EnrollmentModel copyWith({
    String? course,
    String? status,
    int? videosCompleted,
    int? quizzesCompleted,
    int? submissionIndex,
    String? enrolledOn,
  }) => EnrollmentModel(
    course: course ?? this.course,
    status: status ?? this.status,
    videosCompleted: videosCompleted ?? this.videosCompleted,
    quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
    submissionIndex: submissionIndex ?? this.submissionIndex,
    enrolledOn: enrolledOn ?? this.enrolledOn,
  );

  /// The counters when the student is on unit [unitIndex] (the Worker's answer):
  /// earlier units are done, later ones are not. A count far ahead of the Worker
  /// (for example after a reset) goes back to it. The Worker closes a unit only
  /// after valid feedback (R-83), so a unit it still calls current is never
  /// finished by the phone: the submission step stays open.
  ///
  /// With [known] the Worker also said what the student did in this unit
  /// ([lastActivity], its `last_activity_type`: `video`, `quiz`, `submission` or
  /// null). Then the steps are exactly what the Worker has, whatever the phone
  /// says: any activity means the video is done, only `quiz` means the quiz is
  /// done (with `submission` the quiz is not known, so it stays open), and the
  /// work is never closed here.
  EnrollmentModel alignedToUnit(
    int unitIndex, {
    bool known = false,
    String? lastActivity,
  }) {
    if (known) {
      return copyWith(
        videosCompleted: unitIndex + (lastActivity != null ? 1 : 0),
        quizzesCompleted: unitIndex + (lastActivity == 'quiz' ? 1 : 0),
        submissionIndex: unitIndex,
      );
    }
    int fix(int n) => n < unitIndex || n > unitIndex + 1 ? unitIndex : n;
    final video = fix(videosCompleted);
    final quiz = fix(quizzesCompleted);
    var submission = fix(submissionIndex);
    if (video > unitIndex && quiz > unitIndex && submission > unitIndex) {
      submission = unitIndex;
    }
    return copyWith(
      videosCompleted: video,
      quizzesCompleted: quiz,
      submissionIndex: submission,
    );
  }

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentModel(
        course: json['course'] as String?,
        status: json['status'] as String?,
        videosCompleted: (json['videos_completed'] as num?)?.toInt() ?? 0,
        quizzesCompleted: (json['quizzes_completed'] as num?)?.toInt() ?? 0,
        submissionIndex: (json['submission_index'] as num?)?.toInt() ?? 0,
        enrolledOn: json['enrolled_on'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'course': course,
    'status': status,
    'videos_completed': videosCompleted,
    'quizzes_completed': quizzesCompleted,
    'submission_index': submissionIndex,
    'enrolled_on': enrolledOn,
  };
}
