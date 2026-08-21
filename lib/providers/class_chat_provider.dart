import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_flow_provider.dart';
import 'class_chat_controller.dart';
import 'class_session_bootstrap_provider.dart';
import 'home_dashboard_provider.dart';
import 'language_provider.dart';
import 'learner_state_provider.dart';
import 'submission_review_provider.dart';

class NoUnitAvailableException implements Exception {
  const NoUnitAvailableException();

  @override
  String toString() => 'No unit is available to run right now.';
}

final classChatControllerProvider = FutureProvider.autoDispose
    .family<ClassChatController, int>((ref, attempt) async {
      final bootstrap = await ref.watch(classSessionBootstrapProvider.future);
      if (bootstrap.unit == null) {
        throw const NoUnitAvailableException();
      }

      final languageCode = ref.watch(languageProvider);
      final flow = await ref.watch(activityFlowProvider(languageCode).future);

      final learnerStateRepository = await ref.watch(
        learnerStateRepositoryProvider.future,
      );
      final submissionReviewRepository = await ref.watch(
        submissionReviewRepositoryProvider.future,
      );
      final sessionWindowRepository = await ref.watch(
        classSessionWindowRepositoryProvider.future,
      );
      final studentName =
          bootstrap.learnerState.profile?.studentName ?? 'Champ';
      var providerIsActive = true;

      final controller = ClassChatController(
        learnerId: bootstrap.learnerId,
        phone: bootstrap.phone,
        studentName: studentName,
        courseDisplay: bootstrap.courseName,
        flow: flow,
        unit: bootstrap.unit!,
        nextUnit: bootstrap.nextUnit,
        unitIndex: bootstrap.unitIndex,
        initialLearnerState: bootstrap.learnerState,
        learnerStateRepository: learnerStateRepository,
        submissionReviewRepository: submissionReviewRepository,
        sessionWindowRepository: sessionWindowRepository,
        onProgressSaved: () {
          if (!providerIsActive) return;
          ref.invalidate(learnerStateDataProvider(bootstrap.learnerId));
          ref.invalidate(learningDashboardProvider);
        },
      );

      ref.onDispose(() {
        providerIsActive = false;
        controller.dispose();
      });
      return controller;
    });
