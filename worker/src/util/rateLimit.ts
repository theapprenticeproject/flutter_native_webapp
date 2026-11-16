/**
 * util/rateLimit.ts — Cache API burst limiting only. Eventually consistent and
 * per-location, which is the right trade for abuse control at this scale — not meant
 * for exact accounting (that's StudentSession's in-memory sliding window).
 */

import { checkBurst } from "../cache/rateLimitCache";
import type { Env, RouteClass } from "../env";
import { rateLimited } from "../env";
import { config } from "../config/index";

export async function enforceRateLimit(env: Env, studentId: string, routeClass: RouteClass): Promise<void> {
  const cfg = config(env, env as unknown as Record<string, string>);
  const burst = await checkBurst(studentId, routeClass, cfg.RATE_LIMITS);
  if (!burst.allowed) {
    throw rateLimited(`rate limit exceeded for ${routeClass}`);
  }
}