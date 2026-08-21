import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../models/learner_state_model.dart';
import '../remote/api_endpoints.dart';
import '../remote/http_client.dart';

const completedUnitStateFields =
    'profile,xp,level,streak,window,archetype,submission,enrollment,achievements';

class ProgressConflictException implements Exception {
  ProgressConflictException(this.responseBody);
  final Map<String, dynamic> responseBody;

  @override
  String toString() =>
      'ProgressConflictException(learner progress write was rejected — local state left untouched)';
}

class ProgressNotRecordedException implements Exception {
  ProgressNotRecordedException(this.responseBody);
  final Map<String, dynamic> responseBody;

  @override
  String toString() =>
      'ProgressNotRecordedException(learner progress write was not recorded)';
}

class LearnerStateRepository {
  LearnerStateRepository(this._http, this._localCache);

  final HttpClient _http;
  final LocalCache _localCache;

  Future<LearnerStateModel?> readCached(String learnerId) async {
    final raw = _localCache.getForeverRaw(CacheKeys.learnerState(learnerId));
    if (raw == null) return null;
    return LearnerStateModel.fromCache(raw);
  }

  Future<LearnerStateModel> fetchState({
    required String learnerId,
    String? fields,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readCached(learnerId);
      if (cached != null) return cached;
    }

    final data = await _http.get(
      ApiEndpoints.learnerState,
      query: {'learner_id': learnerId, 'fields': ?fields},
    );

    final serverState = await _writeFull(learnerId, data);
    return restoreLocalProgress(serverState);
  }

  Future<LearnerStateModel> enrollCourse({
    required String learnerId,
    required String course,
  }) async {
    final data = await _http.post(
      ApiEndpoints.learnerEnroll,
      body: {'learner_id': learnerId, 'course': course},
    );
    return _writePartial(learnerId, data);
  }

  Future<LearnerStateModel> submitProgress({
    required String learnerId,
    int? xp,
    String? activityType,
    int? videoIndex,
    int? quizIndex,
    int? submissionIndex,
    String? fields,
  }) async {
    final data = await _http.post(
      ApiEndpoints.learnerSubmitProgress,
      body: {
        'learner_id': learnerId,
        'xp': ?xp,
        'activity_type': ?activityType,
        'video_index': ?videoIndex,
        'quiz_index': ?quizIndex,
        'submission_index': ?submissionIndex,
        'fields': ?fields,
      },
    );

    final mergedProgress = {
      ...data,
      'video_index': ?videoIndex,
      'quiz_index': ?quizIndex,
    };

    final conflict = data['conflict'] == true;
    final recorded = data['progress_recorded'] == true;

    if (conflict && !recorded) {
      await _markConflict(learnerId);
      throw ProgressConflictException(data);
    }
    if (data['success'] == false) {
      throw ProgressNotRecordedException(data);
    }

    final model = await _writeProgressResult(learnerId, mergedProgress);
    if (submissionIndex != null && model.enrollment != null) {
      model.enrollment = model.enrollment!.copyWith(
        submissionIndex: _max(
          model.enrollment!.submissionIndex,
          submissionIndex,
        ),
      );
    }
    if (activityType == 'unit_complete') {
      await _localCache.delete(CacheKeys.activityProgress(learnerId));
      model.hasPendingLocalProgress = false;
      model.pendingProgressXp = 0;
      await _localCache.setForeverRaw(
        CacheKeys.learnerState(learnerId),
        model.toJson(),
      );
    }
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

  Future<LearnerStateModel?> syncCompletedLocalProgress(
    String learnerId,
  ) async {
    final progress = _localCache.getForeverRaw(
      CacheKeys.activityProgress(learnerId),
    );
    if (progress == null || progress['ready_to_sync'] != true) return null;

    final unitIndex = _localUnitIndex(progress);
    final synced = await submitProgress(
      learnerId: learnerId,
      xp: (progress['pending_xp'] as num?)?.toInt(),
      activityType: 'unit_complete',
      videoIndex: progress['video_done'] == true && unitIndex != null
          ? unitIndex + 1
          : null,
      quizIndex: progress['quiz_done'] == true && unitIndex != null
          ? unitIndex + 1
          : null,
      submissionIndex: progress['submission_done'] == true && unitIndex != null
          ? unitIndex + 1
          : null,
      fields: completedUnitStateFields,
    );
    return synced;
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

  Future<void> _markConflict(String learnerId) async {
    final existing = await readCached(learnerId);
    if (existing == null) return;
    existing.hasPendingConflict = true;
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      existing.toJson(),
    );
  }

  Future<LearnerStateModel> _writeFull(
    String learnerId,
    Map<String, dynamic> json,
  ) async {
    final model = LearnerStateModel.fromFullJson(learnerId, json);
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return model;
  }

  Future<LearnerStateModel> _writePartial(
    String learnerId,
    Map<String, dynamic> json,
  ) async {
    final existing = await readCached(learnerId);
    final model = existing == null
        ? LearnerStateModel.fromFullJson(learnerId, json)
        : existing.mergeFrom(json);
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return model;
  }

  Future<LearnerStateModel> _writeProgressResult(
    String learnerId,
    Map<String, dynamic> json,
  ) async {
    final model = await _writePartial(learnerId, json);
    model.hasPendingConflict = false;
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return model;
  }

  Future<void> invalidate(String learnerId) =>
      _localCache.invalidateLearner(learnerId);
}
