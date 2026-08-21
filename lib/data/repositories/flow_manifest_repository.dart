import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../core/constants/app_constants.dart';
import '../local/asset_loader.dart';
import '../../models/flow_manifest_model.dart';

class FlowManifestRepository {
  FlowManifestRepository(this._assetLoader, this._localCache);

  final AssetLoader _assetLoader;
  final LocalCache _localCache;
  final Map<String, FlowManifest> _memoryCache = {};

  Future<FlowManifest> load(String languageCode) async {
    final memory = _memoryCache[languageCode];
    if (memory != null) return memory;

    final key = CacheKeys.flowManifest(languageCode);
    final cached = _localCache.getForeverRaw(key);
    if (cached != null) {
      final manifest = FlowManifest.fromJson(cached);
      _memoryCache[languageCode] = manifest;
      return manifest;
    }

    Map<String, dynamic> json;
    try {
      json = await _assetLoader.loadJson(
        AppConstants.flowManifestPath(languageCode),
      );
    } on AssetLoadException {
      if (languageCode == AppConstants.defaultLanguageCode) rethrow;
      json = await _assetLoader.loadJson(
        AppConstants.flowManifestPath(AppConstants.defaultLanguageCode),
      );
    }

    final manifest = FlowManifest.fromJson(json);
    await _localCache.setForeverRaw(key, manifest.toJson());
    _memoryCache[languageCode] = manifest;
    return manifest;
  }

  Future<void> invalidate(String languageCode) async {
    _memoryCache.remove(languageCode);
    await _localCache.delete(CacheKeys.flowManifest(languageCode));
  }

  Future<void> invalidateAll() async {
    _memoryCache.clear();
    await _localCache.deletePrefix('v2:flow:manifest:');
  }
}
