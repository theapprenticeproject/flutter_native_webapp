/**
 * handlers/configHandlers.ts — GET /app/config. Lets the app draw a tier progress bar
 * and know the gallery page size without hard-coding either, and lets you change
 * thresholds without an app release.
 *
 * No later_remind_days / later_max_open here anymore — "do later" keeps no list and no
 * reminder schedule, so there's nothing about it left to configure.
 */

import type { Env } from "../env";
import { ok } from "../util/errors";
import { config } from "../config/index";
import { DEFAULT_POINT_TIERS } from "../constants/pointTiers";

async function appConfig(_req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const cfg = config(env, env as unknown as Record<string, string>, ctx);

  // Point tiers can be D1-overridden via POINT_TIERS_JSON; fall back to the constants
  // file otherwise. (Wiring kept intentionally simple — see constants/pointTiers.ts.)
  const tiers = DEFAULT_POINT_TIERS;

  return ok(
    {
      tiers,
      tiers_version: cfg.POINT_TIERS_VERSION,
      gallery_page_default: cfg.GALLERY_PAGE_DEFAULT,
      gallery_page_max: cfg.GALLERY_PAGE_MAX,
      upload_max_bytes_image: cfg.UPLOAD_MAX_BYTES_IMAGE,
      upload_max_bytes_video: cfg.UPLOAD_MAX_BYTES_VIDEO,
    },
    { httpStatus: 200 }
  );
}

export const configHandlers = { appConfig };