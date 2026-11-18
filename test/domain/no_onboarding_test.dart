import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// v1 has no onboarding (the kids are pre-registered), no theme switch (R-73),
/// no account deletion yet (R-36) and no profile editing (R-74). The old
/// prototype code for these, and the old profile routes, must not come back.
final _forbidden = <String, RegExp>{
  'the onboarding screens or routes': RegExp(
    r"features/onboarding|AppRoutes\.onboarding|ConversationalOnboarding",
  ),
  'the onboarding flag': RegExp(r'onboardingCompleted|onboarding_completed'),
  'the old profile routes': RegExp(
    r'''['"]/(profiles|students|achievements|onboarding)\b''',
  ),
  'the old ApiEndpoints class': RegExp(r'\bApiEndpoints\b'),
  'the theme switch': RegExp(r'_ThemeCard|ThemeButton'),
  'the account management card': RegExp(r'AccountManagement'),
};

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final entry in _forbidden.entries) {
    test('lib/ has no ${entry.key}', () {
      final found = <String>[];
      for (final f in files) {
        for (final line in f.readAsLinesSync()) {
          if (entry.value.hasMatch(line)) {
            found.add('${f.path}: ${line.trim()}');
          }
        }
      }
      expect(found, isEmpty);
    });
  }

  test('the onboarding folder is gone', () {
    expect(Directory('lib/features/onboarding').existsSync(), isFalse);
    expect(Directory('test/features/onboarding').existsSync(), isFalse);
  });

  test('the old profile list code is gone', () {
    for (final path in [
      'lib/domain/profile/profile_summary_model.dart',
      'lib/domain/profile/roster_cache_sync.dart',
      'lib/core/network/api_endpoints.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}
