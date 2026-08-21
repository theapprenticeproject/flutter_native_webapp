import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore(this._storage);

  static const String _tokenKey = 'tap_token';
  static const String _adminCodeKey = 'tap_admin_code';
  static const String _phoneKey = 'tap_phone';

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

  Future<String?> readToken() => _storage.read(key: _tokenKey);
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
  ]);
}
