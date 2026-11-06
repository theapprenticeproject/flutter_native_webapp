import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/constants/app_constants.dart';
import 'package:tapapp/core/constants/build_info.dart';

void main() {
  test('label lists build time, commit, Flutter version and engine', () {
    final label = BuildInfo.label;

    expect(label, startsWith('Build '));
    expect(label, contains('Flutter '));
    expect(label, contains('engine '));
  });

  test('label shows which Worker host the build talks to', () {
    expect(BuildInfo.label, endsWith('API ${BuildInfo.workerHost}'));
    expect(BuildInfo.workerHost, isNotEmpty);
  });

  test('the default Worker is production, an https origin with no slash', () {
    // Run without --dart-define=WORKER_URL, as `flutter test` does by default.
    final url = AppConstants.workerBaseUrl;
    expect(url, startsWith('https://'));
    expect(url, isNot(endsWith('/')));
    expect(Uri.parse(url).path, isEmpty);
  });
}
