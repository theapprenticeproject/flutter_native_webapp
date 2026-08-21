import '../models/program_content/course_detail_model.dart';
import 'classroom_progress_stage.dart';

enum LearningStage { startActivity, sendProject, quizPending, completed }

extension LearningStageClassroomMapper on ClassroomProgressStage {
  LearningStage get homeStage => switch (this) {
    ClassroomProgressStage.watchVideo => LearningStage.startActivity,
    ClassroomProgressStage.submitProject => LearningStage.sendProject,
    ClassroomProgressStage.takeQuiz => LearningStage.quizPending,
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
    required this.skillGems,
    required this.streakDay,
    required this.videoDone,
    required this.submissionDone,
    required this.quizDone,
    required this.classroomStage,
  });

  final String studentName;
  final int points;
  final int skillGems;
  final int streakDay;
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
    required this.hasReachedWeeklyCap,
    this.showCompletionCelebration = false,
    this.completionPoints = 0,
  });

  final LearningProgress progress;
  final CourseUnit? unit;
  final bool hasEnrollment;
  final bool hasReachedWeeklyCap;
  final bool showCompletionCelebration;
  final int completionPoints;
}
