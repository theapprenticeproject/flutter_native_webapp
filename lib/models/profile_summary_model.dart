class ProfileSummaryModel {
  const ProfileSummaryModel({
    required this.learnerId,
    required this.ownerPhone,
    required this.studentName,
    this.rollNumber,
    this.grade,
    this.division,
    this.avatar,
    this.onboardingCompleted = false,
  });

  final String learnerId;
  final String ownerPhone;
  final String studentName;
  final int? rollNumber;
  final String? grade;
  final String? division;
  final String? avatar;
  final bool onboardingCompleted;

  static int? _parseRollNumber(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  factory ProfileSummaryModel.fromJson(
    String ownerPhone,
    Map<String, dynamic> json,
  ) => ProfileSummaryModel(
    learnerId: json['learner_id'] as String,
    ownerPhone: ownerPhone,
    studentName: json['student_name'] as String? ?? '',
    rollNumber: _parseRollNumber(json['roll_number']),
    grade: json['grade']?.toString(),
    division: json['division'] as String?,
    avatar: json['avatar']?.toString(),
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'learner_id': learnerId,
    'owner_phone': ownerPhone,
    'student_name': studentName,
    'roll_number': rollNumber,
    'grade': grade,
    'division': division,
    'avatar': avatar,
    'onboarding_completed': onboardingCompleted,
  };

  ProfileSummaryModel copyWith({
    String? studentName,
    int? rollNumber,
    String? grade,
    String? division,
    String? avatar,
    bool? onboardingCompleted,
  }) => ProfileSummaryModel(
    learnerId: learnerId,
    ownerPhone: ownerPhone,
    studentName: studentName ?? this.studentName,
    rollNumber: rollNumber ?? this.rollNumber,
    grade: grade ?? this.grade,
    division: division ?? this.division,
    avatar: avatar ?? this.avatar,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  static List<ProfileSummaryModel> listFromJson(
    String ownerPhone,
    dynamic raw,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => ProfileSummaryModel.fromJson(
            ownerPhone,
            Map<String, dynamic>.from(m),
          ),
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(
    List<ProfileSummaryModel> list,
  ) => list.map((p) => p.toJson()).toList(growable: false);

  static List<ProfileSummaryModel> listFromCache(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) {
          final json = Map<String, dynamic>.from(m);
          return ProfileSummaryModel.fromJson(
            json['owner_phone'] as String,
            json,
          );
        })
        .toList(growable: false);
  }
}
