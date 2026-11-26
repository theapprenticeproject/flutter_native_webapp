import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_video_prompt.dart';

/// The text above the video ("Watch the video by clicking on the link below…")
/// was cut off at the right edge of a narrow phone: it sat in a Row that gave it
/// no width limit, so it never wrapped.
void main() {
  const text =
      'Watch the video by clicking on the link below📹 and earn *10 points*🪩\n\n'
      'Click here 👇👇👇';

  for (final width in [280.0, 320.0, 412.0]) {
    testWidgets('a long text wraps inside a $width wide screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const ClassVideoPrompt(text: text),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'no overflow');
      final bubble = tester.getSize(find.byType(ClassVideoPrompt));
      expect(bubble.width, lessThanOrEqualTo(width));
      final lineBox = tester.getSize(find.text(text));
      expect(
        lineBox.width,
        lessThanOrEqualTo(width - 28),
        reason: 'the text stays inside the bubble padding',
      );
    });
  }
}
