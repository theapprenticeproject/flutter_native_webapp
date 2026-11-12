class AuthSessionModel {
  const AuthSessionModel({required this.phone, this.teacher, this.adminCode});

  final String phone;
  final String? teacher;
  final String? adminCode;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      AuthSessionModel(
        phone: json['phone'] as String,
        teacher: json['teacher'] as String?,
        adminCode: json['admin_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'teacher': teacher,
    'admin_code': adminCode,
  };
}
