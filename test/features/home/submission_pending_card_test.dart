import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/home/presentation/widgets/submission_pending_card.dart';

/// R-4 and R-68: after the work is sent, Home shows "submission pending". The
/// student leaves the app and waits. After 24 hours the text says it is taking
/// longer than expected.
Future<void> _pump(WidgetTester tester, {required bool slow}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubmissionPendingCard(
              courseDisplay: 'Science',
              unitName: 'Glowing LED Card',
              slow: slow,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('waiting: says TAP Buddy is looking at the work', (tester) async {
    await _pump(tester, slow: false);
    expect(find.text('Glowing LED Card'), findsOneWidget);
    expect(find.text('Pending: Feedback'), findsOneWidget);
    expect(find.textContaining("I'm looking at your work"), findsOneWidget);
    expect(find.textContaining('longer than expected'), findsNothing);
  });

  testWidgets('slow: says it is taking longer than expected', (tester) async {
    await _pump(tester, slow: true);
    expect(find.textContaining('longer than expected'), findsOneWidget);
    expect(find.textContaining("I'm looking at your work"), findsNothing);
  });

  testWidgets('both have a Check again button, and no technical text', (
    tester,
  ) async {
    for (final slow in [false, true]) {
      await _pump(tester, slow: slow);
      expect(find.text('Check again'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    }
  });
}
