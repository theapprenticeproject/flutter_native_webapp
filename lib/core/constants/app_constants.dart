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
  /// The Worker the app talks to. `scripts/build_web.sh` sets it from the
  /// `WORKER_URL` environment variable (for example the dev Worker). A build
  /// without it uses the production Worker.
  static const String workerBaseUrl = String.fromEnvironment(
    'WORKER_URL',
    defaultValue: 'https://tapapp-worker.tapapp-middleware.workers.dev',
  );

  /// Skips the photo and video upload. Only for a build against the test
  /// Worker, whose upload address is fake. `scripts/build_web.sh` refuses it
  /// for a production build.
  static const bool skipUpload = bool.fromEnvironment('SKIP_UPLOAD');

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

  /// The app's language code for what the Worker sends: a code ("hi") or a name
  /// ("Hindi"). Anything else, or nothing, is English.
  static String languageCodeFor(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    for (final l in supportedLanguages) {
      if (v == l.code || v == l.label.toLowerCase()) return l.code;
    }
    return defaultLanguageCode;
  }

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
