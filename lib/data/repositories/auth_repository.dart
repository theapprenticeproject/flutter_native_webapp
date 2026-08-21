import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../core/cache/secure_token_store.dart';
import '../../models/auth_session_model.dart';
import '../../models/learner_state_model.dart';
import '../../models/profile_summary_model.dart';
import '../remote/api_endpoints.dart';
import '../remote/http_client.dart';

class AuthRepository {
  AuthRepository(this._http, this._localCache, this._secureTokenStore);

  final HttpClient _http;
  final LocalCache _localCache;
  final SecureTokenStore _secureTokenStore;

  Future<Map<String, dynamic>> checkPhone(String phone) async {
    final data = await _http.post(
      ApiEndpoints.checkPhone,
      body: {'phone': phone},
    );
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final data = await _http.post(
      ApiEndpoints.login,
      body: {'phone': phone, 'password': password},
    );
    if (data['success'] == true) {
      await _persistLoginPayload(data);
    }
    return data;
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp(String phone) =>
      _http.post(ApiEndpoints.forgotPasswordSendOtp, body: {'phone': phone});

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String phone,
    required String otp,
  }) => _http.post(
    ApiEndpoints.forgotPasswordVerifyOtp,
    body: {'phone': phone, 'otp': otp},
  );

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String newPassword,
    required String resetToken,
  }) async {
    await _secureTokenStore.saveRefreshedToken(resetToken);
    final data = await _http.post(
      ApiEndpoints.resetPassword,
      body: {'phone': phone, 'password': newPassword},
    );
    if (data['success'] == true) {
      await _persistLoginPayload(data);
    }
    return data;
  }

  Future<AuthSessionModel?> readCachedSession(String phone) async {
    final raw = _localCache.getForeverRaw(CacheKeys.authSession(phone));
    return raw == null ? null : AuthSessionModel.fromJson(raw);
  }

  Future<void> logout() async {
    await _secureTokenStore.clear();
    await _localCache.clearAll();
  }

  Future<void> _persistLoginPayload(Map<String, dynamic> data) async {
    final phone = data['phone'] as String;
    final token = data['token'] as String;
    final adminCode = data['admin_code'] as String?;

    await _secureTokenStore.saveSession(
      phone: phone,
      token: token,
      adminCode: adminCode,
    );

    final session = AuthSessionModel.fromJson(data);
    await _localCache.setForeverRaw(
      CacheKeys.authSession(phone),
      session.toJson(),
    );

    final rawProfiles = data['profiles'];
    if (rawProfiles is List) {
      final summaries = <ProfileSummaryModel>[];
      for (final raw in rawProfiles.whereType<Map>()) {
        try {
          summaries.add(
            ProfileSummaryModel.fromJson(phone, Map<String, dynamic>.from(raw)),
          );
        } catch (_) {
          continue;
        }
      }

      await _localCache.setForeverRawList(
        CacheKeys.profilesPage(
          phone,
          data['page'] as int? ?? 1,
          data['page_size'] as int? ?? 10,
        ),
        ProfileSummaryModel.listToJson(summaries),
      );

      for (final raw in rawProfiles.whereType<Map>()) {
        final learnerId = raw['learner_id'] as String?;
        final state = raw['state'];
        if (learnerId == null || state is! Map) continue;
        try {
          final model = LearnerStateModel.fromFullJson(
            learnerId,
            Map<String, dynamic>.from(state),
          );
          await _localCache.setForeverRaw(
            CacheKeys.learnerState(learnerId),
            model.toJson(),
          );
        } catch (_) {
          continue;
        }
      }
    }
  }
}
