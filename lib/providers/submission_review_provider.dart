import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/submission_review_repository.dart';
import 'http_client_provider.dart';
import 'local_cache_provider.dart';

final submissionReviewRepositoryProvider =
    FutureProvider<SubmissionReviewRepository>((ref) async {
      final localCache = await ref.watch(localCacheProvider.future);
      return SubmissionReviewRepository(
        ref.watch(httpClientProvider),
        localCache,
      );
    });
