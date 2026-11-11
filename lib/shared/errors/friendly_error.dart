import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/http_client.dart';
import '../../domain/learning_progress/class_session_bootstrap_provider.dart';
import '../../domain/learning_progress/home_dashboard_provider.dart';

/// What the student can do about an error (R-44).
enum ErrorAction {
  /// Trying again can fix it (no internet, busy server).
  retry,

  /// Trying again cannot fix it. The student must sign in again.
  signInAgain,
}

/// A plain message for a failed call. It never contains technical text.
class FriendlyError {
  const FriendlyError({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.action,
  });

  final String title;
  final String message;
  final String buttonText;
  final ErrorAction action;
}

/// Turns any error into a [FriendlyError]. Log the real error elsewhere.
FriendlyError describeError(Object error) {
  if (error is ApiException) return _describeApiError(error);
  if (error is AuthException || error is NoActiveProfileException) {
    return const FriendlyError(
      title: 'Please sign in again',
      message: 'Your session has ended. Sign in to carry on.',
      buttonText: 'Sign in',
      action: ErrorAction.signInAgain,
    );
  }
  if (error is RateLimitedException) {
    return const FriendlyError(
      title: 'Please wait a little',
      message: 'Too many tries. Wait a minute, then try again.',
      buttonText: 'Try again',
      action: ErrorAction.retry,
    );
  }
  if (error is NoEnrollmentException || error is NoActiveEnrollmentException) {
    return const FriendlyError(
      title: 'No course yet',
      message: 'You are not in a course yet. Ask your teacher, then try again.',
      buttonText: 'Try again',
      action: ErrorAction.retry,
    );
  }
  if (error is DioException && _isConnectionProblem(error)) {
    return const FriendlyError(
      title: 'No internet',
      message: 'Check your internet connection, then try again.',
      buttonText: 'Try again',
      action: ErrorAction.retry,
    );
  }
  return const FriendlyError(
    title: 'Something went wrong',
    message: 'We could not load this. Please try again.',
    buttonText: 'Try again',
    action: ErrorAction.retry,
  );
}

/// The Worker's error codes (`api-contract.md`). The Worker's own message is
/// for logs only, so none of it is shown.
FriendlyError _describeApiError(ApiException e) {
  switch (e.code) {
    case 'UNAUTHORIZED':
      return describeError(AuthException(e.code));
    case 'RATE_LIMITED':
      return describeError(RateLimitedException('default'));
    case 'STUDENT_NOT_FOUND':
      return const FriendlyError(
        title: 'We could not find you',
        message:
            'This phone number is not signed up for TAP yet. '
            'Please ask your teacher.',
        buttonText: 'Try again',
        action: ErrorAction.retry,
      );
    case 'CONFLICT':
      return const FriendlyError(
        title: 'That is all for now',
        message: 'You have reached the limit for this activity.',
        buttonText: 'Try again',
        action: ErrorAction.retry,
      );
    default:
      return describeError(StateError(e.code));
  }
}

bool _isConnectionProblem(DioException e) =>
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.sendTimeout ||
    e.type == DioExceptionType.receiveTimeout;
