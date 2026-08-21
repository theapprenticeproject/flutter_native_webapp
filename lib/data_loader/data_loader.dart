import '../core/cache/local_cache.dart';

class DataLoader {
  DataLoader(this._localCache);

  final LocalCache _localCache;

  Future<Map<String, dynamic>> loadJson({
    required String cacheKey,
    required Future<Map<String, dynamic>> Function() fetch,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localCache.getForeverRaw(cacheKey);
      if (cached != null) return cached;
    }
    final data = await fetch();
    await _localCache.setForeverRaw(cacheKey, data);
    return data;
  }

  Future<List<dynamic>> loadJsonRawList({
    required String cacheKey,
    required Future<List<dynamic>> Function() fetch,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localCache.getForeverRaw(cacheKey);
      if (cached != null && cached['items'] is List) {
        return cached['items'] as List<dynamic>;
      }
    }
    final data = await fetch();
    await _localCache.setForeverRaw(cacheKey, {'items': data});
    return data;
  }

  Future<List<Map<String, dynamic>>> loadJsonList({
    required String cacheKey,
    required Future<List<Map<String, dynamic>>> Function() fetch,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localCache.getForeverList(cacheKey, (json) => json);
      if (cached != null) return cached;
    }
    final data = await fetch();
    await _localCache.setForeverRawList(cacheKey, data);
    return data;
  }

  bool has(String cacheKey) => _localCache.has(cacheKey);

  Future<void> invalidate(String cacheKey) => _localCache.delete(cacheKey);

  Future<void> invalidatePrefix(String prefix) =>
      _localCache.deletePrefix(prefix);
}
