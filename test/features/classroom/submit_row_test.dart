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
}
