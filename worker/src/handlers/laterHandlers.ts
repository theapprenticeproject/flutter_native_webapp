/**
 * handlers/laterHandlers.ts — "do later" is the ONLY way a student moves past a
 * program OR event assignment without submitting. It is a pure no-op on the server:
 *
 *   - nothing is written to D1
 *   - nothing is sent to Frappe
 *   - no reminder, no "open items" list, nothing kept anywhere
 *
 * The assignment's progress field simply stays blank/unset in Frappe, because no
 * submission call was ever made for it — and blank already means "not done" by
 * convention on the progress side. Calling do_later twice, or never removing it,
 * changes nothing: there is no state here to go stale or need cleanup.
 *
 * do_later accepts the same optional `context: "program" | "event"` field as
 * submit_video/submit_quiz/request_upload/submit_artwork, validated and defaulted the
 * same way (parseActivityContext + cfg.DEFAULT_SUBMISSION_CONTEXT). This is still pure
 * routing information — since the call writes nothing anywhere, the context value
 * changes NOTHING about what the Worker does; it exists purely so the response can
 * echo back which track the app meant to skip, for the app's own local
 * bookkeeping/analytics, and so a future Frappe-side feature (e.g. a "later" list) has
 * the field available on day one without another Worker rewrite.
 *
 * do_later is NEVER a source of resume state, for either track. A student's program
 * resume state always comes from the resume payload (current_learning_unit,
 * last_activity_type — handlers/authHandlers.ts); a student's event resume state
 * always comes from /events/is_enrolled (current_event_learning_unit,
 * last_activity_type scoped to that event_id — handlers/eventHandlers.ts). Calling
 * do_later with context: "event" does not register, open, or affect enrollment for
 * that event in any way — enrollment itself is exclusively /events/enroll, and
 * resuming it is exclusively /events/is_enrolled.
 *
 * idempotency_key is still not accepted here — this route changes no state, so there
 * is nothing for an idempotency key to dedupe.
 *
 * The only real behavior left is: authenticate the student, validate/default context,
 * rate-limit the call (routeClass "write" — the same burst limiter every other write
 * route uses, so this can't be hammered), and return success so the app can move on.
 */

import { requireStudentToken } from "../auth/middleware";
import type { Env, ActivityContext } from "../env";
import { invalidInput, parseActivityContext } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { FIELD_PATTERNS } from "../storage/keys";
import { collectTelemetry } from "../telemetry/collector";
import { config } from "../config/index";

interface DoLaterBody {
  assignment_id?: string;
  context?: unknown;
  _t?: unknown;
}

async function doLater(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as DoLaterBody;
  if (!body.assignment_id || !FIELD_PATTERNS.assignment_id.test(body.assignment_id)) {
    throw invalidInput("assignment_id missing or malformed");
  }

  const activityContext: ActivityContext = parseActivityContext(body.context, cfg.DEFAULT_SUBMISSION_CONTEXT);

  // Intentionally nothing else happens here — no D1 row, no Frappe call, no token
  // minting of any kind (tokens are fixed-TTL and never refreshed by any call — see
  // env.ts). Progress for this assignment stays blank (= not done), and the app moves
  // on to the quiz. context is echoed back purely as confirmation of what was skipped —
  // it is never written anywhere and is never a source of resume state (see module
  // docblock: that's always the resume payload for program, is_enrolled for event).
  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({ assignment_id: body.assignment_id, context: activityContext, status: "later" });
}

export const laterHandlers = { doLater };