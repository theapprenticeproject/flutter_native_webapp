class ActiveProfileModel {
  const ActiveProfileModel({
    required this.phone,
    required this.learnerId,
    required this.studentName,
    this.grade,
    this.division,
    this.avatar,
    this.onboardingCompleted = false,
  });

  final String phone;
  final String learnerId;
  final String? studentName;
  final String? grade;
  final String? division;
  final String? avatar;
  final bool onboardingCompleted;

  factory ActiveProfileModel.fromJson(Map<String, dynamic> json) =>
      ActiveProfileModel(
        phone: json['phone'] as String,
        learnerId: json['learner_id'] as String,
        studentName: json['student_name'] as String?,
        grade: json['grade'] as String?,
        division: json['division'] as String?,
        avatar: json['avatar'] as String?,
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'learner_id': learnerId,
    'student_name': studentName,
    'grade': grade,
    'division': division,
    'avatar': avatar,
    'onboarding_completed': onboardingCompleted,
  };

  ActiveProfileModel copyWith({
    String? studentName,
    String? grade,
    String? division,
    String? avatar,
    bool? onboardingCompleted,
  }) => ActiveProfileModel(
    phone: phone,
    learnerId: learnerId,
    studentName: studentName ?? this.studentName,
    grade: grade ?? this.grade,
    division: division ?? this.division,
    avatar: avatar ?? this.avatar,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
}
