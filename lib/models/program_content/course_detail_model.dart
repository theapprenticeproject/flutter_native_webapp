class CourseQuizQuestionModel {
  const CourseQuizQuestionModel({
    required this.question,
    required this.options,
    required this.answerKey,
    this.explanation,
  });

  final String question;
  final Map<String, String> options;
  final String answerKey;
  final String? explanation;

  factory CourseQuizQuestionModel.fromJson(Map<String, dynamic> json) =>
      CourseQuizQuestionModel(
        question: json['q'] as String? ?? '',
        options: json['opts'] is Map
            ? Map<String, String>.from(
                (json['opts'] as Map).map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : const {},
        answerKey: json['ans']?.toString() ?? '',
        explanation: json['exp'] as String?,
      );

  static List<CourseQuizQuestionModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => CourseQuizQuestionModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList(growable: false);
  }
}

class CourseQuizModel {
  const CourseQuizModel({
    required this.id,
    required this.name,
    required this.questions,
  });

  final int id;
  final String name;
  final List<CourseQuizQuestionModel> questions;

  factory CourseQuizModel.fromJson(Map<String, dynamic> json) =>
      CourseQuizModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['nm'] as String? ?? '',
        questions: CourseQuizQuestionModel.listFromJson(json['qs']),
      );
}

class CourseVideoModel {
  const CourseVideoModel({
    required this.id,
    required this.name,
    required this.description,
    required this.youtubeId,
    required this.points,
    this.postQuiz,
  });

  final int id;
  final String name;
  final String description;
  final String youtubeId;
  final int points;
  final CourseQuizModel? postQuiz;

  factory CourseVideoModel.fromJson(Map<String, dynamic> json) =>
      CourseVideoModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['nm'] as String? ?? '',
        description: json['desc'] as String? ?? '',
        youtubeId: json['yt'] as String? ?? '',
        points: (json['pts'] as num?)?.toInt() ?? 0,
        postQuiz: json['pq'] is Map
            ? CourseQuizModel.fromJson(
                Map<String, dynamic>.from(json['pq'] as Map),
              )
            : null,
      );

  static List<CourseVideoModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => CourseVideoModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }
}

class CourseAssignmentStepModel {
  const CourseAssignmentStepModel({
    required this.step,
    required this.label,
    required this.subTypes,
    this.guidedText,
    required this.unguidedText,
    this.validCriteria,
    this.invalidCriteria,
  });

  final int step;
  final String label;
  final String subTypes;
  final String? guidedText;
  final String unguidedText;
  final String? validCriteria;
  final String? invalidCriteria;

  factory CourseAssignmentStepModel.fromJson(Map<String, dynamic> json) =>
      CourseAssignmentStepModel(
        step: (json['step'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        subTypes: json['sub_types'] as String? ?? '',
        guidedText: json['guided_text'] as String?,
        unguidedText: json['unguided_text'] as String? ?? '',
        validCriteria: json['valid_criteria'] as String?,
        invalidCriteria: json['invalid_criteria'] as String?,
      );

  static List<CourseAssignmentStepModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) =>
              CourseAssignmentStepModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList(growable: false);
  }
}

class CourseAssignmentModel {
  const CourseAssignmentModel({
    required this.id,
    required this.sequence,
    required this.name,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.steps,
  });

  final String id;
  final int sequence;
  final String name;
  final String description;
  final String type;
  final String difficulty;
  final List<CourseAssignmentStepModel> steps;

  factory CourseAssignmentModel.fromJson(Map<String, dynamic> json) =>
      CourseAssignmentModel(
        id: json['id'] as String? ?? '',
        sequence: (json['seq'] as num?)?.toInt() ?? 0,
        name: json['nm'] as String? ?? '',
        description: json['desc'] as String? ?? '',
        type: json['type'] as String? ?? '',
        difficulty: json['diff'] as String? ?? '',
        steps: CourseAssignmentStepModel.listFromJson(json['steps']),
      );

  static List<CourseAssignmentModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => CourseAssignmentModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList(growable: false);
  }
}

class CourseUnitModel {
  const CourseUnitModel({
    required this.name,
    required this.description,
    required this.requiredComponents,
    required this.difficulty,
    required this.xp,
    required this.videos,
    this.quiz,
    required this.assignments,
  });

  final String name;
  final String description;
  final String requiredComponents;
  final String difficulty;
  final int xp;
  final List<CourseVideoModel> videos;
  final CourseQuizModel? quiz;
  final List<CourseAssignmentModel> assignments;

  factory CourseUnitModel.fromJson(Map<String, dynamic> json) =>
      CourseUnitModel(
        name: json['nm'] as String? ?? '',
        description: json['desc'] as String? ?? '',
        requiredComponents: json['rwc'] as String? ?? '',
        difficulty: json['diff'] as String? ?? '',
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        videos: CourseVideoModel.listFromJson(json['vids']),
        quiz: json['quiz'] is Map
            ? CourseQuizModel.fromJson(
                Map<String, dynamic>.from(json['quiz'] as Map),
              )
            : null,
        assignments: CourseAssignmentModel.listFromJson(json['assigns']),
      );

  static List<CourseUnitModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => CourseUnitModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }
}

class CourseDetailModel {
  const CourseDetailModel({
    required this.id,
    required this.name,
    required this.level,
    required this.vertical,
    required this.kitLess,
    required this.description,
    required this.units,
  });

  final String id;
  final String name;
  final String level;
  final String vertical;
  final bool kitLess;
  final String description;
  final List<CourseUnitModel> units;

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) =>
      CourseDetailModel(
        id: json['id'] as String? ?? '',
        name: json['nm'] as String? ?? '',
        level: json['lvl'] as String? ?? '',
        vertical: json['vrt'] as String? ?? '',
        kitLess: json['kit_less'] as bool? ?? false,
        description: json['desc'] as String? ?? '',
        units: CourseUnitModel.listFromJson(json['units']),
      );
}
