import 'enrollment_model.dart';
import 'program_content/course_detail_model.dart';

enum ClassroomProgressStage {
  watchVideo,
  submitProject,
  takeQuiz,
  unitCompleted;

  double get revealProgress => switch (this) {
    ClassroomProgressStage.watchVideo => 0,
    ClassroomProgressStage.submitProject => 0.34,
    ClassroomProgressStage.takeQuiz => 0.67,
    ClassroomProgressStage.unitCompleted => 1,
  };
}

class ClassroomProgressSnapshot {
  const ClassroomProgressSnapshot({
    required this.stage,
    required this.videoDone,
    required this.submissionDone,
    required this.quizDone,
  });

  final ClassroomProgressStage stage;
  final bool videoDone;
  final bool submissionDone;
  final bool quizDone;

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
  }) {
    final videoDone = enrollment.videosCompleted > unitIndex;
    final submissionDone = enrollment.submissionIndex > unitIndex;
    final quizDone = enrollment.quizzesCompleted > unitIndex;
    final hasSubmission = unit == null || unit.assignments.isNotEmpty;
    final hasQuiz = unit == null || (unit.quiz?.questions.isNotEmpty ?? true);

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
    );
  }
}
