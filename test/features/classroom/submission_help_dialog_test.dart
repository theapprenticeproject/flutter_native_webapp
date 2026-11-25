import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_submission_card.dart';

/// QA bug 10: in Submission Help the chips and the close X shared one row, so on
/// a narrow phone the second chip ("PHOTO / VIDEO") ran past the edge and the X
/// was pushed out; and the content did not scroll, so on a short screen the
/// Continue button could be cut off.
Future<void> _open(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const Scaffold(
          body: Center(
            child: SubmissionHelpDialog(
              kindLabel: '📷 PHOTO / 🎥 VIDEO',
              text:
                  'Share a clear screenshot or video of your activity showing a '
                  'lizard in a desert background, with the coding blocks clearly '
                  'visible in the programming area.',
              validCriteria: null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('narrow phone: both chips, the X and the title stay inside', (
    tester,
  ) async {
    await _open(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    final dialog = tester.getRect(find.byType(SubmissionHelpDialog));
    for (final text in [
      find.textContaining("TODAY'S ACTIVITY"),
      find.textContaining('PHOTO / '),
      find.text('How to submit'),
      find.byIcon(Icons.close_rounded),
    ]) {
      final r = tester.getRect(text);
      expect(r.right, lessThanOrEqualTo(dialog.right), reason: '$text');
      expect(r.left, greaterThanOrEqualTo(dialog.left), reason: '$text');
    }
  });

  testWidgets('short screen, big text: Continue can be reached', (
    tester,
  ) async {
    await _open(tester, size: const Size(320, 420), textScale: 1.4);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Continue'), 100);
    final screen = tester.view.physicalSize;
    final r = tester.getRect(find.text('Continue'));
    expect(r.bottom, lessThanOrEqualTo(screen.height));
    expect(r.top, greaterThanOrEqualTo(0));
  });

  testWidgets('Continue and the X both close it', (tester) async {
    await _open(tester, size: const Size(390, 800));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
