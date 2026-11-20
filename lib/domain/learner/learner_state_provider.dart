import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'learner_state_model.dart';
import 'learner_state_repository.dart';
import '../../core/network/http_client_provider.dart';
import '../../core/cache/local_cache_provider.dart';
import '../progress/progress_provider.dart';
import '../program_content/bundled_course.dart';
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
      return resolveBundledCourse(serverCourseId, courses.map((c) => c.id));
    },
  );
});

final learnerStateDataProvider = FutureProvider.autoDispose
    .family<LearnerStateModel, String>((ref, learnerId) async {
      final repository = await ref.watch(learnerStateRepositoryProvider.future);
      var state = await repository.readCached(learnerId);
      if (state != null && state.enrollment != null) {
        // The Worker decides the course. If it changed, start the new one.
        final moved = await repository.followWorkerCourse(learnerId);
        if (moved != null) return repository.restoreLocalProgress(moved);
      } else {
        // A new browser: build the state from the login answer.
        state = await repository.fetchState(learnerId: learnerId);
      }
      // Ask the Worker where the student is (points, unit, steps), but never
      // wait long for it. A new browser needs this most: nothing is saved there.
      await repository
          .refreshPoints(learnerId)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      return repository.restoreLocalProgress(
        await repository.readCached(learnerId) ?? state,
      );
    });

Future<LearnerStateModel> refreshLearnerState(
  WidgetRef ref,
  String learnerId,
) async {
  final repository = await ref.read(learnerStateRepositoryProvider.future);
  return repository.fetchState(learnerId: learnerId, forceRefresh: true);
}
