import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/active_profile_model.dart';
import '../models/activity_models.dart';
import '../models/classroom_progress_stage.dart';
import '../models/enrollment_model.dart';
import '../models/learner_state_model.dart';
import '../models/program_content/course_detail_model.dart';
import 'class_session_bootstrap_provider.dart';
import 'learner_state_provider.dart';
import 'profile_provider.dart';
import 'program_content_provider.dart';

class NoActiveProfileException implements Exception {
  const NoActiveProfileException();

  @override
  String toString() => 'No active profile is selected.';
}

class NoEnrollmentException implements Exception {
  const NoEnrollmentException();

  @override
  String toString() => 'This profile has no active course enrollment.';
}

LearningProgress _buildProgress({
  required ActiveProfileModel profile,
  required LearnerStateModel learnerState,
  required EnrollmentModel enrollment,
  required int unitIndex,
  CourseUnitModel? unit,
}) {
  final snapshot = ClassroomProgressResolver.resolve(
    enrollment: enrollment,
    unitIndex: unitIndex,
    unit: unit,
  );

  return LearningProgress(
    studentName:
        learnerState.profile?.studentName ?? profile.studentName ?? 'Champ',
    points: learnerState.xp ?? 0,
    skillGems: learnerState.submissionGems ?? 0,
    streakDay: learnerState.streak ?? 0,
    videoDone: snapshot.videoDone,
    submissionDone: snapshot.submissionDone,
    quizDone: snapshot.quizDone,
    classroomStage: snapshot.stage,
  );
}

final learningDashboardProvider = FutureProvider.autoDispose<LearningDashboard>(
  (ref) async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) {
      throw const NoActiveProfileException();
    }

    var learnerState = await ref.watch(
      learnerStateDataProvider(activeProfile.learnerId).future,
    );
    final sessionWindowRepository = await ref.watch(
      classSessionWindowRepositoryProvider.future,
    );
    final localCompleted = sessionWindowRepository.completedUnitCountThisWindow(
      activeProfile.learnerId,
      learnerState.windowStartDate,
    );
    final hasReachedWeeklyCap = learnerState.hasReachedWeeklyActivityLimit(
      localCompleted: localCompleted,
    );

    var enrollment = learnerState.enrollment;
    if (enrollment == null || enrollment.course == null) {
      return LearningDashboard(
        progress: _buildProgress(
          profile: activeProfile,
          learnerState: learnerState,
          enrollment: const EnrollmentModel(),
          unitIndex: 0,
        ),
        unit: null,
        hasEnrollment: false,
        hasReachedWeeklyCap: hasReachedWeeklyCap,
      );
    }

    final course = await ref.watch(
      courseDetailDataProvider(enrollment.course!).future,
    );

    if (course.units.isEmpty) {
      return LearningDashboard(
        progress: _buildProgress(
          profile: activeProfile,
          learnerState: learnerState,
          enrollment: enrollment,
          unitIndex: 0,
        ),
        unit: null,
        hasEnrollment: true,
        hasReachedWeeklyCap: hasReachedWeeklyCap,
      );
    }

    final unitIndex = ClassroomProgressResolver.resolveUnitIndexForCourse(
      enrollment,
      course.units,
    );
    final courseUnit = course.units[unitIndex];
    var progress = _buildProgress(
      profile: activeProfile,
      learnerState: learnerState,
      enrollment: enrollment,
      unitIndex: unitIndex,
      unit: courseUnit,
    );

    if (!learnerState.hasPendingLocalProgress &&
        progress.classroomStage != ClassroomProgressStage.watchVideo &&
        progress.classroomStage != ClassroomProgressStage.unitCompleted) {
      final repository = await ref.read(learnerStateRepositoryProvider.future);
      learnerState = await repository.prepareLocalUnit(
        learnerId: activeProfile.learnerId,
        unitIndex: unitIndex,
      );
      enrollment = learnerState.enrollment!;
      progress = _buildProgress(
        profile: activeProfile,
        learnerState: learnerState,
        enrollment: enrollment,
        unitIndex: unitIndex,
        unit: courseUnit,
      );
    }

    final allUnitsDone =
        unitIndex >= course.units.length - 1 &&
        progress.videoDone &&
        progress.submissionDone &&
        progress.quizDone;
    final learnerStateRepository = await ref.read(
      learnerStateRepositoryProvider.future,
    );
    final celebration = learnerStateRepository.readHomeCelebration(
      activeProfile.learnerId,
    );

    return LearningDashboard(
      progress: progress,
      unit: allUnitsDone ? null : CourseUnit.fromCourse(course, unitIndex),
      hasEnrollment: true,
      hasReachedWeeklyCap: hasReachedWeeklyCap,
      showCompletionCelebration:
          !allUnitsDone && !hasReachedWeeklyCap && celebration?['show'] == true,
      completionPoints: (celebration?['points'] as num?)?.toInt() ?? 0,
    );
  },
);
