import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/shared/widgets/app_header.dart';

/// The Home design shows the points as "3 Points" (with the word). The activity
/// header shows only the number next to the coin ("40").
Future<void> _pump(WidgetTester tester, Widget header) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: header)));
  await tester.pump();
}

void main() {
  askTapButtonTests();
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

  // The Home design (M-F2-01): "Hi Aarav 👋" and the points pill on one row, no
  // line "Ready for today's class?" under it, and a ring-shaped coin.
  group('the Home header follows the design', () {
    const home = AppHeader(
      title: 'Home',
      studentName: 'Aarav',
      points: 3,
      showStudentSummary: true,
    );

    testWidgets('no "Ready for today\'s class?" line', (tester) async {
      await _pump(tester, home);
      expect(find.text("Ready for today's class?"), findsNothing);
    });

    testWidgets('a subtitle that is given is still shown (Me)', (tester) async {
      await _pump(
        tester,
        const AppHeader(
          title: 'Me',
          studentName: 'Aarav',
          points: 3,
          showStudentSummary: true,
          subtitle: 'Have a look at your progress',
        ),
      );
      expect(find.text('Have a look at your progress'), findsOneWidget);
    });

    testWidgets('the greeting and the pill are on one row', (tester) async {
      await _pump(tester, home);
      final hi = tester.getCenter(find.textContaining('Hi Aarav'));
      final pill = tester.getCenter(find.text('3 Points'));
      expect((hi.dy - pill.dy).abs(), lessThan(4));
    });

    testWidgets('the pill is 36 high with the ring coin', (tester) async {
      await _pump(tester, home);
      final pill = find.ancestor(
        of: find.text('3 Points'),
        matching: find.byKey(const ValueKey('points-pill')),
      );
      expect(tester.getSize(pill).height, 36);
      expect(find.byKey(const ValueKey('points-coin')), findsOneWidget);
    });

    testWidgets('a divider between the two logos', (tester) async {
      await _pump(tester, home);
      expect(find.byKey(const ValueKey('logo-divider')), findsOneWidget);
    });
  });
}

/// Design M-F2-01 and M-C01: the header has an "Ask TAP" button.
void askTapButtonTests() {
  group('the Ask TAP button', () {
    testWidgets('Home header: shown, and it works', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppHeader(
          title: 'Home',
          studentName: 'Aarav',
          points: 3,
          showStudentSummary: true,
          onAskTap: () => taps++,
        ),
      );
      await tester.tap(find.text('Ask TAP'));
      expect(taps, 1);
    });

    testWidgets('activity header: shown, and it works', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppHeader(
          title: 'Unit',
          showBack: true,
          showPoints: true,
          points: 40,
          onAskTap: () => taps++,
        ),
      );
      await tester.tap(find.text('Ask TAP'));
      expect(taps, 1);
    });

    testWidgets('no callback, no button', (tester) async {
      await _pump(
        tester,
        const AppHeader(
          title: 'Home',
          studentName: 'A',
          showStudentSummary: true,
        ),
      );
      expect(find.text('Ask TAP'), findsNothing);
    });
  });
}
