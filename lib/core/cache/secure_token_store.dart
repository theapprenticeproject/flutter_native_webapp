import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore(this._storage);

  static const String _tokenKey = 'tap_token';
  static const String _adminCodeKey = 'tap_admin_code';
  static const String _phoneKey = 'tap_phone';
  static const String _phoneTokenKey = 'tap_phone_token';
  static const String _studentTokensKey = 'tap_student_tokens';
  static const String _activeStudentKey = 'tap_active_student';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String phone,
    required String token,
    String? adminCode,
  }) async {
    await Future.wait([
      _storage.write(key: _phoneKey, value: phone),
      _storage.write(key: _tokenKey, value: token),
      ?adminCode != null
          ? _storage.write(key: _adminCodeKey, value: adminCode)
          : null,
    ]);
  }

  Future<void> saveRefreshedToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Saves what `/auth/redeem` returns: the phone token (kept only to fetch a
  /// lost student token) and one token per student on the phone.
  Future<void> saveStudentSession({
    required String phoneToken,
    required Map<String, String> studentTokens,
    required String activeStudentId,
  }) async {
    await Future.wait([
      _storage.write(key: _phoneTokenKey, value: phoneToken),
      _storage.write(key: _studentTokensKey, value: jsonEncode(studentTokens)),
      _storage.write(key: _activeStudentKey, value: activeStudentId),
    ]);
  }

  Future<String?> readPhoneToken() => _storage.read(key: _phoneTokenKey);
  Future<String?> readActiveStudentId() =>
      _storage.read(key: _activeStudentKey);

  Future<Map<String, String>> _readStudentTokens() async {
    final raw = await _storage.read(key: _studentTokensKey);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<String?> readStudentToken(String studentId) async =>
      (await _readStudentTokens())[studentId];

  Future<void> saveStudentToken(String studentId, String token) async {
    final tokens = await _readStudentTokens();
    tokens[studentId] = token;
    await _storage.write(key: _studentTokensKey, value: jsonEncode(tokens));
  }

  Future<void> forgetStudentToken(String studentId) async {
    final tokens = await _readStudentTokens();
    tokens.remove(studentId);
    await _storage.write(key: _studentTokensKey, value: jsonEncode(tokens));
  }

  Future<void> saveActiveStudentId(String studentId) =>
      _storage.write(key: _activeStudentKey, value: studentId);

  /// The token to send: the active student's, else the old single token.
  Future<String?> readToken() async {
    final activeId = await readActiveStudentId();
    if (activeId != null) {
      final studentToken = await readStudentToken(activeId);
      if (studentToken != null) return studentToken;
    }
    return _storage.read(key: _tokenKey);
  }

  Future<String?> readPhone() => _storage.read(key: _phoneKey);
  Future<String?> readAdminCode() => _storage.read(key: _adminCodeKey);

  Future<bool> checkAdminCode(String candidate) async {
    final stored = await readAdminCode();
    return stored != null && stored == candidate;
  }

  Future<void> clear() => Future.wait([
    _storage.delete(key: _phoneKey),
    _storage.delete(key: _tokenKey),
    _storage.delete(key: _adminCodeKey),
    _storage.delete(key: _phoneTokenKey),
    _storage.delete(key: _studentTokensKey),
    _storage.delete(key: _activeStudentKey),
  ]);
}
