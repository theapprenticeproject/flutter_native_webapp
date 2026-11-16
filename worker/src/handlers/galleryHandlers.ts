/**
 * handlers/galleryHandlers.ts — Contract §8.2, read top to bottom:
 * 1. App calls GET /gallery with only assignment_id/grade/sort/limit/cursor, plus
 *    optionally a scope_cache_token from a previous response.
 * 2. Worker resolves scope: a valid scope_cache_token is trusted directly with NO
 *    Frappe call; otherwise Frappe's get_profile_scope is called, cached, and a fresh
 *    scope_cache_token is minted for the app to echo back next time.
 * 3. Worker queries D1's gallery_items — always the listing source, never Frappe,
 *    never a raw R2 list(), via the config-driven fallback cascade
 *    (cfg.GALLERY_FALLBACK_CASCADE / cfg.GALLERY_FALLBACK_ENABLED).
 * 4. Worker checks its signed-URL cache before minting new signatures (inside
 *    fetchGalleryPage / db/gallery.ts).
 * 5. Response includes the page, matched_level, fallback_applied, and the
 *    (possibly freshly-minted) scope_cache_token for next time.
 *
 * state/district/school are never read from the frontend (§2.1) and never echoed in
 * the top-level response — that display concern belongs to /profile/get_profile's
 * state_name/district_name/school_name, which the app already has from login.
 *
 * The page-cache key (cache/galleryPageCache.ts::GalleryCacheKeyParams) is keyed by
 * every dimension that affects the query, including `scopeMode`, which here just
 * records whether this query was scoped by assignment_id or purely by location
 * (school/district/state) — it is derived locally from whether assignmentId is
 * present, not read from config (there is no such config key).
 *
 * No `refreshed_token` anywhere (Contract §3/§4.5, Reference §0): tokens are
 * fixed-TTL, minted once at redeem/select_profile, never refreshed by any later call,
 * gallery included.
 */

import { requireStudentToken } from "../auth/middleware";
import type { Env } from "../env";
import { invalidInput } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { config } from "../config/index";
import { fetchGalleryPage } from "../db/gallery";
import { getCachedGalleryPage, putCachedGalleryPage, type GalleryCacheKeyParams } from "../cache/galleryPageCache";
import { getProfileScope } from "../storage/profileScope";
import { mintScopeToken, verifyScopeToken } from "../storage/scopeToken";
import { collectTelemetry } from "../telemetry/collector";

const ASSIGNMENT_ID_PATTERN = /^[A-Za-z0-9_-]{3,80}$/;
const GRADE_PATTERN = /^[1-9][0-9]?$/;

async function gallery(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "read");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const url = new URL(req.url);

  // Only assignment_id/grade/sort/limit/cursor/scope_cache_token are ever read from
  // the query string — never state/district/school, not even as optional overrides.
  const assignmentId = url.searchParams.get("assignment_id") ?? undefined;
  const assignmentIdSource = assignmentId !== undefined ? "query" : "default";
  if (assignmentId !== undefined && !ASSIGNMENT_ID_PATTERN.test(assignmentId)) {
    throw invalidInput("assignment_id is malformed");
  }

  const gradeParam = url.searchParams.get("grade");
  let grade: number | undefined;
  const gradeSource = gradeParam !== null && gradeParam !== "" ? "query" : "default";
  if (gradeParam !== null && gradeParam !== "") {
    if (!GRADE_PATTERN.test(gradeParam)) throw invalidInput("grade is malformed");
    grade = Number(gradeParam);
  }

  const sortParam = url.searchParams.get("sort");
  const sort = sortParam ?? cfg.GALLERY_SORT;
  const sortSource = sortParam ? "query" : "default";

  const limitParam = url.searchParams.get("limit");
  let limit = cfg.GALLERY_PAGE_DEFAULT;
  if (limitParam !== null && limitParam !== "") {
    const n = Number(limitParam);
    if (!Number.isInteger(n) || n < 1) throw invalidInput("limit is malformed");
    limit = Math.min(n, cfg.GALLERY_PAGE_MAX);
  }

  const cursorParam = url.searchParams.get("cursor");
  let cursor: number | null = null;
  if (cursorParam !== null && cursorParam !== "") {
    const n = Number(cursorParam);
    if (!Number.isInteger(n) || n < 0) throw invalidInput("cursor is malformed");
    cursor = n;
  }

  // Step 2: resolve scope. A valid token skips Frappe entirely; otherwise Frappe is
  // consulted (and the result cached) and a fresh token is minted at the end.
  const scopeTokenParam = url.searchParams.get("scope_cache_token");
  let profileScope = await verifyScopeToken(scopeTokenParam, env.GALLERY_SCOPE_TOKEN_SECRET);
  if (!profileScope) {
    profileScope = await getProfileScope(env, cfg, studentId);
  }
  if (grade === undefined) grade = profileScope.grade;

  // Step 3/4: D1 query with page+row caching. scopeMode records whether assignment_id
  // narrows this query (vs. pure location/grade scoping) — purely a cache-key
  // dimension, independent of the fallback cascade itself.
  const cacheParams: GalleryCacheKeyParams = {
    scopeMode: assignmentId ? "assignment" : "school_grade",
    assignmentId,
    state: profileScope.state,
    district: profileScope.district,
    school: profileScope.school,
    grade,
    limit,
    cursor,
  };

  let page = await getCachedGalleryPage(cacheParams);
  if (!page) {
    page = await fetchGalleryPage(env.DB, env, cfg, {
      assignmentId,
      state: profileScope.state,
      district: profileScope.district,
      school: profileScope.school,
      grade,
      cursor,
      limit,
    });
    ctx.waitUntil(putCachedGalleryPage(cacheParams, page, cfg));
  }

  const scopeCacheToken = await mintScopeToken(profileScope, cfg.PROFILE_SCOPE_TTL_SECONDS, env.GALLERY_SCOPE_TOKEN_SECRET);

  ctx.waitUntil(collectTelemetry(env, studentId, null).catch(() => {}));

  const responseData: Record<string, unknown> = {
    assignment_id: assignmentId,
    grade: String(grade),
    sort,
    params_source: { assignment_id: assignmentIdSource, grade: gradeSource, sort: sortSource },
    matched_level: page.matched_level,
    fallback_applied: page.fallback_applied,
    images: page.images,
    cursor: page.cursor,
    truncated: page.truncated,
    scope_cache_token: scopeCacheToken,
  };

  return ok(responseData);
}

export const galleryHandlers = { gallery };