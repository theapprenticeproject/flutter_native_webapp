class AchievementModel {
  const AchievementModel({required this.achievement, required this.level});

  final String achievement;
  final String level;

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        achievement: json['achievement']?.toString() ?? '',
        level: json['level']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'achievement': achievement, 'level': level};

  static List<AchievementModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => AchievementModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(List<AchievementModel> list) =>
      list.map((a) => a.toJson()).toList(growable: false);
}
