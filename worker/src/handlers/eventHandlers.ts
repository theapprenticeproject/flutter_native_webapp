/**
 * handlers/eventHandlers.ts
 *
 * /events/is_enrolled is the SOLE source of event-track status and resume information
 * in the whole API. There is no `current_event_learning_unit` field on any resume
 * payload (see handlers/authHandlers.ts) — a student can only ever have one event "on"
 * at a time, so there is nothing to disambiguate between multiple event tracks the way
 * there is for the program track's current_learning_unit. The app resolves "does this
 * student have an open event, and where do they resume it" entirely by calling
 * is_enrolled for the event_id it cares about; last_activity_type on that response is
 * the student's most recent activity type FOR THAT EVENT's track (never the program
 * track — that one lives on the resume payload instead).
 *
 * is_enrolled's last_activity_type uses the exact same three-value-plus-null vocabulary
 * as a resume payload's program-track last_activity_type (handlers/authHandlers.ts):
 * "video" | "quiz" | "submission" | null. The two fields share a type and meaning —
 * they just describe different tracks (event vs. program).
 *
 * do_later (handlers/laterHandlers.ts) is a pure no-op that also accepts this same
 * context: "program" | "event" field, purely for echo-back/analytics purposes — it
 * writes nothing anywhere, so it is never itself a source of resume state. Whatever a
 * student called do_later on, is_enrolled (for events) or the resume payload (for
 * program, via current_learning_unit / last_activity_type) remain the only two places
 * the app should ever look to find out "where is this student in this track."
 *
 * No `refreshed_token` anywhere (Contract §3/§4.5, Reference §0): tokens are
 * fixed-TTL, minted once at redeem/select_profile, never refreshed by any later call —
 * enroll and is_enrolled included.
 */

import { requireStudentToken } from "../auth/middleware";
import { fetchFrappe } from "../frappe/client";
import { FRAPPE_METHODS } from "../frappe/mapRequest";
import type { Env } from "../env";
import { invalidInput } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { withIdempotency } from "../cache/idempotency";
import { isValidIdempotencyKey } from "../util/ids";
import { collectTelemetry } from "../telemetry/collector";
import { config } from "../config/index";
import type { LastActivityType } from "./authHandlers";

interface EnrollBody {
  event_id?: string;
  idempotency_key?: string;
  _t?: unknown;
}

interface EnrollResult {
  enrolled: boolean;
  already_enrolled: boolean;
}

async function enroll(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as EnrollBody;
  if (!body.event_id) throw invalidInput("event_id missing");
  if (!isValidIdempotencyKey(body.idempotency_key)) throw invalidInput("idempotency_key missing or invalid");

  const { result, repeat } = await withIdempotency<EnrollResult>(
    "enroll_event",
    studentId,
    body.idempotency_key,
    cfg.IDEMPOTENCY_TTL_BY_ROUTE.enroll_event ?? cfg.DEFAULT_IDEMPOTENCY_TTL_SECONDS,
    () =>
      fetchFrappe<EnrollResult>(env, FRAPPE_METHODS.enrollEvent, {
        student_id: studentId,
        event_id: body.event_id,
      })
  );

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({
    event_id: body.event_id,
    student_id: studentId,
    enrolled: result.enrolled,
    already_enrolled: result.already_enrolled,
    repeat,
  });
}

interface IsEnrolledBody {
  event_id?: string;
  _t?: unknown;
}

interface IsEnrolledFrappeResult {
  enrolled: boolean;
  /** This event's own track activity type — NEVER the program track's. This is the
   *  only place in the entire API that reports an event's last_activity_type.
   *  Same vocabulary as the program track's: "video" | "quiz" | "submission" | null. */
  last_activity_type: LastActivityType;
  /** The event's own current learning unit, i.e. the event-track equivalent of a
   *  resume payload's current_learning_unit, scoped to this one event_id. Since a
   *  student has at most one event "on", this single call is the ONLY place this
   *  value lives — there is no current_event_learning_unit field anywhere else. */
  current_event_learning_unit: string | null;
}

async function isEnrolled(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const body = (await req.json().catch(() => ({}))) as IsEnrolledBody;
  if (!body.event_id) throw invalidInput("event_id missing");

  const result = await fetchFrappe<IsEnrolledFrappeResult>(env, FRAPPE_METHODS.isEnrolled, {
    student_id: studentId,
    event_id: body.event_id,
  });

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({
    enrolled: result.enrolled,
    last_activity_type: result.last_activity_type,
    current_event_learning_unit: result.current_event_learning_unit,
  });
}

export const eventHandlers = { enroll, isEnrolled };