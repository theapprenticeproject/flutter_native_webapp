import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/domain/auth/auth_provider.dart';
import 'package:tapapp/domain/auth/magic_link_repository.dart';
import 'package:tapapp/domain/auth/redeemed_student.dart';
import 'package:tapapp/features/auth/presentation/link_sign_in_screen.dart';

class _FakeRepo implements MagicLinkRepository {
  _FakeRepo(this.onRedeem);
  final Future<RedeemResult> Function(String code) onRedeem;
  final codes = <String>[];

  @override
  Future<RedeemResult> redeem(String code) {
    codes.add(code);
    return onRedeem(code);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RedeemedStudent _s(String id) =>
    RedeemedStudent(studentId: id, name: id, grade: '5');

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  final router = GoRouter(
    initialLocation: '/l/CODE-1',
    routes: [
      GoRoute(
        path: '/l/:code',
        builder: (_, state) =>
            LinkSignInScreen(code: state.pathParameters['code']!),
      ),
      GoRoute(path: '/home', builder: (_, _) => const Text('HOME PAGE')),
      GoRoute(
        path: '/profile-select',
        builder: (_, _) => const Text('PICKER PAGE'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        magicLinkRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one student goes straight to Home', (tester) async {
    final a = _s('S1');
    final repo = _FakeRepo(
      (_) async => RedeemResult(students: [a], activeStudent: a),
    );
    await _pump(tester, repo);
    expect(repo.codes, ['CODE-1']);
    expect(find.text('HOME PAGE'), findsOneWidget);
  });

  testWidgets('several students go to the name picker', (tester) async {
    final a = _s('S1');
    final repo = _FakeRepo(
      (_) async => RedeemResult(students: [a, _s('S2')], activeStudent: a),
    );
    await _pump(tester, repo);
    expect(find.text('PICKER PAGE'), findsOneWidget);
  });

  testWidgets('an expired link shows a plain message, no code or exception', (
    tester,
  ) async {
    final repo = _FakeRepo(
      (_) async => throw ApiException('UNAUTHORIZED', 'magic link has expired'),
    );
    await _pump(tester, repo);
    expect(find.textContaining('link'), findsWidgets);
    expect(find.textContaining('UNAUTHORIZED'), findsNothing);
    expect(find.textContaining('expired'), findsNothing);
    expect(find.text('HOME PAGE'), findsNothing);
  });

  testWidgets('a phone with no student shows a plain message', (tester) async {
    final repo = _FakeRepo(
      (_) async => throw ApiException('STUDENT_NOT_FOUND', 'no student'),
    );
    await _pump(tester, repo);
    expect(find.textContaining('STUDENT_NOT_FOUND'), findsNothing);
    expect(find.textContaining('not signed up'), findsOneWidget);
  });

  testWidgets('a network failure offers Try again, and it tries again', (
    tester,
  ) async {
    var calls = 0;
    final a = _s('S1');
    final repo = _FakeRepo((_) async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return RedeemResult(students: [a], activeStudent: a);
    });
    await _pump(tester, repo);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('HOME PAGE'), findsOneWidget);
  });
}
