/**
 * config/defaults.ts — every tunable in one place, three-layer precedence resolved by
 * config/index.ts: D1 app_config > wrangler [vars] > these defaults.
 *
 * v5 changes (this rewrite):
 *  - Tokens are fixed-TTL, not rolling. STUDENT_TOKEN_TTL_SECONDS / PHONE_TOKEN_TTL_SECONDS
 *    replace TOKEN_ROLLING_WINDOW_SECONDS. Nothing refreshes a token on a call anymore —
 *    the student token is minted once (redeem, or select_profile as a fallback) and the
 *    app re-derives a new one via select_profile (using its still-valid phone token)
 *    once it expires.
 *  - Gallery scope is fully configurable now: GALLERY_SCOPE_FIELDS declares every field
 *    that CAN scope a query, in fixed physical priority order (this mirrors the object
 *    key's own field order and must never be reordered independently of it).
 *    GALLERY_FALLBACK_CASCADE declares which of those fields the read path actually
 *    tries, in order, when a narrower level comes back empty — e.g. start scoped at
 *    assignment_id, fall back to school, then district, then state. Both are
 *    [vars]/D1-overridable so you can start scoped at assignment and widen later
 *    without a code change.
 *  - GALLERY_SORT: "recent" (promoted_at desc) or "updated" (sort by last updated).
 *    [vars]-overridable default; the app can still override per-request via ?sort=.
 *  - GALLERY_PAGE_CACHE_SECONDS default is one day (86400) — worker-side page cache,
 *    per Worker-side caching requirement.
 */

export type RouteClass = "write" | "read" | "chat" | "telemetry" | "auth";
export type SubmissionType = "image" | "video" | "text";
export type ActivityContext = "program" | "event";
export type GallerySortMode = "recent" | "updated";

/** Every field that can ever scope a gallery query, in fixed physical priority order.
 *  This order mirrors the object key's own field layout and the fallback cascade must
 *  always be a subset of this list, in this relative order. */
export const GALLERY_SCOPE_FIELDS = ["assignment_id", "state", "district", "school", "grade"] as const;
export type GalleryScopeField = (typeof GALLERY_SCOPE_FIELDS)[number];

export interface RateLimitRule {
  max: number;
  windowSeconds: number;
}

export interface ConfigSchema {
  ID_RANDOM_CHARS: number;

  // Default context ("program" | "event") used when submit_video/submit_quiz/
  // request_upload/submit_artwork omit `context` entirely.
  DEFAULT_SUBMISSION_CONTEXT: ActivityContext;

  MEDIA_MODE_GALLERY: "public" | "presigned";
  MEDIA_MODE_OWN: "public" | "presigned";
  PRESIGN_WINDOW_SECONDS: number;
  PRESIGN_EXPIRY_SECONDS: number;

  UPLOAD_MAX_BYTES_IMAGE: number;
  UPLOAD_MAX_BYTES_VIDEO: number;
  UPLOAD_URL_EXPIRY_SECONDS: number;

  // Gallery scoping — fully configurable. GALLERY_FALLBACK_CASCADE is the ordered list
  // of levels the read path actually tries (each entry must be one of
  // GALLERY_SCOPE_FIELDS). Start scoped at assignment_id by putting it first; drop it
  // later by editing this list — no code change needed either way.
  GALLERY_FALLBACK_CASCADE: readonly GalleryScopeField[];
  GALLERY_FALLBACK_ENABLED: boolean;
  GALLERY_SORT: GallerySortMode;
  GALLERY_PAGE_DEFAULT: number;
  GALLERY_PAGE_MAX: number;
  GALLERY_PAGE_CACHE_SECONDS: number;
  GALLERY_ROW_CACHE_SECONDS: number;
  GALLERY_SHOW_NAMES: "own_school" | "all" | "none";
  PROFILE_SCOPE_TTL_SECONDS: number;

  INDEX_BATCH_MAX: number;

  POINT_TIERS_VERSION: number;

  MAGIC_TTL_SECONDS_HOME: number;
  MAGIC_TTL_SECONDS_FEEDBACK: number;
  MAGIC_TTL_SECONDS_GALLERY: number;
  MAGIC_TTL_SECONDS_SUBMIT: number;
  MAGIC_TTL_SECONDS_LATER: number;

  // Fixed-TTL tokens — minted once, never refreshed on a call. [vars]-overridable.
  STUDENT_TOKEN_TTL_SECONDS: number;
  PHONE_TOKEN_TTL_SECONDS: number;

  CONFIG_REFRESH_SECONDS: number;

  TURN_WINDOW_SECONDS: number;
  TURN_BUDGETS: Readonly<Record<string, number>>;
  DEFAULT_TURN_BUDGET: number;

  IDEMPOTENCY_TTL_BY_ROUTE: Readonly<Record<string, number>>;
  DEFAULT_IDEMPOTENCY_TTL_SECONDS: number;

