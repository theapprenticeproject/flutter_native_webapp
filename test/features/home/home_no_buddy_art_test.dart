import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Figma M-F2-01: the Home card has no TAP Buddy picture under it. The picture
/// stays only on the "done" screen, which has no mock yet.
void main() {
  test(
    'the active Home cards (start, quiz, send, waiting) have no buddy art',
    () {
      final text = File(
        'lib/features/home/presentation/home_screen.dart',
      ).readAsStringSync();
      final from = text.indexOf('class _StageContent');
      final to = text.indexOf('class _CompletedStage');
      expect(from, greaterThan(0));
      expect(to, greaterThan(from));
      expect(
        text.substring(from, to).contains('HomeBuddyArt'),
        isFalse,
        reason: 'the picture below the card is not in the design',
      );
    },
  );
}
