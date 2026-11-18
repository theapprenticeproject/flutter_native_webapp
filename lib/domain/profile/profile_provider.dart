import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/local_cache_provider.dart';
import 'active_profile_model.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = FutureProvider<ProfileRepository>((
  ref,
) async {
  return ProfileRepository(await ref.read(localCacheProvider.future));
});

/// The student who is signed in on this phone, or null.
final activeProfileProvider = FutureProvider<ActiveProfileModel?>((ref) async {
  final repository = await ref.read(profileRepositoryProvider.future);
  return repository.readActiveProfile();
});
