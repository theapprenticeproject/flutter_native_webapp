import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/domain/auth/magic_link_repository.dart';
import 'package:tapapp/domain/auth/auth_provider.dart';
import 'package:tapapp/domain/auth/redeemed_student.dart';
import 'package:tapapp/domain/program_content/program_content_provider.dart';
import 'package:tapapp/features/auth/presentation/profile_select_screen.dart';

/// QA bugs 1 and 2: the picker must look like the design (M-F1-01): the two
/// logos, the round TAP Buddy picture, "Welcome", "Hi Champ, please select who I
/// will talk to", and one row for each student with the initials, the name,
/// "Class N • subject" and a Select button. No "Hear again": there is no audio
/// in v1.
RedeemedStudent _s(String id, String name, String grade, String course) =>
    RedeemedStudent(
      studentId: id,
      name: name,
      grade: grade,
      points: 0,
      courseId: course,
    );

Future<void> _pump(
  WidgetTester tester, {
  List<RedeemedStudent>? students,
  Map<String, String> courseNames = const {},
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        linkRosterProvider.overrideWith(
          (ref) async =>
              students ??
              [
                _s('S1', 'Aarav Kumar', '5', 'C-SCI'),
                _s('S2', 'Ajay Kumar', '8', 'C-FIN'),
              ],
        ),
        courseNameByIdProvider.overrideWith((ref) async => courseNames),
      ],
      child: const MaterialApp(home: ProfileSelectScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeRepo implements MagicLinkRepository {
  _FakeRepo(this.picked);
  final List<String> picked;

  @override
  Future<RedeemedStudent> switchStudent(String studentId) async {
    picked.add(studentId);
    return _s(studentId, 'x', '1', 'c');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('has the welcome picture and the two lines of the design', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Welcome'), findsOneWidget);
    expect(
      find.text('Hi Champ, please select who I will talk to'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Hear again'), findsNothing);
    expect(find.text("Who's learning today?"), findsNothing);
  });

  testWidgets('one row for each student: initials, name, class and subject', (
    tester,
  ) async {
    await _pump(
      tester,
      courseNames: {'C-SCI': 'Science', 'C-FIN': 'Financial Literacy'},
    );
    expect(find.text('AK'), findsNWidgets(2));
    expect(find.text('Aarav Kumar'), findsOneWidget);
    expect(find.text('Ajay Kumar'), findsOneWidget);
    expect(find.text('Class 5 • Science'), findsOneWidget);
    expect(find.text('Class 8 • Financial Literacy'), findsOneWidget);
    expect(find.text('Select'), findsNWidgets(2));
  });

  testWidgets('a course we do not know shows only the class', (tester) async {
    await _pump(tester);
    expect(find.text('Class 5'), findsOneWidget);
    expect(find.textContaining('•'), findsNothing);
  });

  testWidgets('the rows are a list, not a grid', (tester) async {
    await _pump(tester);
    final a = tester.getTopLeft(find.text('Aarav Kumar'));
    final b = tester.getTopLeft(find.text('Ajay Kumar'));
    expect(b.dx, a.dx, reason: 'same column');
    expect(b.dy, greaterThan(a.dy));
  });

  testWidgets('no student on the phone: says so', (tester) async {
    await _pump(tester, students: const []);
    expect(
      find.text('No student profiles found for this account.'),
      findsOneWidget,
    );
    expect(find.text('Select'), findsNothing);
  });

  // Design notes (Screen 1): the picked row gets a purple border and a
  // "Selected ✓" tag, and a Continue button appears. Select no longer signs the
  // student in at once.
  group('picking a student', () {
    Future<List<String>> pumpWithRouter(WidgetTester tester) async {
      final picked = <String>[];
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: AppRoutes.profileSelect,
        routes: [
          GoRoute(
            path: AppRoutes.profileSelect,
            builder: (_, _) => const ProfileSelectScreen(),
          ),
          GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('HOME')),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            linkRosterProvider.overrideWith(
              (ref) async => [
                _s('S1', 'Aarav Kumar', '5', 'C-SCI'),
                _s('S2', 'Ajay Kumar', '8', 'C-FIN'),
              ],
            ),
            courseNameByIdProvider.overrideWith((ref) async => {}),
            magicLinkRepositoryProvider.overrideWith(
              (ref) async => _FakeRepo(picked),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('nothing is picked at first: no Continue button', (
      tester,
    ) async {
      await pumpWithRouter(tester);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Selected ✓'), findsNothing);
    });

    testWidgets('Select marks the row and shows Continue, without signing in', (
      tester,
    ) async {
      final picked = await pumpWithRouter(tester);
      await tester.tap(find.text('Select').first);
      await tester.pumpAndSettle();
      expect(find.text('Selected ✓'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget, reason: 'the other row');
      expect(find.text('Continue'), findsOneWidget);
      expect(picked, isEmpty);
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('the picked row has a purple border', (tester) async {
      await pumpWithRouter(tester);
      await tester.tap(find.text('Select').first);
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('student-S1-selected'));
      expect(row, findsOneWidget);
      final box = tester.widget<Container>(row).decoration as BoxDecoration;
      expect((box.border as Border).top.color, const Color(0xFF5B5BD6));
    });

    testWidgets('picking another student moves the mark', (tester) async {
      await pumpWithRouter(tester);
      await tester.tap(find.text('Select').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-S2-selected')), findsOneWidget);
      expect(find.byKey(const ValueKey('student-S1-selected')), findsNothing);
      expect(find.text('Selected ✓'), findsOneWidget);
    });

    testWidgets('Continue signs in the picked student and goes on', (
      tester,
    ) async {
      final picked = await pumpWithRouter(tester);
      await tester.tap(find.text('Select').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(picked, ['S2']);
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
