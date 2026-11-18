/// The student who is signed in on this phone.
///
/// shortcut: [phone] is always empty. The Worker does not send it and the
/// student token carries the identity (R-81). Remove it with the code that
/// still passes it around.
class ActiveProfileModel {
  const ActiveProfileModel({
    required this.phone,
    required this.learnerId,
    required this.studentName,
    this.grade,
  });

  final String phone;
  final String learnerId;
  final String? studentName;
  final String? grade;

  factory ActiveProfileModel.fromJson(Map<String, dynamic> json) =>
      ActiveProfileModel(
        phone: (json['phone'] as String?) ?? '',
        learnerId: json['learner_id'] as String,
        studentName: json['student_name'] as String?,
        grade: json['grade'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'learner_id': learnerId,
    'student_name': studentName,
    'grade': grade,
  };
}
