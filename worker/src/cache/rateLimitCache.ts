import type { RouteClass } from "../env";
import type { RateLimitRule } from "../config/defaults";

const NAMESPACE = "rate-limit";

export interface BurstCheckResult {
  allowed: boolean;
}

export async function checkBurst(
  key: string,
  routeClass: RouteClass,
  rateLimits: Readonly<Record<RouteClass, RateLimitRule>>
): Promise<BurstCheckResult> {
  const limit = rateLimits[routeClass];
  const cache = await caches.open(NAMESPACE);
  const windowStart = Math.floor(Date.now() / 1000 / limit.windowSeconds);
  const cacheKey = new Request(`https://rl.internal/${routeClass}/${encodeURIComponent(key)}/${windowStart}`);

  const hit = await cache.match(cacheKey);
  const count = hit ? Number(await hit.text()) : 0;
  if (count >= limit.max) return { allowed: false };

  await cache.put(cacheKey, new Response(String(count + 1), { headers: { "Cache-Control": `max-age=${limit.windowSeconds}` } }));
  return { allowed: true };
}