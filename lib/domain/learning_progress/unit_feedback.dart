import '../learner/enrollment_model.dart';
import '../learner/learner_state_model.dart';
import '../learner/learner_state_repository.dart';
import 'classroom_progress_stage.dart';
import '../program_content/course_detail_model.dart';
import '../submission/feedback_state.dart';
import '../submission/feedback_tracker.dart';

/// Asks the Worker where the work for this unit stands (R-83).
///
/// Returns null when there is nothing to ask (the video is not watched yet, or
/// the unit has no assignment) or when the Worker cannot be reached and nothing
/// was saved. It never closes the unit: valid feedback first goes through the
/// Results chat (R-68), which then calls `applyValidFeedback`.
Future<FeedbackStage?> loadUnitFeedback({
  required FeedbackTracker tracker,
  required LearnerStateRepository learner,
  required String learnerId,
  required CourseUnitModel unit,
  required int unitIndex,
  required bool videoDone,
}) async {
  final assignmentId = unit.assignments.firstOrNull?.assignmentId ?? '';
  if (assignmentId.isEmpty || !videoDone) return null;

  return (await tracker.check(learnerId, assignmentId))?.stage;
}

/// The unit the student is on, with where its work stands.
typedef UnitWithFeedback = ({
  int unitIndex,
  FeedbackStage? feedback,
  LearnerStateModel state,
});

/// Picks the current unit and asks the Worker about its work. Valid feedback
/// does not move on to the next unit by itself: the unit stays current until
/// the student has seen the Results chat (R-68, R-83).
Future<UnitWithFeedback> currentUnitWithFeedback({
  required FeedbackTracker tracker,
  required LearnerStateRepository learner,
  required String learnerId,
  required LearnerStateModel state,
  required List<CourseUnitModel> units,
}) async {
  // The Worker says where the student is (an unknown unit id throws).
  state = await learner.alignToWorkerUnit(learnerId, units);
  final enrollment = state.enrollment ?? const EnrollmentModel();
  final index = ClassroomProgressResolver.resolveUnitIndexForCourse(
    enrollment,
    units,
  );
  final feedback = await loadUnitFeedback(
    tracker: tracker,
    learner: learner,
    learnerId: learnerId,
    unit: units[index],
    unitIndex: index,
    videoDone: enrollment.videosCompleted > index,
  );
  return (unitIndex: index, feedback: feedback, state: state);
}
