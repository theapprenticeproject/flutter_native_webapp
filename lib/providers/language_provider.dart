import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cache_keys.dart';
import '../core/constants/app_constants.dart';
import 'local_cache_provider.dart';

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _restore();
    return AppConstants.defaultLanguageCode;
  }

  Future<void> _restore() async {
    final localCache = await ref.read(localCacheProvider.future);
    final stored =
        localCache.getForeverRaw(CacheKeys.languageSetting())?['code']
            as String?;
    if (stored != null && AppConstants.isSupportedLanguage(stored)) {
      state = stored;
    }
  }

  Future<void> setLanguage(String code) async {
    if (!AppConstants.isSupportedLanguage(code)) return;
    state = code;
    final localCache = await ref.read(localCacheProvider.future);
    await localCache.setForeverRaw(CacheKeys.languageSetting(), {'code': code});
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);
