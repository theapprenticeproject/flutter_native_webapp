import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/local_cache_provider.dart';
import 'feedback_tracker.dart';
import 'submission_provider.dart';

final feedbackTrackerProvider = FutureProvider<FeedbackTracker>((ref) async {
  final cache = await ref.watch(localCacheProvider.future);
  return FeedbackTracker(ref.watch(submissionRepositoryProvider), cache);
});
