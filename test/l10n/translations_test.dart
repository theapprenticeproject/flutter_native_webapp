import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A translation must keep the {placeholders} of the English text, or the app
/// would show "{name}" to the student. Texts left out fall back to English.
/// The sheet script (scripts/arb_sheet.py) checks the same when it imports.
void main() {
  Map<String, dynamic> arb(String code) =>
      jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
          as Map<String, dynamic>;
  Set<String> placeholders(String text) =>
      RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

  final en = arb('en');

  for (final code in ['hi', 'kn', 'mr', 'pa']) {
    test('$code: only known texts, with the English placeholders', () {
      for (final e in arb(code).entries) {
        if (e.key.startsWith('@')) continue;
        expect(
          en.containsKey(e.key),
          isTrue,
          reason: '${e.key} is not in English',
        );
        expect(
          placeholders(e.value as String),
          placeholders(en[e.key] as String),
          reason: '$code ${e.key}',
        );
      }
    });
  }

  test('the translation sheet script works (write, read, check)', () {
    final result = Process.runSync('python3', [
      '-I',
      'scripts/arb_sheet.py',
      'selftest',
    ]);
    expect(result.stdout, contains('selftest ok'), reason: '${result.stderr}');
  });
}
