import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/http_client.dart';
import '../../domain/learning_progress/class_session_bootstrap_provider.dart';
import '../../domain/learning_progress/home_dashboard_provider.dart';
import '../../domain/program_content/bundled_course.dart';
import '../../l10n/gen/app_localizations.dart';

/// What the student can do about an error (R-44).
enum ErrorAction {
  /// Trying again can fix it (no internet, busy server).
  retry,

  /// Trying again cannot fix it. The student must open the WhatsApp link
  /// again.
  signInAgain,

  /// Nothing the student can do. No button: someone else must fix it.
  none,
}

/// A plain message for a failed call. It never contains technical text.
class FriendlyError {
  FriendlyError({
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
FriendlyError describeError(Object error, AppLocalizations l) {
  if (error is ApiException) return _describeApiError(error, l);
  if (error is CourseNotBundledException) {
    return FriendlyError(
      title: l.errorCourseNotReadyTitle,
      message: l.errorCourseNotReadyMessage,
      buttonText: '',
      action: ErrorAction.none,
    );
  }
  if (error is AuthException || error is NoActiveProfileException) {
    return FriendlyError(
      title: l.errorSessionEndedTitle,
      message: l.errorSessionEndedMessage,
      buttonText: l.buttonOk,
      action: ErrorAction.signInAgain,
    );
  }
  if (error is RateLimitedException) {
    return FriendlyError(
      title: l.errorWaitTitle,
      message: l.errorWaitMessage,
      buttonText: l.buttonTryAgain,
      action: ErrorAction.retry,
    );
  }
  if (error is NoEnrollmentException || error is NoActiveEnrollmentException) {
    return FriendlyError(
      title: l.errorNoCourseTitle,
      message: l.errorNoCourseMessage,
      buttonText: l.buttonTryAgain,
      action: ErrorAction.retry,
    );
  }
  if (error is DioException && _isConnectionProblem(error)) {
    return FriendlyError(
      title: l.errorNoInternetTitle,
      message: l.errorNoInternetMessage,
      buttonText: l.buttonTryAgain,
      action: ErrorAction.retry,
    );
  }
  return FriendlyError(
    title: l.errorGenericTitle,
    message: l.errorGenericMessage,
    buttonText: l.buttonTryAgain,
    action: ErrorAction.retry,
  );
}

/// The Worker's error codes (`api-contract.md`). The Worker's own message is
/// for logs only, so none of it is shown.
FriendlyError _describeApiError(ApiException e, AppLocalizations l) {
  switch (e.code) {
    case 'UNAUTHORIZED':
      return describeError(AuthException(e.code), l);
    case 'RATE_LIMITED':
      return describeError(RateLimitedException('default'), l);
    case 'STUDENT_NOT_FOUND':
      return FriendlyError(
        title: l.errorNotFoundTitle,
        message: l.errorNotFoundMessage,
        buttonText: l.buttonTryAgain,
        action: ErrorAction.retry,
      );
    case 'CONFLICT':
      return FriendlyError(
        title: l.errorLimitTitle,
        message: l.errorLimitMessage,
        buttonText: l.buttonTryAgain,
        action: ErrorAction.retry,
      );
    default:
      return describeError(StateError(e.code), l);
  }
}

bool _isConnectionProblem(DioException e) =>
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.sendTimeout ||
    e.type == DioExceptionType.receiveTimeout;
