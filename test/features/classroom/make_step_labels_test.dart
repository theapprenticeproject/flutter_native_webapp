import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R-63: the Make step is a photo or a video. The card must say so, and must not
/// show made-up "friends" work. A tester took the row of cat, rocket and rainbow
/// emoji for emoji answers.
void main() {
  final text = File(
    'lib/features/classroom/presentation/widgets/class_submission_card.dart',
  ).readAsStringSync();

  // The words live in the translation file now.
  final words = File('lib/l10n/app_en.arb').readAsStringSync();

  test('the photo step is called PHOTO, not SCREENSHOT', () {
    expect(
      text.contains('SCREENSHOT') || words.contains('SCREENSHOT'),
      isFalse,
    );
    expect(words.contains('📷 PHOTO'), isTrue);
  });

  test('the photo and video card shows no made-up friends work', () {
    expect(text.contains('_mediaFriendExamples'), isFalse);
    for (final emoji in ['🐱', '🌈']) {
      expect(text.contains(emoji), isFalse, reason: emoji);
    }
  });
}
