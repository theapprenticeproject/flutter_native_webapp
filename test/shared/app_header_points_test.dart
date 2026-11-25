import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/shared/widgets/app_header.dart';

/// The Home design shows the points as "3 Points" (with the word). The activity
/// header shows only the number next to the coin ("40").
Future<void> _pump(WidgetTester tester, Widget header) async {
  tester.view.physicalSize = const Size(412, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: header)));
  await tester.pump();
}

void main() {
  testWidgets('Home header: "3 Points"', (tester) async {
    await _pump(
      tester,
      const AppHeader(
        title: 'Home',
        studentName: 'Aarav',
        points: 3,
        showStudentSummary: true,
      ),
    );
    expect(find.text('3 Points'), findsOneWidget);
  });

  testWidgets('one point is "1 Point"', (tester) async {
    await _pump(
      tester,
      const AppHeader(
        title: 'Home',
        studentName: 'Aarav',
        points: 1,
        showStudentSummary: true,
      ),
    );
    expect(find.text('1 Point'), findsOneWidget);
  });

  testWidgets('no points yet: "0 Points"', (tester) async {
    await _pump(
      tester,
      const AppHeader(
        title: 'Home',
        studentName: 'Aarav',
        points: 0,
        showStudentSummary: true,
      ),
    );
    expect(find.text('0 Points'), findsOneWidget);
  });

  testWidgets('the activity header shows only the number', (tester) async {
    await _pump(
      tester,
      const AppHeader(
        title: 'Intro',
        points: 40,
        showBack: true,
        showPoints: true,
      ),
    );
    expect(find.text('40'), findsOneWidget);
    expect(find.textContaining('Points'), findsNothing);
  });
}
