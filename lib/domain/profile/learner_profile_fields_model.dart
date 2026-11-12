class LearnerProfileFieldsModel {
  const LearnerProfileFieldsModel({
    this.studentName,
    this.language,
    this.district,
    this.state,
    this.schoolId,
    this.schoolName,
    this.birthdate,
  });

  final String? studentName;
  final String? language;
  final String? district;
  final String? state;
  final String? schoolId;
  final String? schoolName;
  final String? birthdate;

  factory LearnerProfileFieldsModel.fromJson(Map<String, dynamic> json) =>
      LearnerProfileFieldsModel(
        studentName: json['student_name'] as String?,
        language: json['language'] as String?,
        district: json['district'] as String?,
        state: json['state'] as String?,
        schoolId: json['school_id'] as String?,
        schoolName: json['school_name'] as String?,
        birthdate: json['birthdate'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'student_name': studentName,
    'language': language,
    'district': district,
    'state': state,
    'school_id': schoolId,
    'school_name': schoolName,
    'birthdate': birthdate,
  };
}
