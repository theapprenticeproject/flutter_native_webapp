import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/http_client_provider.dart';
import 'tap_buddy_repository.dart';

final tapBuddyRepositoryProvider = Provider<TapBuddyRepository>(
  (ref) => TapBuddyRepository(ref.watch(httpClientProvider)),
);
