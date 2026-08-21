class CourseIndexEntryModel {
  const CourseIndexEntryModel({
    required this.id,
    required this.name,
    required this.level,
    required this.vertical,
    required this.kitLess,
    required this.unitsCount,
  });

  final String id;
  final String name;
  final String level;
  final String vertical;
  final bool kitLess;
  final int unitsCount;

  factory CourseIndexEntryModel.fromJson(Map<String, dynamic> json) =>
      CourseIndexEntryModel(
        id: json['id'] as String? ?? '',
        name: json['nm'] as String? ?? '',
        level: json['lvl'] as String? ?? '',
        vertical: json['vrt'] as String? ?? '',
        kitLess: json['kit_less'] as bool? ?? false,
        unitsCount: (json['units_count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nm': name,
    'lvl': level,
    'vrt': vertical,
    'kit_less': kitLess,
    'units_count': unitsCount,
  };

  static List<CourseIndexEntryModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => CourseIndexEntryModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(
    List<CourseIndexEntryModel> list,
  ) => list.map((c) => c.toJson()).toList(growable: false);
}
