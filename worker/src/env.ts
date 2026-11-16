/**
 * env.ts — bindings/secrets Cloudflare injects, plus the error vocabulary every handler
 * throws against. Error codes match API_Contract.md §2.2.
 *
 * v5 state (carried forward from v4, still true):
 *  - No attempt-cap / event-cap / reward-ceiling enforcement lives here or anywhere in
 *    the Worker. Frappe owns all caps and all reward computation (including the quiz
 *    1-point-per-correct-answer total and a submission's first-attempt bonus) — the
 *    Worker is a thin, trusted pass-through for student_id + context + payload.
 *    CONFLICT is still a valid wire error code (Frappe can still return it and the
 *    Worker forwards it untouched), but the Worker never independently decides "cap
 *    reached" itself.
 *  - Every activity route (submit_video, submit_quiz, request_upload, submit_artwork)
 *    accepts an explicit `context: "program" | "event"` field, defaulting to
 *    DEFAULT_SUBMISSION_CONTEXT when omitted — parseActivityContext() is the single
 *    shared validator every handler uses. do_later accepts and echoes the same field,
 *    purely inertly (it calls Frappe for nothing and writes no state).
 *  - Tokens are fixed-TTL, minted once (student token: at /auth/redeem, inline per
 *    student, or at /auth/select_profile as a fallback re-derivation; phone token: at
 *    /auth/redeem only). NOTHING refreshes a token on a later call — there is no
 *    `refreshed_token` field anywhere in the response surface, on any route. This file
 *    intentionally carries no TOKEN_ROLLING_WINDOW_SECONDS or similar rolling-refresh
 *    knob — that concept does not exist in this version of the API.
 */

export interface Env {
  DB: D1Database; 
  
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_ACCOUNT_ID: string;
  R2_SUBMISSIONS_BUCKET_NAME: string;

  MAGIC_LINK_SECRET: string;
  PHONE_TOKEN_SECRET: string;
  STUDENT_TOKEN_SECRET: string;
  GALLERY_SCOPE_TOKEN_SECRET: string;
  INTERNAL_API_SECRET: string;

  FRAPPE_BASE_URL: string;
  FRAPPE_API_KEY: string;
  FRAPPE_API_SECRET: string;

  GCS_SERVICE_ACCOUNT_JSON: string;
  GCS_AUTHENTICATED_BUCKET: string;

  AI_PROVIDER_API_KEY: string;
  AI_PROVIDER_BASE_URL: string;
  AI_PROVIDER_MODEL: string;

  BQ_SERVICE_ACCOUNT_JSON: string;
  BQ_PROJECT_ID: string;
  BQ_DATASET: string;
  BQ_ENABLED?: string;

  // ── Non-secret [vars] — all strings, resolved through config/index.ts::config() ──
  GALLERY_FALLBACK_ENABLED?: string;
  GALLERY_FALLBACK_CASCADE?: string;
  GALLERY_SORT?: string;
  GALLERY_PAGE_DEFAULT?: string;
  GALLERY_PAGE_MAX?: string;
  GALLERY_PAGE_CACHE_SECONDS?: string;
  GALLERY_ROW_CACHE_SECONDS?: string;
  GALLERY_SHOW_NAMES?: string;
  PRESIGN_WINDOW_SECONDS?: string;
  PRESIGN_EXPIRY_SECONDS?: string;
  UPLOAD_MAX_BYTES_IMAGE?: string;
  UPLOAD_MAX_BYTES_VIDEO?: string;
  UPLOAD_URL_EXPIRY_SECONDS?: string;
  PROFILE_SCOPE_TTL_SECONDS?: string;
  CONFIG_REFRESH_SECONDS?: string;
  ID_RANDOM_CHARS?: string;
  POINT_TIERS_VERSION?: string;

  // Default submission/activity context when the app omits one — "program" by
  // default, settable per-environment without a code change.
  DEFAULT_SUBMISSION_CONTEXT?: string;

