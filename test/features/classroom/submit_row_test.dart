import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_submission_card.dart';

void main() {
  testWidgets(
    'a long label stays on one line and inside the button, big text too',
    (tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SubmitRow(
                  label: 'Share submission',
                  onPressed: () {},
                  onHelp: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final label = tester.getRect(find.text('Share submission'));
      final button = tester.getRect(find.byType(ElevatedButton));
      expect(
        button.contains(label.topLeft) && button.contains(label.bottomRight),
        isTrue,
      );
      expect(find.text('Submission Help'), findsOneWidget);
    },
  );

  // QA bug 9: the Submit label was Flutter's small default (14). The design's
  // main buttons use a large label: 18, semi-bold, like the welcome Continue.
  testWidgets('the label is 18, semi-bold, like the other main buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubmitRow(label: 'Submit', onPressed: () {}, onHelp: () {}),
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('Submit')).style;
    expect(style?.fontSize, 18);
    expect(style?.fontWeight, FontWeight.w600);
    expect(tester.getSize(find.byType(ElevatedButton)).height, 52);
  });

  // QA slide 10 circled the "Submission Help" link too: it was Flutter's small
  // default (14). It is 16, like the other secondary actions.
  testWidgets('the Submission Help link is 16', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubmitRow(label: 'Submit', onPressed: () {}, onHelp: () {}),
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('Submission Help')).style;
    expect(style?.fontSize, 16);
  });
}
