class ArchetypeConstants {
  ArchetypeConstants._();

  static const String dormant = 'dormant';
  static const String fenceSitter = 'fence_sitter';
  static const String irregularSubmitter = 'irregular_submitter';
  static const String submitter = 'submitter';
}

class LocalArchetypeCalculator {
  LocalArchetypeCalculator._();

  static String compute({
    required int streak,
    required int submissionCount,
    required String? lastActivityDate,
    required DateTime now,
  }) {
    final daysSinceLastActivity = _daysSince(lastActivityDate, now);
    if (daysSinceLastActivity == null || daysSinceLastActivity > 21) {
      return ArchetypeConstants.dormant;
    }
    if (submissionCount <= 0) {
      return ArchetypeConstants.fenceSitter;
    }
    if (streak < 2) {
      return ArchetypeConstants.irregularSubmitter;
    }
    return ArchetypeConstants.submitter;
  }

  static int? _daysSince(String? isoDate, DateTime now) {
    if (isoDate == null) return null;
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return null;
    return now.difference(parsed).inDays;
  }
}
