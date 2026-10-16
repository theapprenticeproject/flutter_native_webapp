/// Build details, passed in by `scripts/build_web.sh` with `--dart-define`.
/// A build made without the script shows "unknown".
class BuildInfo {
  BuildInfo._();

  static const String time = String.fromEnvironment(
    'BUILD_TIME',
    defaultValue: 'unknown',
  );
  static const String commit = String.fromEnvironment(
    'GIT_SHA',
    defaultValue: 'unknown',
  );
  static const String flutterVersion = String.fromEnvironment(
    'BUILD_FLUTTER_VERSION',
    defaultValue: 'unknown',
  );
  static const String engineRevision = String.fromEnvironment(
    'BUILD_ENGINE_REVISION',
    defaultValue: 'unknown',
  );

  static String get label =>
      'Build $time · $commit · Flutter $flutterVersion (engine $engineRevision)';
}
