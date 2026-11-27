import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_models.dart';
import 'progress_provider.dart';

/// `/app/config`: the tiers and the points of each step. It rarely changes, so it
/// is read once for the session. A failed call is not kept: the next read asks
/// again. Screens use `valueOrNull`: without the config they just leave out what
/// needs it (the level, the points of an activity).
final appConfigProvider = FutureProvider.autoDispose<AppConfig>((ref) async {
  final link = ref.keepAlive();
  try {
    return await ref.watch(progressRepositoryProvider).appConfig();
  } catch (_) {
    link.close();
    rethrow;
  }
});
