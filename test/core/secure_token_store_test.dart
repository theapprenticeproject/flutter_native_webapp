import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';

/// On the web, the first write to secure storage makes the encryption key. Two
/// writes at the same time each make a key, and only the last key is kept, so
/// the other value can never be read again (`OperationError`). So writes must
/// go one after another.
class _FakeStorage implements FlutterSecureStorage {
  final Map<String, String> data = {};
  int running = 0;
  int maxRunning = 0;
  bool failReads = false;
  int deleteAllCalls = 0;

  @override
  Future<void> write({
    required String key,
    required String? value,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async {
    running++;
    if (running > maxRunning) maxRunning = running;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    running--;
  }

  @override
  Future<String?> read({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async {
    if (failReads) throw StateError('OperationError');
    return data[key];
  }

  @override
  Future<void> delete({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async => data.remove(key);

  @override
  Future<void> deleteAll({
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async {
    deleteAllCalls++;
    data.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  guardTests();
  late _FakeStorage storage;
  late SecureTokenStore store;

  setUp(() {
    storage = _FakeStorage();
    store = SecureTokenStore(storage);
  });

  test('saving a student session never writes two values at once', () async {
    await store.saveStudentSession(
      phoneToken: 'p',
      studentTokens: {'S1': 't1'},
      activeStudentId: 'S1',
    );
    expect(storage.maxRunning, 1);
    expect(await store.readToken(), 't1');
    expect(await store.readPhoneToken(), 'p');
  });

  test('the old session save never writes two values at once either', () async {
    await store.saveSession(phone: '1', token: 't', adminCode: 'a');
    expect(storage.maxRunning, 1);
  });

  test(
    'a value that cannot be read is treated as missing, not as a crash',
    () async {
      await store.saveStudentSession(
        phoneToken: 'p',
        studentTokens: {'S1': 't1'},
        activeStudentId: 'S1',
      );
      storage.failReads = true;

      expect(await store.readToken(), isNull);
      expect(await store.readPhoneToken(), isNull);
      expect(await store.readStudentToken('S1'), isNull);
      expect(await store.readActiveStudentId(), isNull);
    },
  );

  test(
    'an unreadable value clears the broken storage so the next login works',
    () async {
      await store.saveStudentSession(
        phoneToken: 'p',
        studentTokens: {'S1': 't1'},
        activeStudentId: 'S1',
      );
      storage.failReads = true;
      await store.readToken();
      storage.failReads = false;

      expect(storage.deleteAllCalls, greaterThan(0));
      expect(storage.data, isEmpty);

      await store.saveStudentSession(
        phoneToken: 'p2',
        studentTokens: {'S2': 't2'},
        activeStudentId: 'S2',
      );
      expect(await store.readToken(), 't2');
    },
  );
}

/// A guard on the source: every write goes through `_write`, and nothing runs
/// writes in parallel.
void guardTests() {
  test(
    'only _write touches the storage to write, and no Future.wait writes',
    () {
      final text = File(
        'lib/core/cache/secure_token_store.dart',
      ).readAsStringSync();
      expect('_storage.write('.allMatches(text).length, 1);
      final waits = RegExp(r'Future\.wait\(\[[^\]]*write', dotAll: true);
      expect(waits.hasMatch(text), isFalse);
    },
  );
}
