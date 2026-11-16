import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/http_client_provider.dart';
import 'submission_repository.dart';

final submissionRepositoryProvider = Provider<SubmissionRepository>(
  (ref) => SubmissionRepository(ref.watch(httpClientProvider)),
);
