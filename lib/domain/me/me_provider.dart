import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../learner/learner_state_provider.dart';
import '../learning_progress/home_dashboard_provider.dart';
import '../profile/profile_provider.dart';
import '../program_content/course_detail_model.dart';
import '../program_content/program_content_provider.dart';
import '../progress/app_config_provider.dart';
import '../progress/progress_models.dart';
import '../submission/feedback_provider.dart';
import '../submission/submission_provider.dart';
import 'level.dart';
import 'my_projects.dart';

/// What the Me page shows.
class MeData {
  const MeData({
    required this.studentName,
    required this.grade,
    required this.school,
    required this.subject,
    required this.points,
    required this.level,
    required this.projects,
  });

  final String studentName;
  final String grade;
  final String? school;

  /// The course the student is on (the "subject" of the profile card).
  final String? subject;
  final int points;
  final LevelProgress? level;
  final List<MyProject> projects;
}

/// Gathers the Me page data. The points, the tiers and the submissions come
/// from the Worker. If the Worker cannot be reached, the page still opens: the
/// level is left out, and the projects use the states saved on the phone.
final meDataProvider = FutureProvider.autoDispose<MeData>((ref) async {
  final profile = await ref.watch(activeProfileProvider.future);
  if (profile == null) throw const NoActiveProfileException();

  final state = await ref.watch(
    learnerStateDataProvider(profile.learnerId).future,
  );
  final roster = await ref.watch(linkRosterProvider.future);
  final student = roster
      .where((s) => s.studentId == profile.learnerId)
      .firstOrNull;
  final points = state.xp ?? 0;

  List<PointTier> tiers = const [];
  try {
    tiers = (await ref.watch(appConfigProvider.future)).pointTiers;
  } catch (_) {
    // No level to show.
  }

  List<CourseUnitModel> units = const [];
  final course = state.enrollment?.course;
  if (course != null) {
    units = (await ref.watch(courseDetailDataProvider(course).future)).units;
  }

  final tracker = await ref.watch(feedbackTrackerProvider.future);
  List<SubmissionInfo>? submissions;
  try {
    submissions = await ref.read(submissionRepositoryProvider).list();
  } catch (_) {
    submissions = null; // The saved states are used.
  }

  return MeData(
    studentName: state.profile?.studentName ?? profile.studentName ?? 'Champ',
    grade: student?.grade ?? profile.grade ?? '',
    school: student?.schoolName,
    subject: (await ref.watch(
      courseNameByIdProvider.future,
    ))[student?.courseId],
    points: points,
    level: levelProgress(points, tiers),
    projects: buildProjects(
      units,
      submissions,
      savedStage: (aid) => tracker.cached(profile.learnerId, aid)?.stage,
    ),
  );
});
