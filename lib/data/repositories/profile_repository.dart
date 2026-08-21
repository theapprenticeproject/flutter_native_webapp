import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../models/active_profile_model.dart';
import '../../models/learner_state_model.dart';
import '../../models/profile_summary_model.dart';
import '../remote/api_endpoints.dart';
import '../remote/http_client.dart';
import 'learner_state_repository.dart';
import 'roster_cache_sync.dart';

class ProfileRepository {
  ProfileRepository(this._http, this._localCache, this._learnerStateRepository);

  final HttpClient _http;
  final LocalCache _localCache;
  final LearnerStateRepository _learnerStateRepository;

  Future<List<ProfileSummaryModel>> readCachedProfilesPage(
    String phone,
    int page,
    int pageSize,
  ) async {
    final raw = _localCache.getForeverList(
      CacheKeys.profilesPage(phone, page, pageSize),
      (json) => json,
    );
    return raw == null
        ? const []
        : _withLocalOnboardingState(ProfileSummaryModel.listFromCache(raw));
  }

  Future<List<ProfileSummaryModel>> fetchProfilesPage({
    required String phone,
    int page = 1,
    int pageSize = 10,
    bool forceRefresh = false,
  }) async {
    final key = CacheKeys.profilesPage(phone, page, pageSize);
    if (!forceRefresh && _localCache.has(key)) {
      return readCachedProfilesPage(phone, page, pageSize);
    }

    final data = await _http.get(
      ApiEndpoints.profiles,
      query: {'phone': phone, 'page': page, 'page_size': pageSize},
    );
    final rows = _withLocalOnboardingState(
      ProfileSummaryModel.listFromJson(phone, data['profiles']),
    );
    await _localCache.setForeverRawList(
      key,
      ProfileSummaryModel.listToJson(rows),
    );
    return rows;
  }

  Future<List<ProfileSummaryModel>> searchProfiles({
    required String phone,
    String? grade,
    String? division,
    String? rollNumber,
    String? query,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    final key = CacheKeys.profilesSearch(
      phone,
      grade: grade,
      division: division,
      rollNumber: rollNumber,
      query: query,
      page: page,
    );
    if (!forceRefresh && _localCache.has(key)) {
      final raw = _localCache.getForeverList(key, (json) => json);
      return raw == null
          ? const []
          : _withLocalOnboardingState(ProfileSummaryModel.listFromCache(raw));
    }

    final data = await _http.get(
      ApiEndpoints.profilesSearch,
      query: {
        'phone': phone,
        'grade': ?grade,
        'division': ?division,
        'roll_number': ?rollNumber,
        'query': ?query,
        'page': page,
        'page_size': pageSize,
      },
    );
    final rows = _withLocalOnboardingState(
      ProfileSummaryModel.listFromJson(phone, data['profiles']),
    );
    await _localCache.setForeverRawList(
      key,
      ProfileSummaryModel.listToJson(rows),
    );
    return rows;
  }

  Future<LearnerStateModel> selectProfile({
    required String phone,
    required String learnerId,
  }) async {
    final data = await _http.post(
      ApiEndpoints.profilesSelect,
      body: {'phone': phone, 'learner_id': learnerId},
    );
    final model = LearnerStateModel.fromFullJson(learnerId, data);
    final profileData = data['profile'];
    if (data['onboarding_completed'] == true ||
        (profileData is Map && profileData['onboarding_completed'] == true)) {
      await _markOnboardingCompleted(learnerId);
    }
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return _learnerStateRepository.restoreLocalProgress(model);
  }

  Future<void> setActiveProfile(ActiveProfileModel profile) async {
    await _localCache.setForeverRaw(
      CacheKeys.activeProfile(),
      profile.toJson(),
    );
    if (profile.onboardingCompleted) {
      await _markOnboardingCompleted(profile.learnerId);
    }
  }

  Future<ActiveProfileModel?> readActiveProfile() async {
    final raw = _localCache.getForeverRaw(CacheKeys.activeProfile());
    if (raw == null) return null;
    final profile = ActiveProfileModel.fromJson(raw);
    if (profile.onboardingCompleted) {
      await _markOnboardingCompleted(profile.learnerId);
    }
    return profile;
  }

  Future<void> clearActiveProfile() async {
    await _localCache.delete(CacheKeys.activeProfile());
  }

  Future<String> updateAvatar({
    required String phone,
    required String learnerId,
    required String avatar,
  }) async {
    final data = await _http.post(
      ApiEndpoints.profilesAvatar,
      body: {'phone': phone, 'learner_id': learnerId, 'avatar': avatar},
    );
    final resolvedAvatar = data['avatar'] as String? ?? avatar;
    if (data['success'] == true) {
      await RosterCacheSync.patchRow(
        _localCache,
        phone: phone,
        learnerId: learnerId,
        avatar: resolvedAvatar,
      );
    }
    return resolvedAvatar;
  }

  Future<LearnerStateModel> updateProfile({
    required String phone,
    required String learnerId,
    required Map<String, dynamic> updates,
  }) async {
    final data = await _http.post(
      ApiEndpoints.profilesUpdate,
      body: {'phone': phone, 'learner_id': learnerId, 'updates': updates},
    );

    if (updates.containsKey('student_name')) {
      await RosterCacheSync.patchRow(
        _localCache,
        phone: phone,
        learnerId: learnerId,
        studentName: updates['student_name'] as String?,
      );
    }

    final existing = await _learnerStateRepository.readCached(learnerId);
    final model = existing == null
        ? LearnerStateModel.fromFullJson(learnerId, data)
        : existing.mergeFrom(data);
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      model.toJson(),
    );
    return model;
  }

  Future<LearnerStateModel> completeOnboarding({
    required String phone,
    required String learnerId,
    Map<String, dynamic>? updates,
    String? course,
    bool markComplete = true,
  }) async {
    await _http.post(
      ApiEndpoints.onboardingComplete,
      body: {
        'phone': phone,
        'learner_id': learnerId,
        if (updates != null && updates.isNotEmpty) 'updates': updates,
        'course': ?course,
        'mark_complete': markComplete ? 1 : 0,
      },
    );

    if (markComplete) {
      await _markOnboardingCompleted(learnerId);
      await RosterCacheSync.patchRow(
        _localCache,
        phone: phone,
        learnerId: learnerId,
        onboardingCompleted: true,
      );
    }

    if (updates != null && updates.containsKey('student_name')) {
      await RosterCacheSync.patchRow(
        _localCache,
        phone: phone,
        learnerId: learnerId,
        studentName: updates['student_name'] as String?,
      );
    }

    final refreshed = await _learnerStateRepository.fetchState(
      learnerId: learnerId,
      forceRefresh: true,
    );
    await _localCache.setForeverRaw(
      CacheKeys.learnerState(learnerId),
      refreshed.toJson(),
    );
    return refreshed;
  }

  bool isOnboardingCompleted(String learnerId, {bool fallback = false}) =>
      fallback ||
      _localCache.getForeverRaw(
            CacheKeys.onboardingCompleted(learnerId),
          )?['completed'] ==
          true;

  List<ProfileSummaryModel> _withLocalOnboardingState(
    List<ProfileSummaryModel> profiles,
  ) => profiles
      .map(
        (profile) =>
            isOnboardingCompleted(
              profile.learnerId,
              fallback: profile.onboardingCompleted,
            )
            ? profile.copyWith(onboardingCompleted: true)
            : profile,
      )
      .toList(growable: false);

  Future<void> _markOnboardingCompleted(String learnerId) =>
      _localCache.setForeverRaw(CacheKeys.onboardingCompleted(learnerId), {
        'completed': true,
      });
}
