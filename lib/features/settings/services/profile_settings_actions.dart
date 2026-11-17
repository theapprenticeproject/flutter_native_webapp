import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/profile/active_profile_model.dart';
import '../../../domain/learner/learner_state_model.dart';
import '../../../domain/learner/learner_state_provider.dart';
import '../../../domain/profile/profile_provider.dart';

class ProfileSettingsSnapshot {
  const ProfileSettingsSnapshot({this.activeProfile, this.learnerState});

  final ActiveProfileModel? activeProfile;
  final LearnerStateModel? learnerState;
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
}
