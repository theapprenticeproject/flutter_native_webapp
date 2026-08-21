import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../models/chat_turn_model.dart';
import '../remote/api_endpoints.dart';
import '../remote/http_client.dart';

class TapbuddyChatRepository {
  TapbuddyChatRepository(this._http, this._localCache);

  final HttpClient _http;
  final LocalCache _localCache;

  static const int _maxHistoryMessages = 12;

  Future<List<ChatTurnModel>> readTranscript(
    String phone,
    String learnerId,
  ) async {
    final raw = _localCache.getForeverList(
      CacheKeys.chatTranscript(phone, learnerId),
      (json) => json,
    );
    return raw == null ? const [] : ChatTurnModel.listFromJson(raw);
  }

  Future<String> sendMessage({
    required String phone,
    required String learnerId,
    required String message,
    String? grade,
    String? language,
    Map<String, dynamic>? context,
  }) async {
    final key = CacheKeys.chatTranscript(phone, learnerId);
    final history = await readTranscript(phone, learnerId);
    final recentHistory = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;

    final data = await _http.post(
      ApiEndpoints.tapbuddyChat,
      body: {
        'phone': phone,
        'learner_id': learnerId,
        'message': message,
        'grade': ?grade,
        'language': ?language,
        if (context != null && context.isNotEmpty) 'context': context,
        'history': ChatTurnModel.listToJson(recentHistory),
      },
    );

    final reply = data['reply'] as String? ?? '';

    final updated = [
      ...history,
      ChatTurnModel.user(message),
      ChatTurnModel.assistant(reply),
    ];
    await _localCache.setForeverRawList(key, ChatTurnModel.listToJson(updated));

    return reply;
  }

  Future<void> clearTranscript(String phone, String learnerId) async {
    await _localCache.delete(CacheKeys.chatTranscript(phone, learnerId));
  }
}
