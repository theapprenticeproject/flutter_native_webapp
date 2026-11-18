import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';
import 'package:tapapp/shared/errors/friendly_error.dart';

/// Screens whose text already lives in lib/l10n/app_en.arb. New text in these
/// files must go to the ARB too. Add a file here when it is moved.
const _migrated = [
  'lib/shared/errors/friendly_error.dart',
  'lib/shared/widgets/app_nav.dart',
  'lib/features/auth/presentation/open_link_screen.dart',
  'lib/features/auth/presentation/link_sign_in_screen.dart',
];

void main() {
  test('migrated files have no text written in the code', () {
    // A string literal of 3+ letters and a space or capital, inside Text( or a
    // title/message/buttonText/label argument.
    final literal = RegExp(
      r'''(Text\(\s*|title:\s*|message:\s*|buttonText:\s*)['"][A-Za-z][^'"\n]{2,}['"]''',
    );
    for (final path in _migrated) {
      final hits = literal
          .allMatches(File(path).readAsStringSync())
          .map((m) => m.group(0))
          .toList();
      expect(hits, isEmpty, reason: '$path has text in code: $hits');
    }
  });

  test('every language has every text: a missing one shows English', () {
    final en = lookupAppLocalizations(const Locale('en'));
    for (final code in ['hi', 'kn', 'mr', 'pa']) {
      final l = lookupAppLocalizations(Locale(code));
      expect(l.navGallery, en.navGallery, reason: code);
      expect(describeError(StateError('x'), l).title, en.errorGenericTitle);
    }
  });
}
