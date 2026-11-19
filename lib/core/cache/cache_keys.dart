class CacheKeys {
  CacheKeys._();

  static const String schemaVersion = 'v2';

  static String _k(String parts) => '$schemaVersion:$parts';

  /// Saved copies of files that are bundled in the app (the course list, the
  /// course files, the chat flow). They are dropped when the build changes
  /// (`LocalCache.dropContentFromOtherBuilds`). The program content keys are
  /// built in `ProgramContentCache`; a test checks the prefixes still match.
  static const List<String> bundledContentPrefixes = [
    '$schemaVersion:program_content:',
    '$schemaVersion:flow:',
  ];

  static String flow(String lang, String category, String fileName) =>
      _k('flow:$lang:$category:$fileName');

  static String flowManifest(String lang) => _k('flow:manifest:$lang');

  static String activeProfile() => _k('active_profile');

  /// The last known state of a student's work for one assignment (R-83).
  static String feedback(String learnerId, String assignmentId) =>
      _k('feedback:$learnerId:$assignmentId');

  /// The students on the phone, saved when the magic link is opened.
  static String linkRoster() => _k('link_roster');

  static String learnerState(String learnerId) =>
      _k('learner:$learnerId:state');

  static String achievements(String learnerId) => _k('achievements:$learnerId');

  static String languageSetting() => _k('settings:language_code');

  static String activityProgress(String learnerId) =>
      _k('activity:$learnerId:progress');

  static String homeCelebration(String learnerId) =>
      _k('activity:$learnerId:home_celebration');
}