  RATE_LIMITS: Readonly<Record<RouteClass, RateLimitRule>>;
}

export const RUNTIME_OVERRIDABLE_KEYS: ReadonlySet<keyof ConfigSchema> = new Set([
  "DEFAULT_SUBMISSION_CONTEXT",
  "MEDIA_MODE_GALLERY",
  "MEDIA_MODE_OWN",
  "PRESIGN_WINDOW_SECONDS",
  "PRESIGN_EXPIRY_SECONDS",
  "UPLOAD_MAX_BYTES_IMAGE",
  "UPLOAD_MAX_BYTES_VIDEO",
  "UPLOAD_URL_EXPIRY_SECONDS",
  "GALLERY_FALLBACK_CASCADE",
  "GALLERY_FALLBACK_ENABLED",
  "GALLERY_SORT",
  "GALLERY_PAGE_DEFAULT",
  "GALLERY_PAGE_MAX",
  "GALLERY_PAGE_CACHE_SECONDS",
  "GALLERY_ROW_CACHE_SECONDS",
  "GALLERY_SHOW_NAMES",
  "PROFILE_SCOPE_TTL_SECONDS",
  "INDEX_BATCH_MAX",
  "POINT_TIERS_VERSION",
  "STUDENT_TOKEN_TTL_SECONDS",
  "PHONE_TOKEN_TTL_SECONDS",
]);

export const DEFAULT_CONFIG: ConfigSchema = {
  ID_RANDOM_CHARS: 10,

  DEFAULT_SUBMISSION_CONTEXT: "program",

  MEDIA_MODE_GALLERY: "presigned",
  MEDIA_MODE_OWN: "presigned",
  PRESIGN_WINDOW_SECONDS: 6 * 60 * 60,
  PRESIGN_EXPIRY_SECONDS: 24 * 60 * 60,

  UPLOAD_MAX_BYTES_IMAGE: 10 * 1024 * 1024,
  UPLOAD_MAX_BYTES_VIDEO: 50 * 1024 * 1024,
  UPLOAD_URL_EXPIRY_SECONDS: 3600,

  // Start scoped at assignment_id (narrowest, highest priority); fall back through
  // school -> district -> state as assignment-level results run out. Edit this array
  // (via [vars] or D1 app_config) to change scoping without a redeploy.
  GALLERY_FALLBACK_CASCADE: ["assignment_id", "school", "district", "state"],
  GALLERY_FALLBACK_ENABLED: true,
  GALLERY_SORT: "recent",
  GALLERY_PAGE_DEFAULT: 24,
  GALLERY_PAGE_MAX: 50,
  GALLERY_PAGE_CACHE_SECONDS: 86400, // one day, worker-side
  GALLERY_ROW_CACHE_SECONDS: 86400,
  GALLERY_SHOW_NAMES: "own_school",
  PROFILE_SCOPE_TTL_SECONDS: 3600,

  INDEX_BATCH_MAX: 100,

  POINT_TIERS_VERSION: 1,

  MAGIC_TTL_SECONDS_HOME: 90 * 24 * 60 * 60,
  MAGIC_TTL_SECONDS_FEEDBACK: 30 * 24 * 60 * 60,
  MAGIC_TTL_SECONDS_GALLERY: 30 * 24 * 60 * 60,
  MAGIC_TTL_SECONDS_SUBMIT: 14 * 24 * 60 * 60,
  MAGIC_TTL_SECONDS_LATER: 14 * 24 * 60 * 60,

  STUDENT_TOKEN_TTL_SECONDS: 30 * 24 * 60 * 60, // 30 days, fixed — no refresh
  PHONE_TOKEN_TTL_SECONDS: 90 * 24 * 60 * 60, // 90 days, fixed — outlives student tokens

  CONFIG_REFRESH_SECONDS: 300,

  TURN_WINDOW_SECONDS: 120,
  TURN_BUDGETS: {
    "/submission/request_upload": 2,
    "/submission/submit_artwork": 2,
    "/submission/do_later": 2,
    "/auth/redeem": 2,
    "/auth/select_profile": 2,
    "/progress/sync": 2,
    "/submission/get": 2,
  },
  DEFAULT_TURN_BUDGET: 1,

  IDEMPOTENCY_TTL_BY_ROUTE: {
    submit_artwork: 86400,
    submit_video: 3600,
    submit_quiz: 3600,
    enroll_event: 86400,
  },
  DEFAULT_IDEMPOTENCY_TTL_SECONDS: 3600,

  RATE_LIMITS: {
    write: { max: 20, windowSeconds: 60 },
    read: { max: 60, windowSeconds: 60 },
    chat: { max: 10, windowSeconds: 60 },
    telemetry: { max: 30, windowSeconds: 60 },
    auth: { max: 120, windowSeconds: 60 },
  },
};