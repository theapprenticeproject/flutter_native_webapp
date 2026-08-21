class AppLanguage {
  final String code;
  final String label;
  final String nativeLabel;

  const AppLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });
}

class AppConstants {
  static const String workerBaseUrl =
      'https://tapapp-worker.tapapp-middleware.workers.dev';

  static const String defaultLanguageCode = 'en';

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'en', label: 'English', nativeLabel: 'English'),
    AppLanguage(code: 'hi', label: 'Hindi', nativeLabel: 'हिन्दी'),
    AppLanguage(code: 'mr', label: 'Marathi', nativeLabel: 'मराठी'),
    AppLanguage(code: 'kn', label: 'Kannada', nativeLabel: 'ಕನ್ನಡ'),
    AppLanguage(code: 'pa', label: 'Punjabi', nativeLabel: 'ਪੰਜਾਬੀ'),
  ];

  static bool isSupportedLanguage(String code) =>
      supportedLanguages.any((l) => l.code == code);

  static const List<String> flowCategories = [
    'auth',
    'onboarding',
    'activity',
    'course',
  ];

  static String flowManifestPath(String languageCode) =>
      'assets/flows/$languageCode/flow_manifest.json';

  static String flowAssetPath(
    String languageCode,
    String category,
    String fileName,
  ) => 'assets/flows/$languageCode/$category/$fileName';

  static const int maxOtpRetries = 5;
  static const String appVersion = '1.0.0';
}
