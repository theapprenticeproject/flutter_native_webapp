import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'magic_link_repository.dart';
import 'redeemed_student.dart';
import '../../core/network/http_client_provider.dart';
import '../../core/cache/local_cache_provider.dart';

final magicLinkRepositoryProvider = FutureProvider<MagicLinkRepository>((
  ref,
) async {
  final localCache = await ref.read(localCacheProvider.future);
  return MagicLinkRepository(
    ref.read(httpClientProvider),
    localCache,
    ref.read(secureTokenStoreProvider),
  );
});

/// The students on the phone, for the name picker.
final linkRosterProvider = FutureProvider.autoDispose<List<RedeemedStudent>>((
  ref,
) async {
  final repository = await ref.read(magicLinkRepositoryProvider.future);
  return repository.readRoster();
});
