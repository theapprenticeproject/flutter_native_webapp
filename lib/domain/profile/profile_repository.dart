import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import 'active_profile_model.dart';

/// Reads the student who is signed in on this phone. The sign-in (the link, the
/// students, the active one) is saved by `MagicLinkRepository`.
class ProfileRepository {
  ProfileRepository(this._localCache);

  final LocalCache _localCache;

  Future<ActiveProfileModel?> readActiveProfile() async {
    final raw = _localCache.getForeverRaw(CacheKeys.activeProfile());
    return raw == null ? null : ActiveProfileModel.fromJson(raw);
  }
}
