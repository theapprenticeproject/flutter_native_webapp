/// A tier from `/app/config`: its id and the points where it starts.
typedef PointTier = ({String id, int min});

/// Where the student is on the level ladder (R-87).
class LevelProgress {
  const LevelProgress({
    required this.name,
    required this.nextName,
    required this.label,
    required this.fraction,
  });

  /// For example "Bronze Buddy".
  final String name;

  /// The next level, or null at the top.
  final String? nextName;

  /// For example "120 / 1000", or just the points at the top.
  final String label;

  /// How far the student is inside this level, 0 to 1.
  final double fraction;
}

String _buddyName(String id) =>
    id.isEmpty ? '' : '${id[0].toUpperCase()}${id.substring(1)} Buddy';

/// The level for [points], from the Worker's tiers (R-41: the names and the
/// limits are not hardcoded). Null when there are no tiers, for example when
/// the Worker could not be reached.
LevelProgress? levelProgress(int points, List<PointTier> tiers) {
  if (tiers.isEmpty) return null;
  final sorted = [...tiers]..sort((a, b) => a.min.compareTo(b.min));
  final p = points < 0 ? 0 : points;

  var index = 0;
  for (var i = 0; i < sorted.length; i++) {
    if (p >= sorted[i].min) index = i;
  }
  final tier = sorted[index];
  final next = index + 1 < sorted.length ? sorted[index + 1] : null;

  return LevelProgress(
    name: _buddyName(tier.id),
    nextName: next == null ? null : _buddyName(next.id),
    label: next == null ? '$p' : '$p / ${next.min}',
    fraction: next == null
        ? 1.0
        : ((p - tier.min) / (next.min - tier.min)).clamp(0.0, 1.0),
  );
}
