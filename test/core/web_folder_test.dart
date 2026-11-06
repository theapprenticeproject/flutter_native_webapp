import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything in `web/` is copied into every build and goes live. Keep test
/// pages (for example the WhatsApp browser probes) on their own branch.
void main() {
  test('web/ has no probe or test pages', () {
    final names = Directory('web')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.toLowerCase())
        .toList();

    final probes = names.where(
      (p) =>
          p.contains('probe') ||
          p.contains('test-page') ||
          p.contains('tts-test'),
    );
    expect(
      probes,
      isEmpty,
      reason: 'These files would be deployed with the app: $probes',
    );
  });

  test('web/ still has the files the app needs', () {
    for (final name in ['index.html', 'manifest.json', 'favicon.png']) {
      expect(
        File('web/$name').existsSync(),
        isTrue,
        reason: '$name is missing',
      );
    }
  });
}
