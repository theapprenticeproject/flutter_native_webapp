import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../core/network/http_client.dart';
import '../auth/redeemed_student.dart';
import '../profile/learner_profile_fields_model.dart';
import '../progress/progress_repository.dart';
import 'enrollment_model.dart';
import 'learner_state_model.dart';

/// Picks the bundled course for a student. The Worker's `course_id` may not be
/// a bundled course yet, so the first bundled course is used then (test only).
typedef CourseResolver = Future<String?> Function(String? serverCourseId);

/// The learner state in v1.
///
/// It is built from the login answer (name, points, course). The unit and the
/// step the student is on are kept on the phone, because the app follows the
/// bundled course order. The Worker owns the points: they come from its answers.
class LearnerStateRepository {
  LearnerStateRepository(
    this._http,
    this._localCache, {
    ProgressRepository? progress,
    CourseResolver? resolveCourse,
  }) : _progress = progress,
       _resolveCourse = resolveCourse;

  // ignore: unused_field
  final HttpClient _http;
  final LocalCache _localCache;
  final ProgressRepository? _progress;
  final CourseResolver? _resolveCourse;

  Future<LearnerStateModel?> readCached(String learnerId) async {
    final raw = _localCache.getForeverRaw(CacheKeys.learnerState(learnerId));
    if (raw == null) return null;
    return LearnerStateModel.fromCache(raw);
  }

  /// The saved state, or a new one built from the login answer. With
  /// [forceRefresh] the points are asked from the Worker (`sync`) and the unit
  /// step on the phone is kept.
  Future<LearnerStateModel> fetchState({
    required String learnerId,
    bool forceRefresh = false,
  }) async {
    final cached = await readCached(learnerId);
    if (cached == null) return restoreLocalProgress(await _seed(learnerId));
    if (forceRefresh) await refreshPoints(learnerId);
    return restoreLocalProgress(await readCached(learnerId) ?? cached);
  }

  Future<LearnerStateModel> _seed(String learnerId) async {
    final roster = _localCache.getForeverList(
      CacheKeys.linkRoster(),
      RedeemedStudent.fromJson,
    );
    final student = roster?.where((s) => s.studentId == learnerId).firstOrNull;
    final course = await _resolveCourse?.call(student?.courseId);
    final model = LearnerStateModel(
      learnerId: learnerId,
      profile: LearnerProfileFieldsModel(
        studentName: student?.name,
        language: student?.language,
      ),
      xp: student?.points ?? 0,
      enrollment: EnrollmentModel(course: course ?? student?.courseId),
    );
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return model;
  }

  /// Takes the student's points from the Worker. A network problem keeps the
  /// saved points: the home screen must still open.
  Future<void> refreshPoints(String learnerId) async {
    final progress = _progress;
    if (progress == null) return;
    try {
      final sync = await progress.sync(lastUpdated: 0);
      final points = sync.points;
      if (points != null) await applyServerPoints(learnerId, points);
    } catch (_) {
      // Keep what we have.
    }
  }

