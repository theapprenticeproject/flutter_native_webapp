/**
 * cache/galleryPageCache.ts — keyed from EVERY value that affects the query result, so
 * a cache key missing a dimension can never poison the cache for a different caller.
 */

import type { GalleryPage } from "../db/gallery";
import type { ConfigSchema } from "../config/defaults";

const NAMESPACE = "gallery-page";

export interface GalleryCacheKeyParams {
  scopeMode: "assignment" | "school_grade";
  assignmentId?: string;
  state: string;
  district: string;
  school: string;
  grade: number;
  limit: number;
  cursor: number | null;
}

function cacheKeyFor(params: GalleryCacheKeyParams): Request {
  const parts = [
    params.scopeMode,
    params.assignmentId ?? "-",
    params.state,
    params.district,
    params.school,
    String(params.grade),
    String(params.limit),
    params.cursor === null ? "start" : String(params.cursor),
  ].map(encodeURIComponent);
  return new Request(`https://gallery-page.internal/${parts.join("/")}`);
}

export async function getCachedGalleryPage(params: GalleryCacheKeyParams): Promise<GalleryPage | null> {
  const cache = await caches.open(NAMESPACE);
  const hit = await cache.match(cacheKeyFor(params));
  return hit ? ((await hit.json()) as GalleryPage) : null;
}

export async function putCachedGalleryPage(
  params: GalleryCacheKeyParams,
  page: GalleryPage,
  cfg: Pick<ConfigSchema, "GALLERY_PAGE_CACHE_SECONDS">
): Promise<void> {
  if (cfg.GALLERY_PAGE_CACHE_SECONDS <= 0) return;
  const cache = await caches.open(NAMESPACE);
  await cache.put(
    cacheKeyFor(params),
    new Response(JSON.stringify(page), { headers: { "Cache-Control": `max-age=${cfg.GALLERY_PAGE_CACHE_SECONDS}` } })
  );
}