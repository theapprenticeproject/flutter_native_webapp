import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/features/passport/presentation/widgets/me_settings_button.dart';
import 'package:tapapp/shared/widgets/app_nav.dart';

/// R-7: Me holds settings and "switch profile". With the Profile tab gone (R-1),
/// this button is how the student reaches them (R-34).
void main() {
  testWidgets('the button opens Settings, where the student switches profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.passport,
      routes: [
        GoRoute(
          path: AppRoutes.passport,
          builder: (_, _) => const Scaffold(body: MeSettingsButton()),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Text('SETTINGS PAGE'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Settings and switch profile'), findsOneWidget);
    await tester.tap(find.text('Settings and switch profile'));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS PAGE'), findsOneWidget);
  });

  testWidgets('Me stays the active tab on the Settings page', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const AppNav(child: SizedBox()),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final me = tester.widget<Text>(find.text('Me'));
    expect(me.style?.color, Colors.white);
  });
}
