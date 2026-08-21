import '../core/cache/cache_keys.dart';
import '../core/cache/local_cache.dart';
import '../models/class_session_window_model.dart';

class ClassSessionWindowRepository {
  ClassSessionWindowRepository(this._localCache);

  final LocalCache _localCache;

  ClassSessionWindowModel read(String learnerId) {
    final raw = _localCache.getForeverRaw(CacheKeys.sessionWindow(learnerId));
    if (raw == null) return ClassSessionWindowModel.empty(learnerId);
    return ClassSessionWindowModel.fromJson(raw);
  }

  bool hasCompletedUnitThisWindow(
    String learnerId,
    String unitKey,
    String? currentWindowStartDate,
  ) {
    final existing = read(learnerId);
    if (!existing.coversWindow(_windowStart(currentWindowStartDate))) {
      return false;
    }
    return existing.completedUnitKeysThisWindow.contains(unitKey);
  }

  int completedUnitCountThisWindow(
    String learnerId,
    String? currentWindowStartDate,
  ) {
    final existing = read(learnerId);
    if (!existing.coversWindow(_windowStart(currentWindowStartDate))) return 0;
    return existing.completedUnitKeysThisWindow.length;
  }

  Future<void> markUnitCompleted({
    required String learnerId,
    required String unitKey,
    String? windowResetsOn,
    String? windowStartDate,
  }) async {
    final existing = read(learnerId);
    final effectiveWindowStart = _windowStart(windowStartDate);
    final sameWindow = existing.coversWindow(effectiveWindowStart);
    final base = sameWindow
        ? existing
        : ClassSessionWindowModel.empty(learnerId);

    final updated = base.withUnitCompleted(
      unitKey,
      windowResetsOn: windowResetsOn,
      windowStartDate: effectiveWindowStart,
    );

    await _localCache.setForeverRaw(
      CacheKeys.sessionWindow(learnerId),
      updated.toJson(),
    );
  }

  Future<void> reset(String learnerId) async {
    await _localCache.delete(CacheKeys.sessionWindow(learnerId));
  }

  String _windowStart(String? serverWindowStart) {
    if (serverWindowStart != null && serverWindowStart.isNotEmpty) {
      return serverWindowStart;
    }
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    return '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }
}
