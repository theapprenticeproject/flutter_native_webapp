import 'achievement_model.dart';
import 'enrollment_model.dart';
import '../profile/learner_profile_fields_model.dart';

class LearnerStateModel {
  LearnerStateModel({
    required this.learnerId,
    this.profile,
    this.xp,
    this.weeklyXp,
    this.xpDaily,
    this.level,
    this.submissionIndex,
    this.achievements,
    this.enrollment,
    this.hasPendingConflict = false,
    this.hasPendingLocalProgress = false,
    this.pendingProgressXp = 0,
  });

  final String learnerId;
  LearnerProfileFieldsModel? profile;
  int? xp;
  int? weeklyXp;
  List<int>? xpDaily;
  String? level;
  int? submissionIndex;
  List<AchievementModel>? achievements;
  EnrollmentModel? enrollment;
  bool hasPendingConflict;
  bool hasPendingLocalProgress;
  int pendingProgressXp;

  factory LearnerStateModel.fromFullJson(
    String learnerId,
    Map<String, dynamic> json,
  ) {
    final model = LearnerStateModel(learnerId: learnerId);
    return model._applyJson(json, full: true);
  }

  LearnerStateModel mergeFrom(Map<String, dynamic> json) =>
      _applyJson(json, full: false);

  LearnerStateModel _applyJson(
    Map<String, dynamic> json, {
    required bool full,
  }) {
    if (full || json.containsKey('profile')) {
      final p = json['profile'];
      profile = p is Map
          ? LearnerProfileFieldsModel.fromJson(Map<String, dynamic>.from(p))
          : profile;
    }
    if (full || json.containsKey('xp')) {
      xp = (json['xp'] as num?)?.toInt() ?? xp;
    }
    if (full || json.containsKey('weekly_xp')) {
      weeklyXp = (json['weekly_xp'] as num?)?.toInt() ?? weeklyXp;
    }
    if (full || json.containsKey('xp_daily')) {
      final raw = json['xp_daily'];
      if (raw is List) {
        xpDaily = raw.map((e) => (e as num).toInt()).toList(growable: false);
      }
    }
    if (full || json.containsKey('level')) {
      level = json['level'] as String? ?? level;
    }
    if (full || json.containsKey('submission_index')) {
      submissionIndex =
          (json['submission_index'] as num?)?.toInt() ?? submissionIndex;
    }
    if (full || json.containsKey('achievements')) {
      achievements = AchievementModel.listFromJson(json['achievements']);
    }
    if (full || json.containsKey('enrollment')) {
      final e = json['enrollment'];
      enrollment = e is Map
          ? EnrollmentModel.fromJson(Map<String, dynamic>.from(e))
          : enrollment;
    }
    if (json.containsKey('has_pending_local_progress')) {
      hasPendingLocalProgress =
          json['has_pending_local_progress'] as bool? ?? false;
    }
    if (json.containsKey('pending_progress_xp')) {
      pendingProgressXp = (json['pending_progress_xp'] as num?)?.toInt() ?? 0;
    }
    _syncProgressIntoEnrollment(json);
    return this;
  }

  void _syncProgressIntoEnrollment(Map<String, dynamic> json) {
    final existing = enrollment ?? const EnrollmentModel();

    final videoIndex = (json['video_index'] as num?)?.toInt();
    final videosCompleted = (json['videos_completed'] as num?)?.toInt();
    final quizIndex = (json['quiz_index'] as num?)?.toInt();
    final quizzesCompleted = (json['quizzes_completed'] as num?)?.toInt();
    final courseSubmissionIndex =
        (json['course_submission_index'] as num?)?.toInt();

    final nextVideosCompleted = [
      existing.videosCompleted,
      ?videoIndex,
      ?videosCompleted,
    ].reduce((a, b) => a > b ? a : b);
    final nextQuizzesCompleted = [
      existing.quizzesCompleted,
      ?quizIndex,
      ?quizzesCompleted,
    ].reduce((a, b) => a > b ? a : b);
    final nextSubmissionIndex = [
      existing.submissionIndex,
      ?courseSubmissionIndex,
    ].reduce((a, b) => a > b ? a : b);

    enrollment = existing.copyWith(
      videosCompleted: nextVideosCompleted,
      quizzesCompleted: nextQuizzesCompleted,
      submissionIndex: nextSubmissionIndex,
    );
  }

  void upsertAchievement(String achievement, String level) {
    final list = List<AchievementModel>.from(achievements ?? const []);
    final idx = list.indexWhere((a) => a.achievement == achievement);
    final entry = AchievementModel(achievement: achievement, level: level);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    achievements = list;
  }

  Map<String, dynamic> toJson() => {
    'learner_id': learnerId,
    'profile': profile?.toJson(),
    'xp': xp,
    'weekly_xp': weeklyXp,
    'xp_daily': xpDaily,
    'level': level,
    'submission_index': submissionIndex,
    'achievements': achievements == null
        ? null
        : AchievementModel.listToJson(achievements!),
    'enrollment': enrollment?.toJson(),
    'has_pending_conflict': hasPendingConflict,
    'has_pending_local_progress': hasPendingLocalProgress,
    'pending_progress_xp': pendingProgressXp,
  };

  factory LearnerStateModel.fromCache(Map<String, dynamic> json) {
    final model = LearnerStateModel(learnerId: json['learner_id'] as String);
    model._applyJson(json, full: true);
    model.hasPendingConflict = json['has_pending_conflict'] as bool? ?? false;
    return model;
  }
}
