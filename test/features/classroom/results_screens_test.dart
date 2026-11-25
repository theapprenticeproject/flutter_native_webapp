import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_message_content.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_results_cards.dart';

/// The screens after the work: M-C23 (offline), M-C25 (not valid, send again),
/// M-C25A (wrong submission), M-C26 and M-C27 (total points).
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('offline card: Hey {name}, the hint and Retry (M-C23)', (
    tester,
  ) async {
    var retried = 0;
    await _pump(
      tester,
      ClassOfflineCard(name: 'Aarav', onRetry: () => retried++),
    );
    expect(
      find.text('Hey Aarav\nI am not able to talk to you'),
      findsOneWidget,
    );
    expect(
      find.text("Looks like you're offline. Click below to try again."),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('send again card: Add my work and I\'ll do it later (M-C25)', (
    tester,
  ) async {
    var add = 0;
    var later = 0;
    await _pump(
      tester,
      ClassResendCard(onAdd: () => add++, onLater: () => later++),
    );
    expect(find.text('1 photo needed'), findsOneWidget);
    await tester.tap(find.text('Add my work 📷'));
    await tester.tap(find.textContaining("I'll do it later"));
    expect([add, later], [1, 1]);
  });

  testWidgets('"You won" card: the activity points and Continue (M-C27)', (
    tester,
  ) async {
    var done = 0;
    await _pump(
      tester,
      ClassYouWonCard(
        image: 'assets/class-screen/you-won.png',
        label: 'Activity Points',
        points: 50,
        buttonLabel: 'Continue',
        onContinue: () => done++,
      ),
    );
    expect(find.text('Activity Points'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(done, 1);
  });

  testWidgets('a warning bubble is pink, a normal one is not (M-C25)', (
    tester,
  ) async {
    Color? colorOf(WidgetTester t) =>
        (t
                    .widget<Container>(
                      find
                          .ancestor(
                            of: find.text('x'),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color;
    await _pump(
      tester,
      const ClassTextBubble(text: 'x', isUser: false, isWarning: true),
    );
    final pink = colorOf(tester);
    await _pump(tester, const ClassTextBubble(text: 'x', isUser: false));
    expect(pink, const Color(0xFFFBE4E4));
    expect(colorOf(tester), isNot(pink));
  });

  testWidgets('choice buttons: the main one and the second one', (
    tester,
  ) async {
    var main = 0;
    var second = 0;
    await _pump(
      tester,
      ClassChoiceButtons(
        primaryLabel: 'Back to Home',
        onPrimary: () => main++,
        secondaryLabel: 'Check again',
        onSecondary: () => second++,
      ),
    );
    await tester.tap(find.text('Back to Home'));
    await tester.tap(find.text('Check again'));
    expect([main, second], [1, 1]);
  });
}
