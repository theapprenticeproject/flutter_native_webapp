import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/learner_state_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../models/active_profile_model.dart';
import '../../../../models/learner_state_model.dart';
import '../../../../models/program_content/course_index_entry_model.dart';
import '../../../../providers/learner_state_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/program_content_provider.dart';
import '../data/onboarding_flow_repository.dart';
import '../models/onboarding_flow_step.dart';

class OnboardingBootstrapData {
  const OnboardingBootstrapData({
    required this.activeProfile,
    required this.learnerState,
    required this.courseIndex,
    required this.steps,
    required this.sessionService,
  });

  final ActiveProfileModel activeProfile;
  final LearnerStateModel learnerState;
  final List<CourseIndexEntryModel> courseIndex;
  final Map<String, OnboardingFlowStep> steps;
  final OnboardingSessionService sessionService;
}

class OnboardingProfileUpdateResult {
  const OnboardingProfileUpdateResult({
    required this.learnerState,
    this.activeProfile,
  });

  final LearnerStateModel learnerState;
  final ActiveProfileModel? activeProfile;
}

class OnboardingCompletionResult {
  const OnboardingCompletionResult({
    required this.activeProfile,
    required this.learnerState,
  });

  final ActiveProfileModel activeProfile;
  final LearnerStateModel learnerState;
}

class OnboardingSessionService {
  const OnboardingSessionService._({
    required ProfileRepository profileRepository,
    required LearnerStateRepository learnerStateRepository,
  }) : _profileRepository = profileRepository,
       _learnerStateRepository = learnerStateRepository;

  final ProfileRepository _profileRepository;
  final LearnerStateRepository _learnerStateRepository;

  static Future<OnboardingBootstrapData> load(WidgetRef ref) async {
    final profileRepository = await ref.read(profileRepositoryProvider.future);
    final learnerStateRepository = await ref.read(
      learnerStateRepositoryProvider.future,
    );
    final programContentRepository = await ref.read(
      programContentRepositoryProvider.future,
    );

    final activeProfile = await profileRepository.readActiveProfile();
    if (activeProfile == null) {
      throw const OnboardingSessionException(
        'No active profile found. Please sign in again.',
      );
    }

    final learnerState = await learnerStateRepository.fetchState(
      learnerId: activeProfile.learnerId,
    );
    final courseIndex = await programContentRepository.fetchCourseIndex();
    final steps = await const OnboardingFlowRepository().load();

    return OnboardingBootstrapData(
      activeProfile: activeProfile,
      learnerState: learnerState,
      courseIndex: courseIndex,
      steps: steps,
      sessionService: OnboardingSessionService._(
        profileRepository: profileRepository,
        learnerStateRepository: learnerStateRepository,
      ),
    );
  }

  Future<LearnerStateModel> enrollInCourse({
    required WidgetRef ref,
    required ActiveProfileModel activeProfile,
    required String courseId,
  }) async {
    final updated = await _profileRepository.completeOnboarding(
      phone: activeProfile.phone,
      learnerId: activeProfile.learnerId,
      course: courseId,
      markComplete: false,
    );
    ref.invalidate(learnerStateDataProvider(activeProfile.learnerId));
    return updated;
  }

  Future<OnboardingProfileUpdateResult> commitProfileUpdates({
    required WidgetRef ref,
    required ActiveProfileModel activeProfile,
    required Map<String, dynamic> updates,
  }) async {
    final updated = await _profileRepository.completeOnboarding(
      phone: activeProfile.phone,
      learnerId: activeProfile.learnerId,
      updates: updates,
      markComplete: false,
    );
    ref.invalidate(learnerStateDataProvider(activeProfile.learnerId));

    if (!updates.containsKey('student_name')) {
      return OnboardingProfileUpdateResult(learnerState: updated);
    }

    final updatedProfile = ActiveProfileModel(
      phone: activeProfile.phone,
      learnerId: activeProfile.learnerId,
      studentName: updates['student_name'] as String,
      grade: activeProfile.grade,
      division: activeProfile.division,
      avatar: activeProfile.avatar,
      onboardingCompleted: activeProfile.onboardingCompleted,
    );
    await setActiveProfile(ref, updatedProfile);

    return OnboardingProfileUpdateResult(
      learnerState: updated,
      activeProfile: updatedProfile,
    );
  }

  Future<OnboardingCompletionResult> completeOnboarding({
    required WidgetRef ref,
    required ActiveProfileModel activeProfile,
    required String? courseId,
  }) async {
    var updatedState = await _profileRepository.completeOnboarding(
      phone: activeProfile.phone,
      learnerId: activeProfile.learnerId,
      course: courseId,
      markComplete: true,
    );

    if (courseId != null && courseId.isNotEmpty) {
      updatedState = await _learnerStateRepository.prepareLocalUnit(
        learnerId: activeProfile.learnerId,
        unitIndex: 0,
      );
    }

    final updatedProfile = ActiveProfileModel(
      phone: activeProfile.phone,
      learnerId: activeProfile.learnerId,
      studentName:
          updatedState.profile?.studentName ?? activeProfile.studentName,
      grade: activeProfile.grade,
      division: activeProfile.division,
      avatar: activeProfile.avatar,
      onboardingCompleted: true,
    );

    await setActiveProfile(ref, updatedProfile);
    ref.invalidate(learnerStateDataProvider(activeProfile.learnerId));

    return OnboardingCompletionResult(
      activeProfile: updatedProfile,
      learnerState: updatedState,
    );
  }
}

class OnboardingSessionException implements Exception {
  const OnboardingSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}
