import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/domain/auth/auth_provider.dart';
import 'package:tapapp/domain/auth/magic_link_repository.dart';
import 'package:tapapp/domain/auth/redeemed_student.dart';
import 'package:tapapp/domain/me/me_provider.dart';
import 'package:tapapp/domain/profile/active_profile_model.dart';
import 'package:tapapp/domain/profile/profile_provider.dart';
import 'package:tapapp/features/me/presentation/me_screen.dart';

class _FakeRepo implements MagicLinkRepository {
  final switched = <String>[];

  @override
  Future<RedeemedStudent> switchStudent(String studentId) async {
    switched.add(studentId);
    return RedeemedStudent(studentId: studentId, name: studentId, grade: '5');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// After the student switches profile, the app goes to Home (the new student's
/// activity), and does not stay on Me.
void main() {
  testWidgets('switching profile goes to Home', (tester) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _FakeRepo();
    final router = GoRouter(
      initialLocation: AppRoutes.me,
      routes: [
        GoRoute(path: AppRoutes.me, builder: (_, _) => const MeScreen()),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Text('HOME PAGE'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meDataProvider.overrideWith(
            (ref) async => const MeData(
              studentName: 'Durva',
              grade: '5',
              school: null,
              subject: null,
              points: 10,
              level: null,
              projects: [],
            ),
          ),
          activeProfileProvider.overrideWith(
            (ref) async => const ActiveProfileModel(
              phone: '',
              learnerId: 'S1',
              studentName: 'Durva',
            ),
          ),
          linkRosterProvider.overrideWith(
            (ref) async => const [
              RedeemedStudent(studentId: 'S1', name: 'Durva', grade: '5'),
              RedeemedStudent(studentId: 'S2', name: 'Manu', grade: '8'),
            ],
          ),
          magicLinkRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Switch Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Manu'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(repo.switched, ['S2']);
    expect(find.text('HOME PAGE'), findsOneWidget);
  });
}
