import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_flow_model.dart';
import 'flow_repository_provider.dart';

final activityFlowProvider = FutureProvider.autoDispose
    .family<ActivityFlowModel, String>((ref, languageCode) async {
      final resolved = await ref.watch(
        resolvedFlowProvider((
          category: 'activity',
          fileName: 'activity_flow.json',
          languageCode: languageCode,
        )).future,
      );
      return ActivityFlowModel.fromJson(resolved.data);
    });
