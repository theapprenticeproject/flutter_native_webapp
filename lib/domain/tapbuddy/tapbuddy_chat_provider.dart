import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_turn_model.dart';
import 'tapbuddy_chat_repository.dart';
import '../../core/network/http_client_provider.dart';
import '../../core/cache/local_cache_provider.dart';

final tapbuddyChatRepositoryProvider = FutureProvider<TapbuddyChatRepository>((
  ref,
) async {
  final localCache = await ref.watch(localCacheProvider.future);
  return TapbuddyChatRepository(ref.watch(httpClientProvider), localCache);
});

class ChatTranscriptRequest {
  const ChatTranscriptRequest({required this.phone, required this.learnerId});
  final String phone;
  final String learnerId;

  @override
  bool operator ==(Object other) =>
      other is ChatTranscriptRequest &&
      other.phone == phone &&
      other.learnerId == learnerId;

  @override
  int get hashCode => Object.hash(phone, learnerId);
}

final chatTranscriptDataProvider = FutureProvider.autoDispose
    .family<List<ChatTurnModel>, ChatTranscriptRequest>((ref, request) async {
      final repository = await ref.watch(tapbuddyChatRepositoryProvider.future);
      return repository.readTranscript(request.phone, request.learnerId);
    });