  // Fixed-TTL token lifetimes — [vars]-overridable, never a rolling window.
  STUDENT_TOKEN_TTL_SECONDS?: string;
  PHONE_TOKEN_TTL_SECONDS?: string;

  SESSION_IDLE_TIMEOUT_MS?: string;
  SESSION_MAX_LIFETIME_MS?: string;
  CHAT_IDLE_TIMEOUT_MS?: string;
  CHAT_MAX_HISTORY_TURNS?: string;
  CHAT_MAX_EXCHANGES_PER_SESSION?: string;
  CHAT_MAX_EXCHANGES_PER_STUDENT_PER_DAY?: string;
  CHAT_MAX_CONTEXT_BYTES?: string;
  BQ_FLUSH_RETRY_DELAY_MS?: string;
  BQ_MAX_FLUSH_RETRIES?: string;
  BQ_DAILY_BYTE_BUDGET?: string;
  MAX_TAPS_PER_ROW?: string;
  BQ_WRITE_TIMEOUT_MS?: string;

  ENVIRONMENT: "staging" | "production";

  STUDENT_SESSION: DurableObjectNamespace;
  CHAT_SESSION: DurableObjectNamespace;

  REQUEST_ANALYTICS: AnalyticsEngineDataset;
}

export type RouteClass = "write" | "read" | "chat" | "telemetry" | "auth";
export type SubmissionType = "image" | "video";
export type ActivityContext = "program" | "event";

export type ErrorCode =
  | "UNAUTHORIZED"
  | "STUDENT_NOT_FOUND"
  | "INVALID_INPUT"
  | "NOT_FOUND"
  | "NOT_READY"
  | "UPSTREAM_ERROR"
  | "RATE_LIMITED"
  | "CONFLICT"
  | "SERVER_ERROR"
  | "upload_not_confirmed"
  | "upload_size_invalid"
  | "upload_type_mismatch";

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly httpStatus: number;
  constructor(code: ErrorCode, message: string, httpStatus = 400) {
    super(message);
    this.code = code;
    this.httpStatus = httpStatus;
  }
}

export const unauthorized = (msg = "Unauthorized") => new AppError("UNAUTHORIZED", msg, 401);
export const studentNotFound = (msg = "Student not found") => new AppError("STUDENT_NOT_FOUND", msg, 404);
export const invalidInput = (msg: string) => new AppError("INVALID_INPUT", msg, 400);
export const notFound = (msg: string) => new AppError("NOT_FOUND", msg, 404);
export const notReady = (msg = "Not ready yet") => new AppError("NOT_READY", msg, 409);
export const upstreamError = (msg: string) => new AppError("UPSTREAM_ERROR", msg, 502);
export const rateLimited = (msg = "Rate limit exceeded") => new AppError("RATE_LIMITED", msg, 429);
export const conflict = (msg: string) => new AppError("CONFLICT", msg, 409);
export const serverError = (msg = "Internal server error") => new AppError("SERVER_ERROR", msg, 500);

export const VALID_ACTIVITY_CONTEXTS: readonly ActivityContext[] = ["program", "event"] as const;

/**
 * The ONE place every activity route (submit_video, submit_quiz, request_upload,
 * submit_artwork, do_later) validates/defaults `context`. Shared so every endpoint
 * behaves identically — omit context → fallback (DEFAULT_SUBMISSION_CONTEXT); anything
 * other than "program"/"event" → INVALID_INPUT; no Worker-side cap logic keyed off this
 * value anywhere, it is purely routing information forwarded to Frappe as-is (or, for
 * do_later, not forwarded anywhere at all — see handlers/laterHandlers.ts).
 */
export function parseActivityContext(raw: unknown, fallback: ActivityContext): ActivityContext {
  if (raw === undefined || raw === null || raw === "") return fallback;
  if (raw === "program" || raw === "event") return raw;
  throw invalidInput('context must be "program" or "event"');
}