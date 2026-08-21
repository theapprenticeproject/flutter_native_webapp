import 'achievement_model.dart';
import 'enrollment_model.dart';
import 'learner_profile_fields_model.dart';

const int weeklyActivityLimit = 2;

class LearnerStateModel {
  LearnerStateModel({
    required this.learnerId,
    this.profile,
    this.xp,
    this.weeklyXp,
    this.xpDaily,
    this.level,
    this.streak,
    this.longestStreak,
    this.lastActivityDate,
    this.unitsCompletedThisWeek,
    this.maxWeeklyUnits,
    this.isBingeing,
    this.windowStartDate,
    this.windowResetsOn,
    this.unitsRemaining,
    this.archetype,
    this.submissionGems,
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
  int? streak;
  int? longestStreak;
  String? lastActivityDate;
  int? unitsCompletedThisWeek;
  int? maxWeeklyUnits;
  bool? isBingeing;
  String? windowStartDate;
  String? windowResetsOn;
  int? unitsRemaining;
  String? archetype;
  int? submissionGems;
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
    if (full || json.containsKey('streak')) {
      streak = (json['streak'] as num?)?.toInt() ?? streak;
    }
    if (full || json.containsKey('longest_streak')) {
      longestStreak =
          (json['longest_streak'] as num?)?.toInt() ?? longestStreak;
    }
    if (full || json.containsKey('last_activity_date')) {
      lastActivityDate =
          json['last_activity_date'] as String? ?? lastActivityDate;
    }
    if (full ||
        json.containsKey('units_completed_this_week') ||
        json.containsKey('activities_watched_this_week')) {
      unitsCompletedThisWeek =
          (json['units_completed_this_week'] as num?)?.toInt() ??
          (json['activities_watched_this_week'] as num?)?.toInt() ??
          unitsCompletedThisWeek;
    }
    if (full ||
        json.containsKey('max_weekly_units') ||
        json.containsKey('max_weekly_activities')) {
      maxWeeklyUnits =
          (json['max_weekly_units'] as num?)?.toInt() ??
          (json['max_weekly_activities'] as num?)?.toInt() ??
          maxWeeklyUnits;
    }
    if (full || json.containsKey('is_bingeing')) {
      isBingeing = json['is_bingeing'] as bool? ?? isBingeing;
    }
    if (full || json.containsKey('window_start_date')) {
      windowStartDate = json['window_start_date'] as String? ?? windowStartDate;
    }
    if (full || json.containsKey('window_resets_on')) {
      windowResetsOn = json['window_resets_on'] as String? ?? windowResetsOn;
    }
    if (full ||
        json.containsKey('units_remaining') ||
        json.containsKey('activities_remaining')) {
      unitsRemaining =
          (json['units_remaining'] as num?)?.toInt() ??
          (json['activities_remaining'] as num?)?.toInt() ??
          unitsRemaining;
    }
    if (full || json.containsKey('archetype')) {
      archetype = json['archetype'] as String? ?? archetype;
    }
    if (full || json.containsKey('submission_gems')) {
      submissionGems =
          (json['submission_gems'] as num?)?.toInt() ?? submissionGems;
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
    'streak': streak,
    'longest_streak': longestStreak,
    'last_activity_date': lastActivityDate,
    'units_completed_this_week': unitsCompletedThisWeek,
    'max_weekly_units': maxWeeklyUnits,
    'is_bingeing': isBingeing,
    'window_start_date': windowStartDate,
    'window_resets_on': windowResetsOn,
    'units_remaining': unitsRemaining,
    'archetype': archetype,
    'submission_gems': submissionGems,
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

extension LearnerStateWeeklyLimit on LearnerStateModel {
  bool hasReachedWeeklyActivityLimit({int localCompleted = 0}) {
    final serverCompleted = unitsCompletedThisWeek ?? 0;
    final completed = serverCompleted > localCompleted
        ? serverCompleted
        : localCompleted;
    final remaining = unitsRemaining;
    return (isBingeing ?? false) ||
        (remaining != null && remaining <= 0) ||
        completed >= weeklyActivityLimit;
  }
}
