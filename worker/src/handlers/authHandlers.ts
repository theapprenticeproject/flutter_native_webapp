/**
 * handlers/authHandlers.ts
 *
 * /auth/redeem ALWAYS returns, in one call:
 *   - a phone-scoped token (`phone_token`), kept ONLY as a fallback credential: if the
 *     app ever loses its cached per-student token (cache cleared, reinstall, etc.) it
 *     can call /auth/select_profile with this phone token to re-derive a student token
 *     for whichever student it needs, without re-redeeming the magic link.
 *   - the FULL resume payload for EVERY student on the phone, each one carrying its OWN
 *     student-scoped token INLINE as `students[i].token`. This is the only place a
 *     student token is ever returned on this route — there is no separate top-level
 *     `token` field. The app reads `students[i].token` for whichever student it treats
 *     as active (`active_student_id` names the default/first one) and persists each
 *     student's token alongside that student's own cached profile data.
 *   - `active_student_id` naming the default student (first in Frappe's roster).
 *
 * /auth/select_profile is KEPT, purely as the fallback path: phone-scoped token + a
 * student_id in, a fresh student-scoped token out, embedded the same way (`token`
 * inside the payload body) so the shape matches one entry of redeem's `students` array.
 * The app only needs this when its locally cached student token for that student is
 * gone (expired, cache cleared) — NOT as part of normal profile switching if the token
 * is already cached locally.
 *
 * Tokens are fixed-TTL (cfg.STUDENT_TOKEN_TTL_SECONDS / cfg.PHONE_TOKEN_TTL_SECONDS) —
 * nothing refreshes them on a call. There is no refreshed_token anywhere in the
 * response surface, on this route or any other.
 *
 * Point tiers: only points_tier is returned — no next_tier, no points_to_next.
 * No raw storage key (object_key) is ever included in a resume payload.
 *
 * current_event_learning_unit does NOT appear anywhere in this payload. A student can
 * only ever have one event "on" at a time, so there is nothing to resume-pick between
 * multiple event tracks the way there is for current_learning_unit (the program
 * track). ALL event-track state — whether a student is enrolled in a given event, that
 * event's own current_learning_unit, and that event's own last_activity_type — comes
 * exclusively from /events/is_enrolled (see handlers/eventHandlers.ts). A resume
 * payload here only ever describes the PROGRAM track: current_learning_unit and
 * last_activity_type here are always the program track's values. If the app needs to
 * know whether the student has an open event and where to resume it, it calls
 * is_enrolled for that event_id — that is now the ONLY place event resume state lives,
 * full stop.
 *
 * do_later is shared the same way submit_video/submit_quiz/request_upload/
 * submit_artwork are: it takes the same optional context: "program" | "event" field
 * (handlers/laterHandlers.ts). Because do_later writes nothing, the app's own
 * knowledge of "what's open for this event" still resolves only through is_enrolled —
 * do_later's context is pure echo-back bookkeeping, never a source of resume state.
 */

import { checkBurst } from "../cache/rateLimitCache";
import { fetchFrappe } from "../frappe/client";
import { FRAPPE_METHODS } from "../frappe/mapRequest";
import { verifyMagicLinkV2, formatDest } from "../auth/magicLink";
import { mintPhoneToken, mintStudentToken } from "../auth/sessionToken";
import { requirePhoneToken } from "../auth/middleware";
import type { Env } from "../env";
import { invalidInput, rateLimited, studentNotFound } from "../env";
import { ok } from "../util/errors";
import { collectTelemetry } from "../telemetry/collector";
import { tierInfo } from "../constants/pointTiers";
import { config } from "../config/index";

interface RedeemBody {
  code?: string;
  _t?: unknown;
}
interface SelectProfileBody {
  student_id?: string;
  _t?: unknown;
}

/**
 * A student's most recent PROGRAM-track activity, as reported by Frappe's own
 * `last_activity_type` field. Exactly three non-null values are possible, plus null
 * for "no activity yet":
 *   - "video"      — most recent program activity was a submit_video call
 *   - "quiz"       — most recent program activity was a submit_quiz call
 *   - "submission" — most recent program activity was a submit_artwork call
 *   - null         — student has no recorded program activity yet
 * There is no event equivalent of this field here — see module docblock;
 * /events/is_enrolled reports its own last_activity_type, scoped to that one event_id.
 */
export type LastActivityType = "video" | "quiz" | "submission" | null;

/** One student's full resume payload, as Frappe returns it — same shape whether the
 *  phone has 1 student or 10, and same shape for redeem vs select_profile. Describes
 *  the PROGRAM track only; event-track state is never embedded here (see
 *  handlers/eventHandlers.ts::isEnrolled). Notably absent: current_event_learning_unit
 *  — removed entirely; see module docblock. */
