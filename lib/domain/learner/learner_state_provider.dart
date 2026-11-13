import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'learner_state_model.dart';
import 'learner_state_repository.dart';
import '../../core/network/http_client_provider.dart';
import '../../core/cache/local_cache_provider.dart';
import '../progress/progress_provider.dart';
import '../program_content/program_content_provider.dart';

final learnerStateRepositoryProvider = FutureProvider<LearnerStateRepository>((
  ref,
) async {
  final localCache = await ref.watch(localCacheProvider.future);
  return LearnerStateRepository(
    ref.watch(httpClientProvider),
    localCache,
    progress: ref.watch(progressRepositoryProvider),
    resolveCourse: (serverCourseId) async {
      final content = await ref.read(programContentRepositoryProvider.future);
      final courses = await content.fetchCourseIndex();
      if (courses.any((c) => c.id == serverCourseId)) return serverCourseId;
      return courses.isEmpty ? serverCourseId : courses.first.id;
    },
  );
});

final learnerStateDataProvider = FutureProvider.autoDispose
    .family<LearnerStateModel, String>((ref, learnerId) async {
      final repository = await ref.watch(learnerStateRepositoryProvider.future);
      final cached = await repository.readCached(learnerId);
      if (cached != null && cached.enrollment != null) {
        // Take the points from the Worker, but never wait long for it.
        await repository
            .refreshPoints(learnerId)
            .timeout(const Duration(seconds: 3), onTimeout: () {});
        return repository.restoreLocalProgress(
          await repository.readCached(learnerId) ?? cached,
        );
      }
      return repository.fetchState(learnerId: learnerId);
    });

Future<LearnerStateModel> refreshLearnerState(
  WidgetRef ref,
  String learnerId,
) async {
  final repository = await ref.read(learnerStateRepositoryProvider.future);
  return repository.fetchState(learnerId: learnerId, forceRefresh: true);
}
