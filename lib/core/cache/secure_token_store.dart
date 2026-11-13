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

  /// Writes one value. Callers must write **one after another**, never with
  /// `Future.wait`. On the web the first write makes the encryption key, so two
  /// writes at the same time make two keys, only one key is kept, and the other
  /// value can never be read again (`OperationError`).
  Future<void> _write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Reads one value. A value that cannot be read (a lost or wrong encryption
  /// key) is treated as missing, and the broken storage is cleared, so the
  /// student can sign in again. It must never throw: a request reads the token
  /// first, and a throw here would stop every request.
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {
        // Nothing more we can do.
      }
      return null;
    }
  }

  Future<void> saveSession({
    required String phone,
    required String token,
    String? adminCode,
  }) async {
    await _write(_phoneKey, phone);
    await _write(_tokenKey, token);
    if (adminCode != null) await _write(_adminCodeKey, adminCode);
  }

  Future<void> saveRefreshedToken(String token) => _write(_tokenKey, token);

  /// Saves what `/auth/redeem` returns: the phone token (kept only to fetch a
  /// lost student token) and one token per student on the phone.
  Future<void> saveStudentSession({
    required String phoneToken,
    required Map<String, String> studentTokens,
    required String activeStudentId,
  }) async {
    await _write(_phoneTokenKey, phoneToken);
    await _write(_studentTokensKey, jsonEncode(studentTokens));
    await _write(_activeStudentKey, activeStudentId);
  }

  Future<String?> readPhoneToken() => _read(_phoneTokenKey);
  Future<String?> readActiveStudentId() => _read(_activeStudentKey);

  Future<Map<String, String>> _readStudentTokens() async {
    final raw = await _read(_studentTokensKey);
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
    await _write(_studentTokensKey, jsonEncode(tokens));
  }

  Future<void> forgetStudentToken(String studentId) async {
    final tokens = await _readStudentTokens();
    tokens.remove(studentId);
    await _write(_studentTokensKey, jsonEncode(tokens));
  }

  Future<void> saveActiveStudentId(String studentId) =>
      _write(_activeStudentKey, studentId);

  /// The token to send: the active student's, else the old single token.
  Future<String?> readToken() async {
    final activeId = await readActiveStudentId();
    if (activeId != null) {
      final studentToken = await readStudentToken(activeId);
      if (studentToken != null) return studentToken;
    }
    return _read(_tokenKey);
  }

  Future<String?> readPhone() => _read(_phoneKey);
  Future<String?> readAdminCode() => _read(_adminCodeKey);

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
