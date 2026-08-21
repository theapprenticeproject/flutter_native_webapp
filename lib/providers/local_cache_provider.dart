import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/local_cache.dart';

final localCacheProvider = FutureProvider<LocalCache>((ref) async {
  return LocalCache.open();
});
