import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/shared/widgets/app_nav.dart';

/// R-1: the bottom bar has 3 items: Home, Gallery, Me. There is no Class tab
/// (R-2: the activity opens from Home, it is not a tab).
Future<GoRouter> _pump(WidgetTester tester, {String start = '/home'}) async {
  Widget page(String name) => AppNav(child: Center(child: Text('$name PAGE')));
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => page('Home')),
      GoRoute(path: AppRoutes.gallery, builder: (_, _) => page('Gallery')),
      GoRoute(path: AppRoutes.passport, builder: (_, _) => page('Me')),
      GoRoute(path: AppRoutes.classroom, builder: (_, _) => page('Class')),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('the bar has exactly Home, Gallery and Me', (tester) async {
    await _pump(tester);
    for (final label in ['Home', 'Gallery', 'Me']) {
      expect(
        find.widgetWithText(InkWell, label),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.widgetWithText(InkWell, 'Class'), findsNothing);
    expect(find.widgetWithText(InkWell, 'Passport'), findsNothing);
    expect(find.widgetWithText(InkWell, 'Profile'), findsNothing);
    expect(find.byType(InkWell), findsNWidgets(3));
  });

  testWidgets('Gallery and Me open their pages', (tester) async {
    await _pump(tester);

    await tester.tap(find.widgetWithText(InkWell, 'Gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Gallery PAGE'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Me'));
    await tester.pumpAndSettle();
    expect(find.text('Me PAGE'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home PAGE'), findsOneWidget);
  });

  testWidgets('the activity (opened from Home) keeps Home as the active tab', (
    tester,
  ) async {
    await _pump(tester, start: AppRoutes.classroom);
    // The active tab is drawn as a filled button with white text.
    final home = tester.widget<Text>(find.text('Home'));
    final gallery = tester.widget<Text>(find.text('Gallery'));
    expect(home.style?.color, Colors.white);
    expect(gallery.style?.color, isNot(Colors.white));
  });
}
