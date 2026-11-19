import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// In Riverpod 2.6, `ref.watch(provider).value` THROWS when the provider failed.
/// In a build method that gives a blank gray page in a release build (the
/// Gallery did, when the course was not bundled). Use `.valueOrNull`, or handle
/// the error with `.when`.
void main() {
  test('no screen or provider reads ref.watch(...).value', () {
    final bad = RegExp(r'ref\.(watch|read)\([^;]*\)\s*\.value\b(?!OrNull)');
    final found = <String>[];
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      for (final m in bad.allMatches(text)) {
        found.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(found, isEmpty);
  });
}
