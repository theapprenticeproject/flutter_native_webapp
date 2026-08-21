class CacheKeys {
  CacheKeys._();

  static const String schemaVersion = 'v2';

  static String _k(String parts) => '$schemaVersion:$parts';

  static String flow(String lang, String category, String fileName) =>
      _k('flow:$lang:$category:$fileName');

  static String flowManifest(String lang) => _k('flow:manifest:$lang');

  static String authSession(String phone) => _k('auth:$phone:session');

  static String activeProfile() => _k('active_profile');

  static String profilesPage(String phone, int page, int pageSize) =>
      _k('profiles:$phone:page$page:$pageSize');

  static String profilesSearch(
    String phone, {
    String? grade,
    String? division,
    String? rollNumber,
    String? query,
    int page = 1,
  }) => _k(
    'profiles:$phone:search:${grade ?? '*'}:${division ?? '*'}:${rollNumber ?? '*'}:${query ?? '*'}:$page',
  );

  static String profilesIndex(String phone) => _k('profiles:$phone:index');

  static String learnerState(String learnerId) =>
      _k('learner:$learnerId:state');

  static String onboardingCompleted(String learnerId) =>
      _k('learner:$learnerId:onboarding_completed');

  static String roster(
    String phone, {
    String? grade,
    String? division,
    String? query,
  }) => _k('roster:$phone:${grade ?? '*'}:${division ?? '*'}:${query ?? '*'}');

  static String rosterIndex(String phone) => _k('roster:$phone:index');

  static String students(
    String phone, {
    String? grade,
    String? division,
    int page = 1,
  }) => _k('students:$phone:${grade ?? '*'}:${division ?? '*'}:$page');

  static String studentSearch(
    String phone,
    String grade,
    String rollNumber,
    String division,
  ) => _k('students:$phone:search:$grade:$rollNumber:$division');

  static String achievements(String learnerId) => _k('achievements:$learnerId');

  static String submissionReview(
    String learnerId,
    String question,
    String submissionText,
  ) => _k('review:$learnerId:${Object.hash(question, submissionText)}');

  static String chatTranscript(String phone, String learnerId) =>
      _k('chat:$phone:$learnerId');

  static String languageSetting() => _k('settings:language_code');

  static String activityProgress(String learnerId) =>
      _k('activity:$learnerId:progress');

  static String homeCelebration(String learnerId) =>
      _k('activity:$learnerId:home_celebration');

  static String weeklyWatchWindow(String learnerId) =>
      _k('activity:$learnerId:weekly_window');

  static String sessionWindow(String learnerId) =>
      _k('class_session:$learnerId:window');

  static bool belongsToPhone(String key, String phone) =>
      key.contains(':$phone:');

  static bool isRosterKey(String key) => key.startsWith(_k('roster:'));

  static bool isProfilesKey(String key) => key.startsWith(_k('profiles:'));
}
