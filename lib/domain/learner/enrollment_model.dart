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
