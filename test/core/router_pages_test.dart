import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';

/// On the web the phone Back button moves the router to the previous address.
/// With pages that have no key, the Navigator treats the next page as the SAME
/// page with new content, and a dialog or sheet that was opened above it stays
/// on top of the new screen ("Submission Help" stayed on top of Home). The next
/// Back then left the whole screen gray. Every route page must have its own key.
GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    GoRoute(
      path: '/a',
      pageBuilder: (context, state) => AppRoutes.page(
        state,
        Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('PAGE A'),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(content: Text('HELP')),
                  ),
                  child: const Text('open dialog'),
                ),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) =>
                        const SizedBox(height: 100, child: Text('SHEET')),
                  ),
                  child: const Text('open sheet'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Text('VIEWER'),
                    ),
                  ),
                  child: const Text('open viewer'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/b',
      pageBuilder: (context, state) =>
          AppRoutes.page(state, const Scaffold(body: Text('PAGE B'))),
    ),
  ],
);

void main() {
  for (final (open, shown) in [
    ('open dialog', 'HELP'),
    ('open sheet', 'SHEET'),
    ('open viewer', 'VIEWER'),
  ]) {
    testWidgets('$shown does not stay on top of the next screen', (
      tester,
    ) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text(open));
      await tester.pumpAndSettle();
      expect(find.text(shown), findsOneWidget);

      router.go('/b'); // what the phone Back button does
      await tester.pumpAndSettle();

      expect(find.text('PAGE B'), findsOneWidget);
      expect(find.text(shown), findsNothing, reason: '$shown stayed on top');
      expect(tester.takeException(), isNull);
    });
  }

  // The text of every screen can be selected and copied. Flutter draws text on a
  // canvas, so the browser cannot select it by itself.
  testWidgets('a screen is inside a SelectionArea, so its text can be copied', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.text('PAGE A'),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );
  });
}
