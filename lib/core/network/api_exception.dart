/// An error answer from the Worker: `{"ok": false, "error": {code, message}}`.
///
/// The [code] is one of the Worker's codes (for example `UNAUTHORIZED`,
/// `STUDENT_NOT_FOUND`, `CONFLICT`). The [message] is for logs only and is
/// never shown to a student (R-44).
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status});

  final String code;
  final String message;
  final int? status;

  @override
  String toString() => 'ApiException($code, $status)';
}
