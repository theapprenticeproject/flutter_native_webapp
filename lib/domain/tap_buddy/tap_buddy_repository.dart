import '../../core/network/http_client.dart';

/// Ask TAP: `POST /tapbuddy/chat` (API reference v7, section 7). The Worker keeps
/// the conversation for the student for about 10 idle minutes, so the app sends
/// only the new message. `context` is free: the app says which screen the
/// student is on. The Worker answers `INVALID_INPUT` (empty message),
/// `RATE_LIMITED` and `UPSTREAM_ERROR` (safe to retry).
class TapBuddyRepository {
  TapBuddyRepository(this._http);

  final HttpClient _http;

  Future<String> ask(
    String message, {
    required Map<String, Object?> context,
  }) async {
    final data = await _http.postApi(
      '/tapbuddy/chat',
      body: {'message': message, 'context': context},
    );
    return (data['reply'] as String?)?.trim() ?? '';
  }
}
