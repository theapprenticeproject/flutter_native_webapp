import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/learning_progress/class_session_bootstrap_provider.dart';
import 'package:tapapp/domain/program_content/bundled_course.dart';
import 'package:tapapp/domain/learning_progress/home_dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/domain/auth/auth_provider.dart';
import 'package:tapapp/domain/auth/magic_link_repository.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';
import 'package:tapapp/shared/errors/friendly_error.dart';
import 'package:tapapp/shared/widgets/load_error_view.dart';

/// R-44: plain messages, and a button that can fix the cause.
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  final technical = RegExp(
    r'Exception|Dio|Auth|Error\(|\bnull\b|Instance of|status code|socket',
    caseSensitive: false,
  );

  final cases = <String, (Object, ErrorAction)>{
    'expired session': (
      AuthException('invalid_or_expired_token'),
      ErrorAction.signInAgain,
    ),
    'no profile': (const NoActiveProfileException(), ErrorAction.signInAgain),
    'too many requests': (RateLimitedException('default'), ErrorAction.retry),
    'no enrollment': (const NoEnrollmentException(), ErrorAction.retry),
    'no active enrollment': (
      const NoActiveEnrollmentException(),
      ErrorAction.retry,
    ),
    'offline': (
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
      ErrorAction.retry,
    ),
    'timeout': (
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      ),
      ErrorAction.retry,
    ),
    'server 500': (
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
      ),
      ErrorAction.retry,
    ),
    'link expired (UNAUTHORIZED)': (
      ApiException('UNAUTHORIZED', 'x', status: 401),
      ErrorAction.signInAgain,
    ),
    'no student (STUDENT_NOT_FOUND)': (
      ApiException('STUDENT_NOT_FOUND', 'x', status: 404),
      ErrorAction.retry,
    ),
    'limit reached (CONFLICT)': (
      ApiException('CONFLICT', 'x', status: 409),
      ErrorAction.retry,
    ),
    'rate limited (RATE_LIMITED)': (
      ApiException('RATE_LIMITED', 'x', status: 429),
      ErrorAction.retry,
    ),
    'server problem (UPSTREAM_ERROR)': (
      ApiException('UPSTREAM_ERROR', 'x', status: 502),
      ErrorAction.retry,
    ),
    'anything else': (StateError('boom: secret detail'), ErrorAction.retry),
  };

  for (final entry in cases.entries) {
    test('${entry.key}: plain text and the right action', () {
      final f = describeError(entry.value.$1, _en);
      expect(f.action, entry.value.$2);
      for (final text in [f.title, f.message, f.buttonText]) {
        expect(text, isNotEmpty);
        expect(
          technical.hasMatch(text),
          isFalse,
          reason: 'technical text: $text',
        );
        expect(text.contains('boom'), isFalse);
      }
    });
  }

  testWidgets('Retry button runs the retry callback', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoadErrorView(
            error: StateError('boom'),
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  test('an ended session says to open the WhatsApp link again', () {
    final f = describeError(AuthException('invalid_or_expired_token'), _en);
    final text = '${f.title} ${f.message}'.toLowerCase();
    expect(f.action, ErrorAction.signInAgain);
    expect(text, contains('whatsapp'));
    expect(text, isNot(contains('password')));
    expect(text, isNot(contains('sign in')));
  });

  testWidgets(
    'the button on an ended session clears the sign-in and opens the link page',
    (tester) async {
      final repo = _FakeAuthRepo();
      final router = GoRouter(
        initialLocation: '/x',
        routes: [
          GoRoute(
            path: '/x',
            builder: (_, _) => LoadErrorView(
              error: AuthException('invalid_or_expired_token'),
              onRetry: () {},
            ),
          ),
          GoRoute(
            path: AppRoutes.openLink,
            builder: (_, _) => const Text('OPEN LINK PAGE'),
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
      await tester.pump();

      await tester.tap(
        find.text(describeError(AuthException('x'), _en).buttonText),
      );
      await tester.pumpAndSettle();

      expect(repo.cleared, 1);
      expect(find.text('OPEN LINK PAGE'), findsOneWidget);
    },
  );

  test(
    'a course that is not in the app: a plain message, and no useless button',
    () {
      final f = describeError(
        const CourseNotBundledException('CRS-SCI-05'),
        _en,
      );
      final text = '${f.title} ${f.message}';
      expect(f.action, ErrorAction.none);
      expect(
        text,
        isNot(contains('CRS-SCI-05')),
        reason: 'no id, no technical text',
      );
      expect(text.toLowerCase(), contains('teacher'));
    },
  );

  testWidgets('with nothing to retry, the error page has no button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoadErrorView(
            error: const CourseNotBundledException('X'),
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.textContaining('teacher'), findsWidgets);
  });
}

class _FakeAuthRepo implements MagicLinkRepository {
  int cleared = 0;

  @override
  Future<void> clearSession() async => cleared++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
