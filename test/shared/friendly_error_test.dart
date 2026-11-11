import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/learning_progress/class_session_bootstrap_provider.dart';
import 'package:tapapp/domain/learning_progress/home_dashboard_provider.dart';
import 'package:tapapp/shared/errors/friendly_error.dart';
import 'package:tapapp/shared/widgets/load_error_view.dart';

/// R-44: plain messages, and a button that can fix the cause.
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
    'anything else': (StateError('boom: secret detail'), ErrorAction.retry),
  };

  for (final entry in cases.entries) {
    test('${entry.key}: plain text and the right action', () {
      final f = describeError(entry.value.$1);
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
}
