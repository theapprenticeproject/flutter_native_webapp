import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/domain/profile/active_profile_model.dart';
import 'package:tapapp/domain/profile/profile_provider.dart';
import 'package:tapapp/features/welcome/presentation/welcome_screen.dart';

/// R-3: after the student is chosen there is a "Welcome back" screen. The
/// Continue button works at once: a tester waited 5 seconds for nothing.
void main() {
  testWidgets('Continue works at once and goes Home', (tester) async {
    var done = 0;
    final router = GoRouter(
      initialLocation: AppRoutes.welcome,
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          builder: (_, _) => WelcomeBackScreen(onDone: () => done++),
        ),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('HOME')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeProfileProvider.overrideWith(
            (ref) async => const ActiveProfileModel(
              phone: '',
              learnerId: 'S1',
              studentName: 'Asha',
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(); // no waiting: the screen is just shown

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull, reason: 'enabled without a wait');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(done, 1);
    expect(find.text('HOME'), findsOneWidget);
  });
}
