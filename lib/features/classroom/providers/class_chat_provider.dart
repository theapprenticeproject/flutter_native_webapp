import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_flow_provider.dart';
import 'class_chat_controller.dart';
import '../../../domain/learning_progress/class_session_bootstrap_provider.dart';
import '../../../domain/learning_progress/home_dashboard_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../domain/learner/learner_state_provider.dart';
import '../../../domain/progress/progress_provider.dart';
import '../../../domain/progress/step_recorder.dart';
import '../../../domain/submission/feedback_provider.dart';
import '../../../domain/submission/submission_provider.dart';
import '../../../domain/submission/work_submitter.dart';
import '../../../shared/media/webp_encoder.dart';

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
        feedbackTracker: await ref.watch(feedbackTrackerProvider.future),
        initialFeedback: bootstrap.feedback,
        workSubmitter: WorkSubmitter(
          ref.read(submissionRepositoryProvider),
          studentId: bootstrap.learnerId,
          prepareImage: encodeWebp,
        ),
        stepRecorder: StepRecorder(
          ref.read(progressRepositoryProvider),
          studentId: bootstrap.learnerId,
        ),
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
