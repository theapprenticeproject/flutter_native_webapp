import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/build_info.dart';
import 'local_cache.dart';

final localCacheProvider = FutureProvider<LocalCache>((ref) async {
  final cache = await LocalCache.open();
  await cache.dropContentFromOtherBuilds(
    '${BuildInfo.commit}|${BuildInfo.time}',
  );
  return cache;
});
