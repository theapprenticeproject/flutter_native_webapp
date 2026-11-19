import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'cache_keys.dart';

class CacheEntry<T> {
  const CacheEntry({required this.value, required this.cachedAt});

  final T value;
  final DateTime cachedAt;
}

class LocalCacheOpenTimeoutException implements Exception {
  const LocalCacheOpenTimeoutException();

  @override
  String toString() =>
      'LocalCacheOpenTimeoutException: opening local storage took too long. '
      'On web this usually means a stale IndexedDB connection from a '
      'previous session is blocking the new one — clear site data and '
      'reload.';
}

class LocalCache {
  LocalCache._(this._box, this._indexBox);

  LocalCache.forTesting(this._box, this._indexBox);

  static const String _boxName = 'tap_forever_cache';
  static const String _indexBoxName = 'tap_forever_cache_index';

  static const Duration _openTimeout = Duration(seconds: 10);

  final Box<String> _box;
  final Box<String> _indexBox;

  static Future<LocalCache> open() async {
    try {
      return await _openInternal().timeout(_openTimeout);
    } on TimeoutException {
      throw const LocalCacheOpenTimeoutException();
    }
  }

  static Future<LocalCache> _openInternal() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(_boxName);
    final indexBox = await Hive.openBox<String>(_indexBoxName);
    return LocalCache._(box, indexBox);
  }

  bool has(String key) => _box.containsKey(key);

  DateTime? cachedAt(String key) {
    final raw = _indexBox.get(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  T? getForever<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      _box.delete(key);
      _indexBox.delete(key);
    }
    return null;
  }

  List<T>? getForeverList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => fromJson(Map<String, dynamic>.from(m)))
            .toList(growable: false);
      }
    } catch (_) {
      _box.delete(key);
      _indexBox.delete(key);
    }
    return null;
  }

  Map<String, dynamic>? getForeverRaw(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      _box.delete(key);
      _indexBox.delete(key);
    }
    return null;
  }

  Future<void> setForever<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T value) toJson,
  ) async {
    await _box.put(key, jsonEncode(toJson(value)));
    await _touch(key);
  }

  Future<void> setForeverList<T>(
    String key,
    List<T> values,
    Map<String, dynamic> Function(T value) toJson,
  ) async {
    await _box.put(key, jsonEncode(values.map(toJson).toList()));
    await _touch(key);
  }

  Future<void> setForeverRaw(String key, Map<String, dynamic> value) async {
    await _box.put(key, jsonEncode(value));
    await _touch(key);
  }

  Future<void> setForeverRawList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    await _box.put(key, jsonEncode(value));
    await _touch(key);
  }

  Future<void> _touch(String key) async {
    await _indexBox.put(key, DateTime.now().toIso8601String());
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
    await _indexBox.delete(key);
  }

  List<String> keysWithPrefix(String prefix) => _box.keys
      .map((k) => k.toString())
      .where((k) => k.startsWith(prefix))
      .toList(growable: false);

  Future<void> deletePrefix(String prefix) async {
    final keys = keysWithPrefix(prefix);
    await _box.deleteAll(keys);
    await _indexBox.deleteAll(keys);
  }

  /// Bundled files (course list, course files, chat flow) are also saved here.
  /// A browser that ran an older build would keep the old copies forever and
  /// ignore the new files, for example a new course. So saved copies from
  /// another build are dropped. The student's progress is never touched. A
  /// build with no stamp (not made by `scripts/build_web.sh`) always drops them.
  Future<void> dropContentFromOtherBuilds(String build) async {
    final sameBuild =
        !build.startsWith('unknown') &&
        getForeverRaw(_contentBuildKey)?['build'] == build;
    if (sameBuild) return;
    for (final prefix in CacheKeys.bundledContentPrefixes) {
      await deletePrefix(prefix);
    }
    await setForeverRaw(_contentBuildKey, {'build': build});
  }

  static const String _contentBuildKey = 'v2:content_build';

  Future<void> invalidateLearner(String learnerId) async {
    await delete(CacheKeys.learnerState(learnerId));
    await delete(CacheKeys.achievements(learnerId));
    await delete(CacheKeys.activityProgress(learnerId));
  }

  Future<void> clearAll() async {
    await _box.clear();
    await _indexBox.clear();
  }
}
