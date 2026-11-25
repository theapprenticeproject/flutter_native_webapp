import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_section_checkpoint.dart';

/// QA bug 4: the TAP Buddy circle (design M-C01) is one orb: purple blobs, a dark
/// circle, the small TAP Buddy avatar and the caption. Ours drew its own circles
/// and then put a picture that is already a whole orb inside them: an orb in an
/// orb, with a tiny avatar and an unreadable caption.
void main() {
  testWidgets('one small avatar and the caption, not a picture of an orb', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ClassTapBuddyOrb(size: 200))),
      ),
    );
    expect(find.text('TAP Buddy'), findsOneWidget);
    // The avatar is one image, and it is small next to the dark circle.
    final image = tester.getSize(find.byType(Image));
    final orb = tester.getSize(find.byType(ClassTapBuddyOrb));
    expect(image.width, lessThan(orb.width * 0.35));
    expect(tester.takeException(), isNull);
  });

  for (final size in [100.0, 136.0, 240.0]) {
    testWidgets('fits at $size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: ClassTapBuddyOrb(size: size)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ClassTapBuddyOrb)).width, size);
    });
  }

  test('does not use the picture that is already a whole orb', () {
    final text = File(
      'lib/features/classroom/presentation/widgets/class_section_checkpoint.dart',
    ).readAsStringSync();
    expect(text.contains('tap_buddy_ai.png'), isFalse);
  });
}