  /// Saves the total the Worker gave in an answer.
  Future<void> applyServerPoints(String learnerId, int pointsTotal) async {
    final existing = await readCached(learnerId);
    if (existing == null) return;
    existing.xp = pointsTotal;
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      existing.toJson(),
    );
  }

  /// Finishes the unit on the phone. The steps were already recorded on the
  /// Worker one by one, so there is nothing to send here.
  Future<LearnerStateModel> completeUnitLocally(String learnerId) async {
    final model =
        await readCached(learnerId) ?? LearnerStateModel(learnerId: learnerId);
    await _localCache.delete(CacheKeys.activityProgress(learnerId));
    model.hasPendingLocalProgress = false;
    model.pendingProgressXp = 0;
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return model;
  }

  Future<LearnerStateModel> applyLocalProgress({
    required String learnerId,
    int xp = 0,
    int? videoIndex,
    int? quizIndex,
    int? submissionIndex,
  }) async {
    final cachedState = await readCached(learnerId);
    final existing = _localCache.getForeverRaw(
      CacheKeys.activityProgress(learnerId),
    );
    final requestedIndex = videoIndex ?? submissionIndex ?? quizIndex;
    if (requestedIndex == null || requestedIndex <= 0) {
      throw ArgumentError('A positive unit progress index is required.');
    }
    final unitIndex = requestedIndex - 1;
    final sameUnit = existing != null && _localUnitIndex(existing) == unitIndex;
    final progress = <String, dynamic>{
      if (sameUnit) ...existing,
      'learner_id': learnerId,
      'course': cachedState?.enrollment?.course,
      'unit_index': unitIndex,
      'video_done': sameUnit
          ? (existing['video_done'] == true ||
                ((existing['video_index'] as num?)?.toInt() ?? 0) > unitIndex)
          : false,
      'submission_done': sameUnit
          ? (existing['submission_done'] == true ||
                ((existing['submission_index'] as num?)?.toInt() ?? 0) >
                    unitIndex)
          : false,
      'quiz_done': sameUnit
          ? (existing['quiz_done'] == true ||
                ((existing['quiz_index'] as num?)?.toInt() ?? 0) > unitIndex)
          : false,
      'ready_to_sync': false,
    };
    if (videoIndex != null) {
      progress['video_done'] = true;
      progress['video_xp'] = xp;
    }
    if (submissionIndex != null) {
      progress['submission_done'] = true;
      progress['submission_xp'] = xp;
    }
    if (quizIndex != null) {
      progress['quiz_done'] = true;
      progress['quiz_xp'] = xp;
    }
    progress['pending_xp'] =
        ((progress['video_xp'] as num?)?.toInt() ?? 0) +
        ((progress['submission_xp'] as num?)?.toInt() ?? 0) +
        ((progress['quiz_xp'] as num?)?.toInt() ?? 0);
    await _localCache.setForeverRaw(
      CacheKeys.activityProgress(learnerId),
      progress,
    );

    return restoreLocalProgress(
      cachedState ?? LearnerStateModel(learnerId: learnerId),
    );
  }

  Future<LearnerStateModel> restoreLocalProgress(
    LearnerStateModel serverState,
  ) async {
    final progress = _localCache.getForeverRaw(
      CacheKeys.activityProgress(serverState.learnerId),
    );
    if (progress == null) return serverState;

    final pendingCourse = progress['course'] as String?;
    if (pendingCourse != serverState.enrollment?.course) {
      await _localCache.delete(
        CacheKeys.activityProgress(serverState.learnerId),
      );
      return serverState;
    }

    final unitIndex = _localUnitIndex(progress);
    if (unitIndex == null) return serverState;
    final existingEnrollment = serverState.enrollment;
    if (existingEnrollment == null) return serverState;

    final videoDone =
        progress['video_done'] == true ||
        ((progress['video_index'] as num?)?.toInt() ?? 0) > unitIndex;
    final submissionDone =
        progress['submission_done'] == true ||
        ((progress['submission_index'] as num?)?.toInt() ?? 0) > unitIndex;
    final quizDone =
        progress['quiz_done'] == true ||
        ((progress['quiz_index'] as num?)?.toInt() ?? 0) > unitIndex;
    serverState.enrollment = existingEnrollment.copyWith(
      videosCompleted: _max(
        existingEnrollment.videosCompleted,
        unitIndex + (videoDone ? 1 : 0),
      ),
      submissionIndex: _max(
        existingEnrollment.submissionIndex,
        unitIndex + (submissionDone ? 1 : 0),
      ),
      quizzesCompleted: _max(
        existingEnrollment.quizzesCompleted,
        unitIndex + (quizDone ? 1 : 0),
      ),
    );
    final model = serverState;
    model.hasPendingLocalProgress = true;
    model.pendingProgressXp = (progress['pending_xp'] as num?)?.toInt() ?? 0;
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(serverState.learnerId),
      model.toJson(),
    );
    return model;
  }

  int? _localUnitIndex(Map<String, dynamic> progress) {
    final explicit = (progress['unit_index'] as num?)?.toInt();
    if (explicit != null) return explicit;
    final indexes = [
      (progress['video_index'] as num?)?.toInt(),
      (progress['submission_index'] as num?)?.toInt(),
      (progress['quiz_index'] as num?)?.toInt(),
    ].whereType<int>().where((value) => value > 0).toList();
    if (indexes.isEmpty) return null;
    return indexes.reduce((a, b) => a < b ? a : b) - 1;
  }

  int _max(int a, int b) => a > b ? a : b;

  Future<LearnerStateModel> prepareLocalUnit({
    required String learnerId,
    required int unitIndex,
  }) async {
    final state = await readCached(learnerId);
    final enrollment = state?.enrollment;
    final submissionIndex = enrollment?.submissionIndex ?? 0;
    await _localCache.setForeverRaw(CacheKeys.activityProgress(learnerId), {
      'learner_id': learnerId,
      'course': enrollment?.course,
      'unit_index': unitIndex,
      'video_done': (enrollment?.videosCompleted ?? 0) > unitIndex,
      'submission_done': submissionIndex > unitIndex,
      'quiz_done': (enrollment?.quizzesCompleted ?? 0) > unitIndex,
      'pending_xp': 0,
      'ready_to_sync': false,
    });
    return restoreLocalProgress(
      state ?? LearnerStateModel(learnerId: learnerId),
    );
  }

  Future<void> markLocalProgressReady(String learnerId) async {
    final progress = _localCache.getForeverRaw(
      CacheKeys.activityProgress(learnerId),
    );
    if (progress == null) return;
    await _localCache.setForeverRaw(CacheKeys.activityProgress(learnerId), {
      ...progress,
      'ready_to_sync': true,
    });
  }

  Future<void> showHomeCelebration(String learnerId, {required int points}) =>
      _localCache.setForeverRaw(CacheKeys.homeCelebration(learnerId), {
        'show': true,
        'points': points,
      });

  Map<String, dynamic>? readHomeCelebration(String learnerId) =>
      _localCache.getForeverRaw(CacheKeys.homeCelebration(learnerId));

  Future<void> clearHomeCelebration(String learnerId) =>
      _localCache.delete(CacheKeys.homeCelebration(learnerId));

  /// A unit that was finished but not closed (the app stopped): close it now.
  Future<LearnerStateModel?> syncCompletedLocalProgress(
    String learnerId,
  ) async {
    final progress = _localCache.getForeverRaw(
      CacheKeys.activityProgress(learnerId),
    );
    if (progress == null || progress['ready_to_sync'] != true) return null;
    return completeUnitLocally(learnerId);
  }

  Future<void> applyAchievementAward(
    String learnerId,
    String achievement,
    String level,
  ) async {
    final existing = await readCached(learnerId);
    if (existing == null) return;
    existing.upsertAchievement(achievement, level);
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      existing.toJson(),
    );
  }

  Future<void> invalidate(String learnerId) =>
      _localCache.invalidateLearner(learnerId);
}
