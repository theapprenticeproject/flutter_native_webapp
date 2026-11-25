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
Future<void> _pumpFor(WidgetTester tester, String? name) async {
  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeBackScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('HOME')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileProvider.overrideWith(
          (ref) async =>
              ActiveProfileModel(phone: '', learnerId: 'S1', studentName: name),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

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

  // QA bug 1 (design M-F1-04): both lines are one bold, dark heading of one
  // size. The second line was small and light grey, the name was the full name
  // and had a space before the "!".
  group('the welcome heading follows the design', () {
    testWidgets('one heading with both lines, the first name only', (
      tester,
    ) async {
      await _pumpFor(tester, 'Aarav Kumar');
      expect(
        find.text('Welcome Back, Aarav!\nAre you ready for a New Year?'),
        findsOneWidget,
      );
      expect(find.textContaining('Kumar'), findsNothing);
    });

    testWidgets('the heading is bold, dark and 24', (tester) async {
      await _pumpFor(tester, 'Aarav Kumar');
      final style = tester
          .widget<Text>(find.textContaining('Welcome Back'))
          .style;
      expect(style?.fontSize, 24);
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.color, const Color(0xFF1C1C21));
    });

    testWidgets('no small grey second line', (tester) async {
      await _pumpFor(tester, 'Aarav Kumar');
      expect(find.text('Are you ready for a New Year?'), findsNothing);
    });

    testWidgets('a name with a trailing space has no space before "!"', (
      tester,
    ) async {
      await _pumpFor(tester, 'Supriya ');
      expect(find.textContaining('Supriya!'), findsOneWidget);
      expect(find.textContaining('Supriya !'), findsNothing);
    });

    testWidgets('no name: "there"', (tester) async {
      await _pumpFor(tester, null);
      expect(find.textContaining('Welcome Back, there!'), findsOneWidget);
    });
  });
}
