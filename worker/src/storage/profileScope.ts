/**
 * storage/profileScope.ts — Frappe is the scope authority for gallery (Contract §1.2).
 * Called only when the app's scope_cache_token is missing/expired/malformed (§8.2 step
 * 2); cached in the Worker Cache API for PROFILE_SCOPE_TTL_SECONDS so a run of gallery
 * opens within one token's window never re-hits Frappe even on a token miss within the
 * same isolate.
 */

import { fetchFrappe } from "../frappe/client";
import { FRAPPE_METHODS } from "../frappe/mapRequest";
import type { ConfigSchema } from "../config/defaults";
import type { Env } from "../env";

const CACHE_NAMESPACE = "profile-scope";

export function normalizeScopeValue(v: string): string {
  return v.trim().toLowerCase();
}

export interface ProfileScope {
  state: string;
  district: string;
  school: string;
  grade: number;
}

interface FrappeProfileScopeResult {
  state_id: string;
  district_id: string;
  school_id: string;
  grade: string | number;
}

export async function getProfileScope(
  env: Env,
  cfg: Pick<ConfigSchema, "PROFILE_SCOPE_TTL_SECONDS">,
  studentId: string
): Promise<ProfileScope> {
  const cache = await caches.open(CACHE_NAMESPACE);
  const cacheKey = new Request(`https://profile-scope.internal/${encodeURIComponent(studentId)}`);

  const cached = await cache.match(cacheKey);
  if (cached) return (await cached.json()) as ProfileScope;

  const raw = await fetchFrappe<FrappeProfileScopeResult>(env, FRAPPE_METHODS.getProfileScope, {
    student_id: studentId,
  });

  const scope: ProfileScope = {
    state: normalizeScopeValue(raw.state_id),
    district: normalizeScopeValue(raw.district_id),
    school: normalizeScopeValue(raw.school_id),
    grade: Number(raw.grade),
  };

  await cache.put(
    cacheKey,
    new Response(JSON.stringify(scope), { headers: { "Cache-Control": `max-age=${cfg.PROFILE_SCOPE_TTL_SECONDS}` } })
  );

  return scope;
}