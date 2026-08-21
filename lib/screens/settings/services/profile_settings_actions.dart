import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/active_profile_model.dart';
import '../../../models/learner_state_model.dart';
import '../../../models/profile_summary_model.dart';
import '../../../providers/learner_state_provider.dart';
import '../../../providers/profile_provider.dart';

class ProfileSettingsSnapshot {
  const ProfileSettingsSnapshot({this.activeProfile, this.learnerState});

  final ActiveProfileModel? activeProfile;
  final LearnerStateModel? learnerState;
}

class ProfileSaveResult {
  const ProfileSaveResult({
    required this.learnerState,
    required this.updatedProfile,
  });

  final LearnerStateModel learnerState;
  final ActiveProfileModel? updatedProfile;
}

class ProfileSettingsActions {
  const ProfileSettingsActions();

  Future<ProfileSettingsSnapshot> load(WidgetRef ref) async {
    final repository = await ref.read(profileRepositoryProvider.future);
    final activeProfile = await repository.readActiveProfile();
    if (activeProfile == null) {
      return const ProfileSettingsSnapshot();
    }

    final learnerStateRepository = await ref.read(
      learnerStateRepositoryProvider.future,
    );
    final learnerState =
        await learnerStateRepository.readCached(activeProfile.learnerId) ??
        await learnerStateRepository.fetchState(
          learnerId: activeProfile.learnerId,
        );

    return ProfileSettingsSnapshot(
      activeProfile: activeProfile,
      learnerState: learnerState,
    );
  }

  Future<ProfileSaveResult> save({
    required WidgetRef ref,
    required String phone,
    required ActiveProfileModel activeProfile,
    required Map<String, dynamic> updates,
    required String fullName,
    required String grade,
  }) async {
    final repository = await ref.read(profileRepositoryProvider.future);
    final updatedState = await repository.updateProfile(
      phone: phone,
      learnerId: activeProfile.learnerId,
      updates: updates,
    );

    ActiveProfileModel? updatedProfile;
    if (updates.containsKey('student_name') || updates.containsKey('grade')) {
      updatedProfile = ActiveProfileModel(
        phone: phone,
        learnerId: activeProfile.learnerId,
        studentName: updates.containsKey('student_name')
            ? fullName
            : activeProfile.studentName,
        grade: updates.containsKey('grade') ? grade : activeProfile.grade,
        division: activeProfile.division,
        avatar: activeProfile.avatar,
        onboardingCompleted: activeProfile.onboardingCompleted,
      );
      await repository.setActiveProfile(updatedProfile);
    }

    return ProfileSaveResult(
      learnerState: updatedState,
      updatedProfile: updatedProfile,
    );
  }

  Future<ProfileSettingsSnapshot> switchProfile({
    required WidgetRef ref,
    required String phone,
    required ProfileSummaryModel profile,
  }) async {
    final repository = await ref.read(profileRepositoryProvider.future);
    final learnerState = await repository.selectProfile(
      phone: phone,
      learnerId: profile.learnerId,
    );

    final activeProfile = ActiveProfileModel(
      phone: phone,
      learnerId: profile.learnerId,
      studentName: learnerState.profile?.studentName ?? profile.studentName,
      grade: profile.grade,
      division: profile.division,
      avatar: profile.avatar,
      onboardingCompleted: profile.onboardingCompleted,
    );
    await repository.setActiveProfile(activeProfile);

    return ProfileSettingsSnapshot(
      activeProfile: activeProfile,
      learnerState: learnerState,
    );
  }
}
