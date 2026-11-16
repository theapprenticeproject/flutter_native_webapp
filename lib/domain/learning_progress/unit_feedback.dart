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
/// was saved. When the feedback is valid and the quiz is done, it also closes
/// the unit on the phone, so the next unit can open.
Future<FeedbackStage?> loadUnitFeedback({
  required FeedbackTracker tracker,
  required LearnerStateRepository learner,
  required String learnerId,
  required CourseUnitModel unit,
  required int unitIndex,
  required bool videoDone,
  required bool quizDone,
}) async {
  final assignmentId = unit.assignments.firstOrNull?.assignmentId ?? '';
  if (assignmentId.isEmpty || !videoDone) return null;

  final check = await tracker.check(learnerId, assignmentId);
  final stage = check?.stage;
  if (stage == FeedbackStage.valid && quizDone) {
    await learner.applyValidFeedback(learnerId, unitIndex: unitIndex);
  }
  return stage;
}

/// The unit the student is on, with where its work stands.
typedef UnitWithFeedback = ({
  int unitIndex,
  FeedbackStage? feedback,
  LearnerStateModel state,
});

/// Picks the current unit, asks the Worker about its work, and moves on to the
/// next unit when the feedback is valid and the unit is closed (R-83).
Future<UnitWithFeedback> currentUnitWithFeedback({
  required FeedbackTracker tracker,
  required LearnerStateRepository learner,
  required String learnerId,
  required LearnerStateModel state,
  required List<CourseUnitModel> units,
}) async {
  var enrollment = state.enrollment ?? const EnrollmentModel();
  var index = ClassroomProgressResolver.resolveUnitIndexForCourse(
    enrollment,
    units,
  );
  final quizDone = enrollment.quizzesCompleted > index;
  final feedback = await loadUnitFeedback(
    tracker: tracker,
    learner: learner,
    learnerId: learnerId,
    unit: units[index],
    unitIndex: index,
    videoDone: enrollment.videosCompleted > index,
    quizDone: quizDone,
  );

  if (feedback == FeedbackStage.valid && quizDone) {
    // The unit is closed on the phone: read the new state and move on.
    final closed = await learner.readCached(learnerId) ?? state;
    enrollment = closed.enrollment ?? enrollment;
    index = ClassroomProgressResolver.resolveUnitIndexForCourse(
      enrollment,
      units,
    );
    return (unitIndex: index, feedback: null, state: closed);
  }
  return (unitIndex: index, feedback: feedback, state: state);
}
