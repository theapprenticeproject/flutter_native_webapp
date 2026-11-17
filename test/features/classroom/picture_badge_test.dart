import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/picture_badge.dart';

/// R-69: a small badge on every screen of the activity shows 0/4 up to 4/4.
Future<void> _pump(
  WidgetTester tester,
  int pieces, {
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PictureBadge(pieces: pieces, onTap: onTap),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows n/4 for every count', (tester) async {
    for (final n in [0, 1, 2, 3, 4]) {
      await _pump(tester, n);
      expect(find.text('$n/4'), findsOneWidget, reason: 'for $n pieces');
    }
  });

  testWidgets('a count outside 0 to 4 is kept inside the range', (
    tester,
  ) async {
    await _pump(tester, 7);
    expect(find.text('4/4'), findsOneWidget);
    await _pump(tester, -1);
    expect(find.text('0/4'), findsOneWidget);
  });

  testWidgets('says what it is for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, 2);
    expect(
      find.bySemanticsLabel(RegExp(r"Today's picture, 2 of 4")),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('tapping the badge opens the picture', (tester) async {
    var taps = 0;
    await _pump(tester, 2, onTap: () => taps++);
    await tester.tap(find.text('2/4'));
    expect(taps, 1);
  });
}
