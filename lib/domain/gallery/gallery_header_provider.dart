import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learner/learner_state_provider.dart';
import '../learning_progress/classroom_progress_stage.dart';
import '../learning_progress/home_dashboard_provider.dart';
import '../profile/profile_provider.dart';
import '../program_content/program_content_provider.dart';
import '../progress/progress_models.dart';
import '../submission/feedback_provider.dart';
import '../submission/feedback_state.dart';
import '../submission/submission_provider.dart';

/// The top of the Gallery: this activity and the student's own work.
class GalleryHeader {
  const GalleryHeader({
    required this.activityTitle,
    required this.shared,
    required this.ownWorkUrl,
  });

  final String? activityTitle;

  /// The student has sent work for this activity.
  final bool shared;

  /// A link to the student's own work, when the Worker gave one.
  final String? ownWorkUrl;
}

final galleryHeaderProvider = FutureProvider.autoDispose<GalleryHeader>((
  ref,
) async {
  final profile = await ref.watch(activeProfileProvider.future);
  if (profile == null) throw const NoActiveProfileException();

  final state = await ref.watch(
    learnerStateDataProvider(profile.learnerId).future,
  );
  final course = state.enrollment?.course;
  if (course == null) {
    return const GalleryHeader(
      activityTitle: null,
      shared: false,
      ownWorkUrl: null,
    );
  }
  final units = (await ref.watch(
    courseDetailDataProvider(course).future,
  )).units;
  if (units.isEmpty) {
    return const GalleryHeader(
      activityTitle: null,
      shared: false,
      ownWorkUrl: null,
    );
  }

  final index = ClassroomProgressResolver.resolveUnitIndexForCourse(
    state.enrollment!,
    units,
  );
  final unit = units[index];
  final assignmentId = unit.assignments.firstOrNull?.assignmentId ?? '';

  SubmissionInfo? latest;
  var known = true;
  try {
    latest = latestFor(
      assignmentId,
      await ref.read(submissionRepositoryProvider).list(),
    );
  } catch (_) {
    known = false;
  }
  // The Worker could not be reached: use the state saved on the phone.
  var shared = latest != null;
  if (!known && assignmentId.isNotEmpty) {
    final tracker = await ref.watch(feedbackTrackerProvider.future);
    final saved = tracker.cached(profile.learnerId, assignmentId)?.stage;
    shared = saved != null && saved != FeedbackStage.notSent;
  }

  return GalleryHeader(
    activityTitle: unit.name,
    shared: shared,
    ownWorkUrl: latest?.viewUrl,
  );
});
