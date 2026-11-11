import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/http_client_provider.dart';
import 'progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(httpClientProvider)),
);
