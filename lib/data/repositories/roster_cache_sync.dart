import '../../core/cache/local_cache.dart';
import '../../models/profile_summary_model.dart';

class RosterCacheSync {
  RosterCacheSync._();

  static Future<void> patchRow(
    LocalCache localCache, {
    required String phone,
    required String learnerId,
    String? studentName,
    int? rollNumber,
    String? grade,
    String? division,
    String? avatar,
    bool? onboardingCompleted,
  }) async {
    final prefixes = ['v2:roster:$phone:', 'v2:profiles:$phone:'];

    for (final prefix in prefixes) {
      for (final key in localCache.keysWithPrefix(prefix)) {
        final raw = localCache.getForeverList(key, (json) => json);
        if (raw == null) continue;
        final rows = ProfileSummaryModel.listFromCache(raw);
        final idx = rows.indexWhere((r) => r.learnerId == learnerId);
        if (idx == -1) continue;

        final updated = rows[idx].copyWith(
          studentName: studentName,
          rollNumber: rollNumber,
          grade: grade,
          division: division,
          avatar: avatar,
          onboardingCompleted: onboardingCompleted,
        );
        final newRows = List<ProfileSummaryModel>.from(rows)..[idx] = updated;
        await localCache.setForeverRawList(
          key,
          ProfileSummaryModel.listToJson(newRows),
        );
      }
    }
  }

  static Future<void> patchManyRows(
    LocalCache localCache, {
    required String phone,
    required Map<String, Map<String, dynamic>> updatesByLearnerId,
  }) async {
    final prefixes = ['v2:roster:$phone:', 'v2:profiles:$phone:'];

    for (final prefix in prefixes) {
      for (final key in localCache.keysWithPrefix(prefix)) {
        final raw = localCache.getForeverList(key, (json) => json);
        if (raw == null) continue;
        var rows = ProfileSummaryModel.listFromCache(raw);
        var changed = false;

        for (final entry in updatesByLearnerId.entries) {
          final idx = rows.indexWhere((r) => r.learnerId == entry.key);
          if (idx == -1) continue;
          final u = entry.value;
          rows = List<ProfileSummaryModel>.from(rows)
            ..[idx] = rows[idx].copyWith(
              studentName: u['student_name'] as String?,
              rollNumber: (u['roll_number'] as num?)?.toInt(),
              grade: u['grade'] as String?,
              division: u['division'] as String?,
              avatar: u['avatar'] as String?,
            );
          changed = true;
        }

        if (changed) {
          await localCache.setForeverRawList(
            key,
            ProfileSummaryModel.listToJson(rows),
          );
        }
      }
    }
  }
}
