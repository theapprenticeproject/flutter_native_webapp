class ApiEndpoints {
  ApiEndpoints._();

  static const String checkPhone = '/auth/check-phone';
  static const String login = '/auth/login';
  static const String forgotPasswordSendOtp = '/auth/forgot-password/send-otp';
  static const String forgotPasswordVerifyOtp =
      '/auth/forgot-password/verify-otp';
  static const String resetPassword = '/auth/reset-password';

  static const String profiles = '/profiles';
  static const String profilesSearch = '/profiles/search';
  static const String profilesSelect = '/profiles/select';
  static const String profilesAvatar = '/profiles/avatar';
  static const String profilesUpdate = '/profiles/update';

  static const String studentsSearch = '/students/search';
  static const String students = '/students';
  static const String studentsUpdate = '/students/update';
  static const String studentsBulkUpdate = '/students/bulk-update';

  static const String learnerState = '/learner/state';
  static const String learnerEnroll = '/learner/enroll';
  static const String learnerSubmitProgress = '/learner/submit-progress';

  static const String achievements = '/achievements';
  static const String achievementsAward = '/achievements/award';

  static const String tapbuddyChat = '/tapbuddy/chat';
  static const String submissionReview = '/submission-review/review';

  static const String onboardingComplete = '/onboarding/complete';
}
