import '../learner/enrollment_model.dart';
import '../program_content/course_detail_model.dart';
import '../submission/feedback_state.dart';

enum ClassroomProgressStage {
  watchVideo,
  submitProject,
  takeQuiz,

  /// The work is sent and the quiz is done, but the feedback is not valid yet
  /// (R-83): waiting, slow, or not valid.
  awaitingFeedback,

  /// The feedback is valid and the student has not seen it yet: the Results
  /// chat comes next (R-68). The unit closes after it.
  resultsReady,
  unitCompleted;

  double get revealProgress => switch (this) {
    ClassroomProgressStage.watchVideo => 0,
    ClassroomProgressStage.submitProject => 0.34,
    ClassroomProgressStage.takeQuiz => 0.67,
    ClassroomProgressStage.awaitingFeedback => 0.67,
    ClassroomProgressStage.resultsReady => 0.67,
    ClassroomProgressStage.unitCompleted => 1,
  };
}

class ClassroomProgressSnapshot {
  const ClassroomProgressSnapshot({
    required this.stage,
    required this.videoDone,
    required this.submissionDone,
    required this.quizDone,
    this.workSent = false,
  });

  final ClassroomProgressStage stage;
  final bool videoDone;
  final bool submissionDone;
  final bool quizDone;

  /// The Worker has a submission for this unit's assignment.
  final bool workSent;
}

class ClassroomProgressResolver {
  const ClassroomProgressResolver._();

  static int resolveUnitIndexForCourse(
    EnrollmentModel enrollment,
    List<CourseUnitModel> units,
  ) {
    if (units.isEmpty) return 0;
    for (var index = 0; index < units.length; index++) {
      final snapshot = resolve(
        enrollment: enrollment,
        unitIndex: index,
        unit: units[index],
      );
      if (snapshot.stage != ClassroomProgressStage.unitCompleted) {
        return index;
      }
    }
    return units.length - 1;
  }

  static ClassroomProgressSnapshot resolve({
    required EnrollmentModel enrollment,
    required int unitIndex,
    CourseUnitModel? unit,
    FeedbackStage? feedback,
  }) {
    final videoDone = enrollment.videosCompleted > unitIndex;
    final quizDone = enrollment.quizzesCompleted > unitIndex;
    final hasSubmission = unit == null || unit.assignments.isNotEmpty;
    final hasQuiz = unit == null || (unit.quiz?.questions.isNotEmpty ?? true);

    // With the Worker's feedback state, a unit is finished only when the
    // feedback is valid (R-83). Without it (never sent, or never checked) the
    // phone's own submission index counts.
    if (feedback != null && hasSubmission) {
      final sent = feedback != FeedbackStage.notSent;
      final valid = feedback.opensNextUnit;
      final stage = !videoDone
          ? ClassroomProgressStage.watchVideo
          : !sent
          ? ClassroomProgressStage.submitProject
          : hasQuiz && !quizDone
          ? ClassroomProgressStage.takeQuiz
          : !valid
          ? ClassroomProgressStage.awaitingFeedback
          : enrollment.submissionIndex > unitIndex
          ? ClassroomProgressStage.unitCompleted
          : ClassroomProgressStage.resultsReady;
      return ClassroomProgressSnapshot(
        stage: stage,
        videoDone: videoDone,
        submissionDone: valid && enrollment.submissionIndex > unitIndex,
        quizDone: !hasQuiz || quizDone,
        workSent: sent,
      );
    }

    final submissionDone = enrollment.submissionIndex > unitIndex;

    final stage = !videoDone
        ? ClassroomProgressStage.watchVideo
        : hasSubmission && !submissionDone
        ? ClassroomProgressStage.submitProject
        : hasQuiz && !quizDone
        ? ClassroomProgressStage.takeQuiz
        : ClassroomProgressStage.unitCompleted;

    return ClassroomProgressSnapshot(
      stage: stage,
      videoDone: videoDone,
      submissionDone: !hasSubmission || submissionDone,
      quizDone: !hasQuiz || quizDone,
      workSent: !hasSubmission || submissionDone,
    );
  }
}
