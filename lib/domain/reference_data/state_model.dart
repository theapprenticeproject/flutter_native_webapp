class StateModel {
  const StateModel({
    required this.id,
    required this.name,
    required this.country,
  });

  final String id;
  final String name;
  final String country;

  factory StateModel.fromJson(Map<String, dynamic> json) => StateModel(
    id: json['id'] as String,
    name: json['name'] as String,
    country: json['country'] as String? ?? 'India',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'country': country};

  static List<StateModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => StateModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(List<StateModel> list) =>
      list.map((s) => s.toJson()).toList(growable: false);

  static String assetFileNameFor(String stateId) =>
      stateId.replaceAll(' ', '-');
}

class DistrictModel {
  const DistrictModel({required this.id, required this.name});

  final String id;
  final String name;

  factory DistrictModel.fromJson(Map<String, dynamic> json) =>
      DistrictModel(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static List<DistrictModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => DistrictModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(List<DistrictModel> list) =>
      list.map((d) => d.toJson()).toList(growable: false);
}

class OnboardingConstantsModel {
  const OnboardingConstantsModel({
    required this.flowCategories,
    required this.maxOtpRetries,
    required this.appVersion,
    required this.defaultLanguageCode,
  });

  final List<String> flowCategories;
  final int maxOtpRetries;
  final String appVersion;
  final String defaultLanguageCode;

  factory OnboardingConstantsModel.fromJson(Map<String, dynamic> json) =>
      OnboardingConstantsModel(
        flowCategories:
            (json['flow_categories'] as List?)?.whereType<String>().toList() ??
            const [],
        maxOtpRetries: (json['max_otp_retries'] as num?)?.toInt() ?? 5,
        appVersion: json['app_version'] as String? ?? '1.0.0',
        defaultLanguageCode: json['default_language_code'] as String? ?? 'en',
      );

  Map<String, dynamic> toJson() => {
    'flow_categories': flowCategories,
    'max_otp_retries': maxOtpRetries,
    'app_version': appVersion,
    'default_language_code': defaultLanguageCode,
  };
}

class OnboardingLanguageModel {
  const OnboardingLanguageModel({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });

  final String code;
  final String label;
  final String nativeLabel;

  factory OnboardingLanguageModel.fromJson(Map<String, dynamic> json) =>
      OnboardingLanguageModel(
        code: json['code'] as String,
        label: json['label'] as String,
        nativeLabel: json['native_label'] as String? ?? json['label'] as String,
      );

  Map<String, dynamic> toJson() => {
    'code': code,
    'label': label,
    'native_label': nativeLabel,
  };

  static List<OnboardingLanguageModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => OnboardingLanguageModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(
    List<OnboardingLanguageModel> list,
  ) => list.map((l) => l.toJson()).toList(growable: false);
}
