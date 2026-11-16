/**
 * constants/pointTiers.ts — edit thresholds here. Every caller (login, select_profile,
 * sync, last_submission, submit_video, submit_quiz) reads through tierInfo(), so a
 * threshold change here applies immediately — tier is always derived from current
 * points, never stored.
 *
 * v5 change: tierInfo() returns ONLY points_tier now. next_tier/points_to_next are no
 * longer computed or exposed anywhere in the API surface.
 */

export interface PointTier {
  id: string;
  min: number;
}

export const DEFAULT_POINT_TIERS: PointTier[] = [
  { id: "bronze", min: 0 },
  { id: "silver", min: 1000 },
  { id: "gold", min: 5000 },
  { id: "platinum", min: 10000 },
];

export interface TierInfo {
  points_tier: string;
}

export function tierInfo(points: number, tiers: PointTier[] = DEFAULT_POINT_TIERS): TierInfo {
  let current = tiers[0] as PointTier;
  for (const t of tiers) {
    if (points >= t.min) {
      current = t;
    } else {
      break;
    }
  }
  return { points_tier: current.id };
}