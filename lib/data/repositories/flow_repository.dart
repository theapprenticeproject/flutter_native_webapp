import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../core/constants/app_constants.dart';
import '../local/asset_loader.dart';
import 'flow_manifest_repository.dart';

class FlowNotFoundException implements Exception {
  FlowNotFoundException(this.category, this.fileName);
  final String category;
  final String fileName;

  @override
  String toString() =>
      'FlowNotFoundException: no manifest entry for "$category/$fileName"';
}

class ResolvedFlow {
  const ResolvedFlow({required this.data, required this.isFallback});
  final Map<String, dynamic> data;
  final bool isFallback;
}

class FlowRepository {
  FlowRepository(this._manifestRepository, this._assetLoader, this._localCache);

  final FlowManifestRepository _manifestRepository;
  final AssetLoader _assetLoader;
  final LocalCache _localCache;
  final Map<String, ResolvedFlow> _memoryCache = {};

  Future<ResolvedFlow> loadFlow({
    required String category,
    required String fileName,
    required String languageCode,
  }) async {
    final manifest = await _manifestRepository.load(languageCode);
    final entry = manifest.entryFor(category, fileName);
    if (entry == null) throw FlowNotFoundException(category, fileName);

    final resolvedLanguage = manifest.resolveLanguage(
      category,
      fileName,
      languageCode,
    );
    final isFallback = resolvedLanguage != languageCode;
    final assetPath = AppConstants.flowAssetPath(
      resolvedLanguage,
      category,
      fileName,
    );
    final cacheKey = CacheKeys.flow(resolvedLanguage, category, fileName);

    final memory = _memoryCache[assetPath];
    if (memory != null) return memory;

    final cached = _localCache.getForeverRaw(cacheKey);
    if (cached != null) {
      final resolved = ResolvedFlow(data: cached, isFallback: isFallback);
      _memoryCache[assetPath] = resolved;
      return resolved;
    }

    final data = await _assetLoader.loadJson(assetPath);
    final resolved = ResolvedFlow(data: data, isFallback: isFallback);
    await _localCache.setForeverRaw(cacheKey, data);
    _memoryCache[assetPath] = resolved;
    return resolved;
  }

  Future<List<String>> fileNamesFor(
    String category, {
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final manifest = await _manifestRepository.load(languageCode);
    return manifest.fileNamesFor(category);
  }

  Future<List<String>> allCategories({
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final manifest = await _manifestRepository.load(languageCode);
    return manifest.allCategories();
  }

  Future<void> invalidateAll() async {
    _memoryCache.clear();
    await _localCache.deletePrefix('v2:flow:');
  }
}
