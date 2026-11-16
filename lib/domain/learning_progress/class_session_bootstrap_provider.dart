import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'classroom_progress_stage.dart';
import '../learner/learner_state_model.dart';
import '../program_content/course_detail_model.dart';
import '../learner/learner_state_provider.dart';
import '../profile/profile_provider.dart';
import '../program_content/program_content_provider.dart';
import '../submission/feedback_provider.dart';
import '../submission/feedback_state.dart';
import 'unit_feedback.dart';

class NoActiveEnrollmentException implements Exception {
  const NoActiveEnrollmentException();

  @override
  String toString() => 'No active course enrollment for this profile.';
}

class ClassSessionBootstrap {
  const ClassSessionBootstrap({
    required this.learnerId,
    required this.phone,
    required this.learnerState,
    required this.courseName,
    required this.unit,
    required this.nextUnit,
    required this.unitIndex,
    this.feedback,
  });

  final String learnerId;
  final String phone;
  final LearnerStateModel learnerState;
  final String courseName;
  final CourseUnitModel? unit;
  final CourseUnitModel? nextUnit;
  final int unitIndex;

  /// Where the work for this unit stands, when the Worker said (R-83).
  final FeedbackStage? feedback;
}

final classSessionBootstrapProvider =
    FutureProvider.autoDispose<ClassSessionBootstrap>((ref) async {
      final activeProfile = await ref.watch(activeProfileProvider.future);
      if (activeProfile == null) {
        throw StateError('No active profile selected.');
      }

      final learnerStateRepository = await ref.watch(
        learnerStateRepositoryProvider.future,
      );

      var learnerState = await learnerStateRepository.fetchState(
        learnerId: activeProfile.learnerId,
      );

      if (learnerState.hasPendingLocalProgress) {
        final synced = await learnerStateRepository.syncCompletedLocalProgress(
          activeProfile.learnerId,
        );
        if (synced != null) learnerState = synced;
      }

      var enrollment = learnerState.enrollment;
      if (enrollment == null || enrollment.course == null) {
        throw const NoActiveEnrollmentException();
      }

      final course = await ref.watch(
        courseDetailDataProvider(enrollment.course!).future,
      );
      if (course.units.isEmpty) {
        return ClassSessionBootstrap(
          learnerId: activeProfile.learnerId,
          phone: activeProfile.phone,
          learnerState: learnerState,
          courseName: course.name,
          unit: null,
          nextUnit: null,
          unitIndex: 0,
        );
      }

      // The Worker says where the work stands (R-83). Valid feedback closes the
      // unit and the next unit becomes current.
      final current = await currentUnitWithFeedback(
        tracker: await ref.watch(feedbackTrackerProvider.future),
        learner: learnerStateRepository,
        learnerId: activeProfile.learnerId,
        state: learnerState,
        units: course.units,
      );
      learnerState = current.state;
      enrollment = learnerState.enrollment!;
      final feedback = current.feedback;
      final startIndex = current.unitIndex;
      final selectedUnit = course.units[startIndex];
      final nextUnit = startIndex + 1 < course.units.length
          ? course.units[startIndex + 1]
          : null;
      var selectedProgress = ClassroomProgressResolver.resolve(
        enrollment: enrollment,
        unitIndex: startIndex,
        unit: selectedUnit,
        feedback: feedback,
      );

      if (!learnerState.hasPendingLocalProgress &&
          selectedProgress.stage != ClassroomProgressStage.watchVideo &&
          selectedProgress.stage != ClassroomProgressStage.unitCompleted) {
        learnerState = await learnerStateRepository.prepareLocalUnit(
          learnerId: activeProfile.learnerId,
          unitIndex: startIndex,
        );
        enrollment = learnerState.enrollment!;
        selectedProgress = ClassroomProgressResolver.resolve(
          enrollment: enrollment,
          unitIndex: startIndex,
          unit: selectedUnit,
          feedback: feedback,
        );
      }
      if (selectedProgress.stage != ClassroomProgressStage.unitCompleted) {
        return ClassSessionBootstrap(
          learnerId: activeProfile.learnerId,
          phone: activeProfile.phone,
          learnerState: learnerState,
          courseName: course.name,
          unit: selectedUnit,
          nextUnit: nextUnit,
          unitIndex: startIndex,
          feedback: feedback,
        );
      }

      return ClassSessionBootstrap(
        learnerId: activeProfile.learnerId,
        phone: activeProfile.phone,
        learnerState: learnerState,
        courseName: course.name,
        unit: selectedUnit,
        nextUnit: nextUnit,
        unitIndex: startIndex,
        feedback: feedback,
      );
    });
