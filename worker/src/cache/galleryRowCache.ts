/**
 * cache/galleryRowCache.ts — keyed by submission_id alone, not by query/scope, so the
 * same image resolved through a school-level query and a state-level fallback is
 * signed and named exactly once per cache window. Sits below galleryPageCache in the
 * read path: a page-cache miss still avoids re-signing any row it's already seen.
 */

import type { ConfigSchema } from "../config/defaults";

const NAMESPACE = "gallery-row";

export interface CachedGalleryRow {
  url: string;
  uploaded: string;
  display_name?: string;
}

function rowCacheKey(submissionId: string): Request {
  return new Request(`https://gallery-row.internal/${encodeURIComponent(submissionId)}`);
}

export async function getCachedGalleryRow(submissionId: string): Promise<CachedGalleryRow | null> {
  const cache = await caches.open(NAMESPACE);
  const hit = await cache.match(rowCacheKey(submissionId));
  return hit ? ((await hit.json()) as CachedGalleryRow) : null;
}

export async function putCachedGalleryRow(
  submissionId: string,
  row: CachedGalleryRow,
  cfg: Pick<ConfigSchema, "GALLERY_ROW_CACHE_SECONDS">
): Promise<void> {
  if (cfg.GALLERY_ROW_CACHE_SECONDS <= 0) return;
  const cache = await caches.open(NAMESPACE);
  await cache.put(
    rowCacheKey(submissionId),
    new Response(JSON.stringify(row), { headers: { "Cache-Control": `max-age=${cfg.GALLERY_ROW_CACHE_SECONDS}` } })
  );
}

/** Called by the promotion/visibility path when a row is re-graded or hidden, so a stale cache entry never outlives the D1 write that superseded it. */
export async function invalidateCachedGalleryRow(submissionId: string): Promise<void> {
  const cache = await caches.open(NAMESPACE);
  await cache.delete(rowCacheKey(submissionId));
}