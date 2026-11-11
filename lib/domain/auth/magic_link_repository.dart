import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../core/cache/secure_token_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/http_client.dart';
import '../profile/active_profile_model.dart';
import 'redeemed_student.dart';

/// Signing in with the WhatsApp magic link (R-32, R-34, R-81).
///
/// The link carries a code. `/auth/redeem` swaps it for one token per student
/// on the phone, so switching student needs no network call. The phone token
/// is kept only to fetch a student token that was lost (`/auth/select_profile`).
class MagicLinkRepository {
  MagicLinkRepository(this._http, this._cache, this._store);

  final HttpClient _http;
  final LocalCache _cache;
  final SecureTokenStore _store;

  Future<RedeemResult> redeem(String code) async {
    final data = await _http.postApi(
      '/auth/redeem',
      body: {'code': code.trim()},
    );

    final rawStudents = (data['students'] as List?)?.whereType<Map>().toList();
    if (rawStudents == null || rawStudents.isEmpty) {
      throw ApiException('STUDENT_NOT_FOUND', 'the phone has no student');
    }
    final students = <RedeemedStudent>[];
    final tokens = <String, String>{};
    for (final raw in rawStudents) {
      final json = Map<String, dynamic>.from(raw);
      final student = RedeemedStudent.fromJson(json);
      students.add(student);
      final token = json['token'];
      if (token is String) tokens[student.studentId] = token;
    }

    final active = students.first;
    await _store.saveStudentSession(
      phoneToken: (data['phone_token'] as String?) ?? '',
      studentTokens: tokens,
      activeStudentId: active.studentId,
    );
    await _cache.setForeverRawList(
      CacheKeys.linkRoster(),
      students.map((s) => s.toJson()).toList(),
    );

    final result = RedeemResult(students: students, activeStudent: active);
    if (result.needsPicker) {
      // The student picks a name first. Forget any profile from an old link.
      await _cache.delete(CacheKeys.activeProfile());
    } else {
      await _activate(active);
    }
    return result;
  }

  Future<List<RedeemedStudent>> readRoster() async =>
      _cache.getForeverList(CacheKeys.linkRoster(), RedeemedStudent.fromJson) ??
      const [];

  /// Makes [studentId] the active student. Uses the saved token. If it is gone,
  /// asks the Worker for a new one with the phone token.
  Future<RedeemedStudent> switchStudent(String studentId) async {
    final roster = await readRoster();
    final student = roster.where((s) => s.studentId == studentId).firstOrNull;
    if (student == null) {
      throw StateError('student $studentId is not on this phone');
    }

    if (await _store.readStudentToken(studentId) == null) {
      final phoneToken = await _store.readPhoneToken();
      if (phoneToken == null || phoneToken.isEmpty) {
        throw ApiException('UNAUTHORIZED', 'no phone token saved');
      }
      final data = await _http.postApi(
        '/auth/select_profile',
        body: {'student_id': studentId},
        bearer: phoneToken,
      );
      final token = data['token'] as String?;
      if (token == null) {
        throw ApiException('SERVER_ERROR', 'select_profile gave no token');
      }
      await _store.saveStudentToken(studentId, token);
    }

    await _store.saveActiveStudentId(studentId);
    await _activate(student);
    return student;
  }

  /// There is no onboarding in v1 (the kids are pre-registered), so the student
  /// counts as onboarded. The Worker does not send the phone number, and the
  /// student token carries the identity, so the phone is empty.
  Future<void> _activate(RedeemedStudent student) => _cache.setForeverRaw(
    CacheKeys.activeProfile(),
    ActiveProfileModel(
      phone: '',
      learnerId: student.studentId,
      studentName: student.name,
      grade: student.grade,
      onboardingCompleted: true,
    ).toJson(),
  );
}
