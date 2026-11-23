import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/providers/not_valid_text.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';

/// The page after a work that is not valid. The Worker's feedback text, when it
/// has one, comes first. With none, the page said "Please send your work again"
/// AND "Please send corrected work": the same thing twice. And with no tries
/// left it said "send again" and then "you cannot send again".
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  test('can send again, with the Worker\'s feedback: it, then the hint', () {
    expect(
      notValidText(_en, feedback: 'Too dark.', canSend: true),
      'Too dark.\n\nPlease send corrected work 📸',
    );
  });

  test('can send again, no feedback: one sentence only', () {
    for (final none in [null, '', '   ']) {
      expect(
        notValidText(_en, feedback: none, canSend: true),
        'Please send corrected work 📸',
      );
    }
  });

  test('no tries left, with feedback: it, then why there is no button', () {
    expect(
      notValidText(_en, feedback: 'Too dark.', canSend: false),
      startsWith('Too dark.\n\nYou have used both tries'),
    );
  });

  test('no tries left, no feedback: it was not accepted, and why', () {
    final text = notValidText(_en, feedback: null, canSend: false);
    expect(text, contains('not accepted'));
    expect(text, contains('both tries'));
    expect(text, isNot(contains('send your work again')));
  });
}