interface ProfileResumeFields {
  student_id: string;
  name: string;
  grade: string;
  points: number;
  gems: number;
  current_learning_unit: string | null;
  last_activity_type: LastActivityType;
  state_id: string;
  district_id: string;
  school_id: string;
  state_name: string;
  district_name: string;
  school_name: string;
  course_id: string;
  language: string;
  updated_at: number;
}

interface RedeemMagicLinkResult {
  /** Every student on this phone, each with their full resume state. First element
   *  is the default. */
  students: ProfileResumeFields[];
}

/** Builds one student's response payload WITH its own token embedded inline. This is
 *  the only place a student token appears — never as a sibling top-level field.
 *  current_event_learning_unit is intentionally never added here (see module
 *  docblock) — event resume state lives only behind /events/is_enrolled. */
function resumePayload(r: ProfileResumeFields, studentToken: string): Record<string, unknown> {
  const tier = tierInfo(r.points);
  return {
    student_id: r.student_id,
    token: studentToken,
    name: r.name,
    grade: r.grade,
    points: r.points,
    points_tier: tier.points_tier,
    gems: r.gems,
    current_learning_unit: r.current_learning_unit,
    last_activity_type: r.last_activity_type,
    state_id: r.state_id,
    district_id: r.district_id,
    school_id: r.school_id,
    state_name: r.state_name,
    district_name: r.district_name,
    school_name: r.school_name,
    course_id: r.course_id,
    language: r.language,
    updated_at: r.updated_at,
  };
}

async function redeem(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const ip = req.headers.get("CF-Connecting-IP") ?? "unknown";
  const ipBurst = await checkBurst(`ip:${ip}`, "auth", cfg.RATE_LIMITS);
  if (!ipBurst.allowed) throw rateLimited("too many redeem attempts from this network");

  const body = (await req.json().catch(() => ({}))) as RedeemBody;
  if (!body.code || typeof body.code !== "string") throw invalidInput("code missing");

  // Pure stateless verify — no "used" check, no nonce store. Redeeming never consumes
  // the link; the same code verifies identically on every future call until expiry.
  const payload = await verifyMagicLinkV2(env.MAGIC_LINK_SECRET, body.code);

  const phoneBurst = await checkBurst(`phone:${payload.phone}`, "auth", cfg.RATE_LIMITS);
  if (!phoneBurst.allowed) throw rateLimited("too many redeem attempts for this phone");

  const frappeResult = await fetchFrappe<RedeemMagicLinkResult>(env, FRAPPE_METHODS.redeemMagicLink, {
    phone: payload.phone,
  });

  if (!frappeResult.students || frappeResult.students.length === 0) {
    throw studentNotFound("no student with an active enrollment for this phone");
  }

  const defaultStudent = frappeResult.students[0] as ProfileResumeFields;

  // Mint a phone token (fallback credential only) AND one fixed-TTL student token per
  // student in the roster — every student gets its token embedded directly in its own
  // payload object, nowhere else.
  const [phoneToken, studentTokens] = await Promise.all([
    mintPhoneToken(payload.phone, env, cfg.PHONE_TOKEN_TTL_SECONDS),
    Promise.all(frappeResult.students.map((s) => mintStudentToken(s.student_id, env, cfg.STUDENT_TOKEN_TTL_SECONDS))),
  ]);

  setStudentId(defaultStudent.student_id);

  const responseData: Record<string, unknown> = {
    phone_token: phoneToken,
    active_student_id: defaultStudent.student_id,
    students: frappeResult.students.map((s, i) => resumePayload(s, studentTokens[i] as string)),
  };
  if (payload.dest) responseData.dest = formatDest(payload.dest);

  ctx.waitUntil(collectTelemetry(env, defaultStudent.student_id, body._t).catch(() => {}));

  return ok(responseData);
}

/**
 * Fallback only: used when the app's locally cached student token is gone (expired,
 * cleared cache, reinstall) and it needs to re-derive one from its still-valid phone
 * token. Returns the same payload shape as one entry of redeem's `students` array,
 * with the freshly minted token embedded the same way (payload.token) — never as a
 * sibling field. Like redeem, never includes current_event_learning_unit.
 */
async function selectProfile(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const { phone } = await requirePhoneToken(req, env);

  const body = (await req.json().catch(() => ({}))) as SelectProfileBody;
  if (!body.student_id || typeof body.student_id !== "string") throw invalidInput("student_id missing");

  const resume = await fetchFrappe<ProfileResumeFields>(env, FRAPPE_METHODS.selectProfile, {
    phone,
    student_id: body.student_id,
  });

  const token = await mintStudentToken(resume.student_id, env, cfg.STUDENT_TOKEN_TTL_SECONDS);
  setStudentId(resume.student_id);

  ctx.waitUntil(collectTelemetry(env, resume.student_id, body._t).catch(() => {}));

  return ok({ active_student_id: resume.student_id, ...resumePayload(resume, token) });
}

export const authHandlers = { redeem, selectProfile };