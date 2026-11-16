/**
 * handlers/telemetryHandlers.ts — /telemetry/flush. Fallback only, used when the app's
 * local buffer is non-empty and ~60s have passed with no other call to piggyback on. This
 * route's entire purpose is delivering telemetry, so the DO call is synchronous (not
 * waitUntil) — there's no other response payload to prioritize.
 */

import { requireStudentToken } from "../auth/middleware";
import type { Env } from "../env";
import { invalidInput } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { collectTelemetrySync } from "../telemetry/collector";

interface FlushBody {
  _t?: unknown;
}

async function flush(
  req: Request,
  env: Env,
  _ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "telemetry");

  const body = (await req.json().catch(() => ({}))) as FlushBody;
  if (!body._t || typeof body._t !== "object" || Object.keys(body._t).length === 0) {
    throw invalidInput("_t missing or entirely empty");
  }

  const accepted = await collectTelemetrySync(env, studentId, body._t);
  return ok({ accepted });
}

export const telemetryHandlers = { flush };
