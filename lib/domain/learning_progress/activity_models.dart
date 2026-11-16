import '../program_content/course_detail_model.dart';
import '../submission/feedback_state.dart';
import 'classroom_progress_stage.dart';

enum LearningStage {
  startActivity,
  sendProject,
  quizPending,

  /// The work is sent. The student waits for valid feedback (R-4, R-83).
  submissionPending,

  /// The feedback is valid. Home invites the student to see it (R-68).
  feedbackReady,
  completed,
}

extension LearningStageClassroomMapper on ClassroomProgressStage {
  LearningStage get homeStage => switch (this) {
    ClassroomProgressStage.watchVideo => LearningStage.startActivity,
    ClassroomProgressStage.submitProject => LearningStage.sendProject,
    ClassroomProgressStage.takeQuiz => LearningStage.quizPending,
    ClassroomProgressStage.awaitingFeedback => LearningStage.submissionPending,
    ClassroomProgressStage.resultsReady => LearningStage.feedbackReady,
    ClassroomProgressStage.unitCompleted => LearningStage.completed,
  };
}

class CourseUnit {
  const CourseUnit({
    required this.courseDisplay,
    required this.unitName,
    required this.thumbnailAsset,
    required this.videoPoints,
    required this.submissionPoints,
    required this.totalPoints,
  });

  final String courseDisplay;
  final String unitName;
  final String thumbnailAsset;
  final int videoPoints;
  final int submissionPoints;
  final int totalPoints;

  factory CourseUnit.fromCourse(CourseDetailModel course, int unitIndex) {
    final unit = course.units[unitIndex];
    final video = unit.videos.isNotEmpty ? unit.videos.first : null;
    return CourseUnit(
      courseDisplay: course.vertical.isNotEmpty ? course.vertical : course.name,
      unitName: unit.name,
      thumbnailAsset: 'assets/data/courses/thumbnail/${course.id}.webp',
      videoPoints: video?.points ?? unit.xp,
      submissionPoints: unit.xp,
      totalPoints: unit.xp,
    );
  }
}

class LearningProgress {
  const LearningProgress({
    required this.studentName,
    required this.points,
    required this.videoDone,
    required this.submissionDone,
    required this.quizDone,
    required this.classroomStage,
  });

  final String studentName;
  final int points;
  final bool videoDone;
  final bool submissionDone;
  final bool quizDone;
  final ClassroomProgressStage classroomStage;

  LearningStage get currentStage => classroomStage.homeStage;
}

class LearningDashboard {
  const LearningDashboard({
    required this.progress,
    required this.unit,
    required this.hasEnrollment,
    this.showCompletionCelebration = false,
    this.completionPoints = 0,
    this.feedback,
  });

  final LearningProgress progress;
  final CourseUnit? unit;
  final bool hasEnrollment;
  final bool showCompletionCelebration;
  final int completionPoints;

  /// Where the work for this unit stands, when the Worker said (R-83).
  final FeedbackStage? feedback;
}
