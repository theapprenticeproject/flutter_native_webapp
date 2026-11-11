/// A student on the phone, as `/auth/redeem` and `/auth/select_profile` return
/// it. The student's token is kept in secure storage, never in this model.
/// Only the fields v1 uses are read.
class RedeemedStudent {
  const RedeemedStudent({
    required this.studentId,
    required this.name,
    required this.grade,
    this.points = 0,
    this.pointsTier,
    this.currentLearningUnit,
    this.courseId,
    this.language,
  });

  final String studentId;
  final String name;
  final String grade;
  final int points;
  final String? pointsTier;
  final String? currentLearningUnit;
  final String? courseId;
  final String? language;

  factory RedeemedStudent.fromJson(Map<String, dynamic> json) =>
      RedeemedStudent(
        studentId: json['student_id'] as String,
        name: (json['name'] as String?) ?? '',
        grade: (json['grade'] ?? '').toString(),
        points: (json['points'] as num?)?.toInt() ?? 0,
        pointsTier: json['points_tier'] as String?,
        currentLearningUnit: json['current_learning_unit'] as String?,
        courseId: json['course_id'] as String?,
        language: json['language'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'name': name,
    'grade': grade,
    'points': points,
    'points_tier': pointsTier,
    'current_learning_unit': currentLearningUnit,
    'course_id': courseId,
    'language': language,
  };
}

/// What opening a magic link gives back.
class RedeemResult {
  const RedeemResult({required this.students, required this.activeStudent});

  final List<RedeemedStudent> students;

  /// The first student on the phone. Used straight away when there is only one.
  final RedeemedStudent activeStudent;

  /// More than one child on the phone: the student picks their name first.
  bool get needsPicker => students.length > 1;
}
