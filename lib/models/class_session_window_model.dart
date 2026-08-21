class ClassSessionWindowModel {
  const ClassSessionWindowModel({
    required this.learnerId,
    required this.completedUnitKeysThisWindow,
    this.windowResetsOn,
    this.windowStartDate,
  });

  final String learnerId;
  final List<String> completedUnitKeysThisWindow;
  final String? windowResetsOn;
  final String? windowStartDate;

  factory ClassSessionWindowModel.fromJson(Map<String, dynamic> json) =>
      ClassSessionWindowModel(
        learnerId: json['learner_id'] as String? ?? '',
        completedUnitKeysThisWindow:
            (json['completed_unit_keys'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        windowResetsOn: json['window_resets_on'] as String?,
        windowStartDate: json['window_start_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'learner_id': learnerId,
    'completed_unit_keys': completedUnitKeysThisWindow,
    'window_resets_on': windowResetsOn,
    'window_start_date': windowStartDate,
  };

  bool coversWindow(String? currentWindowStartDate) {
    if (windowStartDate == null || currentWindowStartDate == null) return false;
    return windowStartDate == currentWindowStartDate;
  }

  ClassSessionWindowModel withUnitCompleted(
    String unitKey, {
    String? windowResetsOn,
    String? windowStartDate,
  }) => ClassSessionWindowModel(
    learnerId: learnerId,
    completedUnitKeysThisWindow: [
      ...completedUnitKeysThisWindow,
      if (!completedUnitKeysThisWindow.contains(unitKey)) unitKey,
    ],
    windowResetsOn: windowResetsOn ?? this.windowResetsOn,
    windowStartDate: windowStartDate ?? this.windowStartDate,
  );

  static ClassSessionWindowModel empty(String learnerId) =>
      ClassSessionWindowModel(
        learnerId: learnerId,
        completedUnitKeysThisWindow: const [],
      );
}
