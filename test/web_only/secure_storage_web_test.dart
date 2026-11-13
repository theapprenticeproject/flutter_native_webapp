@TestOn('browser')
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// The test runner does not register web plugins, so we register the real one.
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';

/// Runs in a real browser, with the real web secure storage (WebCrypto). It
/// shows the bug and the fix: the first writes, done in parallel, lose a key.
///
///   flutter test --platform chrome test/web_only
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStoragePlatform.instance = FlutterSecureStorageWeb();
  setUp(() {
    // Start every test with no key and no values, like a new browser.
    return const FlutterSecureStorage().deleteAll();
  });

  test(
    'BUG (why we write one by one): parallel first writes lose a value',
    () async {
      const storage = FlutterSecureStorage();
      await Future.wait([
        storage.write(key: 'a', value: '1'),
        storage.write(key: 'b', value: '2'),
        storage.write(key: 'c', value: '3'),
      ]);
      var unreadable = 0;
      for (final k in ['a', 'b', 'c']) {
        try {
          if (await storage.read(key: k) != '${k.codeUnitAt(0) - 96}') {
            unreadable++;
          }
        } catch (_) {
          unreadable++;
        }
      }
      expect(unreadable, greaterThan(0), reason: 'the package loses keys here');
    },
  );

  test('FIX: our store keeps every value from a first sign-in', () async {
    final store = SecureTokenStore(const FlutterSecureStorage());
    await store.saveStudentSession(
      phoneToken: 'phone-tok',
      studentTokens: {'S1': 'tok-1', 'S2': 'tok-2'},
      activeStudentId: 'S2',
    );
    expect(await store.readPhoneToken(), 'phone-tok');
    expect(await store.readActiveStudentId(), 'S2');
    expect(await store.readStudentToken('S1'), 'tok-1');
    expect(await store.readToken(), 'tok-2');
  });
}
