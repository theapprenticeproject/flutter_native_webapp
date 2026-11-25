import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/theme/app_theme.dart';
import 'package:tapapp/shared/widgets/app_primary_button.dart';

/// QA bugs 6 and 13: the main buttons had many sizes (44 to 76 high), radii (10
/// to 30), label sizes (12 to 18) and disabled colours. They are one button now.
Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('one size: 52 high, label 18 semi-bold, full width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 300,
          child: AppPrimaryButton(label: 'Continue', onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ElevatedButton)).height, 52);
    expect(tester.getSize(find.byType(ElevatedButton)).width, 300);
    final style = tester.widget<Text>(find.text('Continue')).style;
    expect(style?.fontSize, 18);
    expect(style?.fontWeight, FontWeight.w600);
  });

  testWidgets('the app purple, and the muted lavender when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(AppPrimaryButton(label: 'Go', onPressed: () {})),
    );
    Color? bg() => tester
        .widget<ElevatedButton>(find.byType(ElevatedButton))
        .style
        ?.backgroundColor
        ?.resolve(<WidgetState>{});
    expect(bg(), AppTheme.buttonColor);
    await tester.pumpWidget(
      _wrap(const AppPrimaryButton(label: 'Go', onPressed: null)),
    );
    final disabled = tester
        .widget<ElevatedButton>(find.byType(ElevatedButton))
        .style
        ?.backgroundColor
        ?.resolve(<WidgetState>{WidgetState.disabled});
    expect(disabled, AppTheme.mutedLavender);
  });

  testWidgets(
    'a long label shrinks and stays on one line, even with big text',
    (tester) async {
      tester.view.physicalSize = const Size(280, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 240,
            child: AppPrimaryButton(
              label: 'Yes, I want to send my project now',
              onPressed: () {},
            ),
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ElevatedButton)).height, 52);
    },
  );

  testWidgets('the loading state shows a spinner and is not pressable', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        AppPrimaryButton(label: 'Send', loading: true, onPressed: () => taps++),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 0);
  });

  // New one-off buttons would bring the mismatch back.
  test('screens use AppPrimaryButton, not their own ElevatedButton', () {
    final found = <String>[];
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.endsWith('app_primary_button.dart')) continue;
      final text = f.readAsStringSync();
      final count = RegExp(r'\bElevatedButton\(').allMatches(text).length;
      if (count > 0) found.add('${f.path}: $count');
    }
    expect(found, isEmpty, reason: 'use AppPrimaryButton: $found');
  });
}
