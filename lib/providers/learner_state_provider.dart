import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learner_state_model.dart';
import '../data/repositories/learner_state_repository.dart';
import 'http_client_provider.dart';
import 'local_cache_provider.dart';

final learnerStateRepositoryProvider = FutureProvider<LearnerStateRepository>((
  ref,
) async {
  final localCache = await ref.watch(localCacheProvider.future);
  return LearnerStateRepository(ref.watch(httpClientProvider), localCache);
});

final learnerStateDataProvider = FutureProvider.autoDispose
    .family<LearnerStateModel, String>((ref, learnerId) async {
      final repository = await ref.watch(learnerStateRepositoryProvider.future);
      final cached = await repository.readCached(learnerId);
      if (cached != null && cached.enrollment != null) {
        return repository.restoreLocalProgress(cached);
      }
      return repository.fetchState(
        learnerId: learnerId,
        forceRefresh: cached != null,
      );
    });

Future<LearnerStateModel> refreshLearnerState(
  WidgetRef ref,
  String learnerId,
) async {
  final repository = await ref.read(learnerStateRepositoryProvider.future);
  return repository.fetchState(learnerId: learnerId, forceRefresh: true);
}
