import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_section_checkpoint.dart';

/// R-66: "Are you ready to share your work?" has two choices: Yes, or Not today.
Future<void> _pump(
  WidgetTester tester, {
  String? secondaryLabel,
  VoidCallback? onSecondary,
  VoidCallback? onMain,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ClassSectionCheckpoint(
          kind: ClassSectionCheckpointKind.submission,
          text: 'Are you ready to share your work?',
          buttonLabel: "Yes, let's go",
          onPressed: onMain,
          secondaryLabel: secondaryLabel,
          onSecondary: onSecondary,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows both choices and each one works', (tester) async {
    var main = 0;
    var later = 0;
    await _pump(
      tester,
      secondaryLabel: 'Not today',
      onMain: () => main++,
      onSecondary: () => later++,
    );

    expect(find.text("Yes, let's go"), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);

    await tester.tap(find.text('Not today'));
    expect(later, 1);
    expect(main, 0);

    await tester.tap(find.text("Yes, let's go"));
    expect(main, 1);
  });

  testWidgets('without a second choice there is only the one button', (
    tester,
  ) async {
    await _pump(tester, onMain: () {});
    expect(find.text('Not today'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
