import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/active_profile_model.dart';
import 'activity_models.dart';
import 'classroom_progress_stage.dart';
import '../learner/enrollment_model.dart';
import '../learner/learner_state_model.dart';
import '../program_content/course_detail_model.dart';
import '../learner/learner_state_provider.dart';
import '../profile/profile_provider.dart';
import '../program_content/program_content_provider.dart';
import '../submission/feedback_provider.dart';
import '../submission/feedback_state.dart';
import 'unit_feedback.dart';

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
  FeedbackStage? feedback,
}) {
  final snapshot = ClassroomProgressResolver.resolve(
    enrollment: enrollment,
    unitIndex: unitIndex,
    unit: unit,
    feedback: feedback,
  );

  return LearningProgress(
    studentName:
        learnerState.profile?.studentName ?? profile.studentName ?? 'Champ',
    points: learnerState.xp ?? 0,
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
      );
    }

    // The Worker says where the work stands (R-83). Valid feedback closes the
    // unit and the next unit becomes current.
    final learnerRepository = await ref.read(
      learnerStateRepositoryProvider.future,
    );
    final current = await currentUnitWithFeedback(
      tracker: await ref.read(feedbackTrackerProvider.future),
      learner: learnerRepository,
      learnerId: activeProfile.learnerId,
      state: learnerState,
      units: course.units,
    );
    learnerState = current.state;
    enrollment = learnerState.enrollment!;
    final unitIndex = current.unitIndex;
    final feedback = current.feedback;
    final courseUnit = course.units[unitIndex];
    var progress = _buildProgress(
      profile: activeProfile,
      learnerState: learnerState,
      enrollment: enrollment,
      unitIndex: unitIndex,
      unit: courseUnit,
      feedback: feedback,
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
        feedback: feedback,
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
      showCompletionCelebration: !allUnitsDone && celebration?['show'] == true,
      completionPoints: (celebration?['points'] as num?)?.toInt() ?? 0,
      feedback: feedback,
    );
  },
);
