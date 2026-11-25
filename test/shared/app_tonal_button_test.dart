import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/shared/widgets/app_tonal_button.dart';

/// QA (slide 10): "I'll do it later →" is a light purple pill button in the
/// design (S-01), not a small text link.
void main() {
  testWidgets(
    'light lavender button, purple label 16, 44 high, with an arrow',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppTonalButton(
                label: "I'll do it later",
                trailing: Icons.arrow_forward_rounded,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, 44);
      final style = tester.widget<Text>(find.text("I'll do it later")).style;
      expect(style?.fontSize, 16);
      expect(style?.fontWeight, FontWeight.w500);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      await tester.tap(find.text("I'll do it later"));
      expect(taps, 1);
    },
  );
}
