/**
 * handlers/progressHandlers.ts — points_awarded/points_total/points_tier only (no
 * next_tier/points_to_next). submit_video/submit_quiz accept an explicit
 * `context: "program" | "event"` field, defaulting to cfg.DEFAULT_SUBMISSION_CONTEXT
 * when omitted, via the shared parseActivityContext validator. No Worker-side cap
 * enforcement anywhere in this file — Frappe owns every cap and every reward
 * computation. No refreshed_token anywhere — tokens are fixed-TTL, minted once at
 * redeem/select_profile time and never refreshed on a call.
 */

import { requireStudentToken } from "../auth/middleware";
import { fetchFrappe } from "../frappe/client";
import { FRAPPE_METHODS } from "../frappe/mapRequest";
import type { Env, ActivityContext } from "../env";
import { invalidInput, parseActivityContext } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { withIdempotency } from "../cache/idempotency";
import { isValidIdempotencyKey } from "../util/ids";
import { collectTelemetry } from "../telemetry/collector";
import { signSubmission, type RawSubmission } from "../storage/resign";
import { config } from "../config/index";
import { tierInfo } from "../constants/pointTiers";

interface SubmitVideoBody {
  unit_id?: string;
  watched?: boolean;
  idempotency_key?: string;
  context?: unknown;
  _t?: unknown;
}
interface SubmitVideoFrappeResult {
  points_awarded: number;
  points_total: number;
  updated_at: number;
}

async function submitVideo(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as SubmitVideoBody;
  if (!body.unit_id) throw invalidInput("unit_id missing");
  if (typeof body.watched !== "boolean") throw invalidInput("watched missing or not boolean");
  if (!isValidIdempotencyKey(body.idempotency_key)) throw invalidInput("idempotency_key missing or invalid");

  const activityContext: ActivityContext = parseActivityContext(body.context, cfg.DEFAULT_SUBMISSION_CONTEXT);

  const { result, repeat } = await withIdempotency(
    "submit_video",
    studentId,
    body.idempotency_key,
    cfg.IDEMPOTENCY_TTL_BY_ROUTE.submit_video ?? cfg.DEFAULT_IDEMPOTENCY_TTL_SECONDS,
    () =>
      fetchFrappe<SubmitVideoFrappeResult>(env, FRAPPE_METHODS.submitVideo, {
        student_id: studentId,
        unit_id: body.unit_id,
        watched: body.watched,
        context: activityContext,
      })
  );

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  const tier = tierInfo(result.points_total);
  return ok({
    points_awarded: result.points_awarded,
    points_total: result.points_total,
    points_tier: tier.points_tier,
    context: activityContext,
    repeat,
    updated_at: result.updated_at,
  });
}

interface SubmitQuizBody {
  unit_id?: string;
  answers?: Array<{ question_id: string; selected_key: string }>;
  idempotency_key?: string;
  context?: unknown;
  _t?: unknown;
}
interface SubmitQuizFrappeResult {
  correct_count: number;
  total_count: number;
  points_awarded: number;
  points_total: number;
  updated_at: number;
}

async function submitQuiz(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as SubmitQuizBody;
  if (!body.unit_id) throw invalidInput("unit_id missing");
  if (!Array.isArray(body.answers) || body.answers.length === 0) throw invalidInput("answers missing or empty");
  for (const a of body.answers) {
    // Only bare identifiers ever cross the wire — never question text, option text, or
    // the answer key. The Worker passes question_id/selected_key through untouched and
    // never inspects their content.
    if (!a.question_id || typeof a.selected_key !== "string") {
      throw invalidInput("each answer needs question_id and selected_key");
    }
  }
  if (!isValidIdempotencyKey(body.idempotency_key)) throw invalidInput("idempotency_key missing or invalid");

  const activityContext: ActivityContext = parseActivityContext(body.context, cfg.DEFAULT_SUBMISSION_CONTEXT);

  const { result, repeat } = await withIdempotency(
    "submit_quiz",
    studentId,
    body.idempotency_key,
    cfg.IDEMPOTENCY_TTL_BY_ROUTE.submit_quiz ?? cfg.DEFAULT_IDEMPOTENCY_TTL_SECONDS,
    () =>
      fetchFrappe<SubmitQuizFrappeResult>(env, FRAPPE_METHODS.submitQuiz, {
        student_id: studentId,
        unit_id: body.unit_id,
        answers: body.answers,
        context: activityContext,
      })
  );

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  const tier = tierInfo(result.points_total);
  return ok({
    correct_count: result.correct_count,
    total_count: result.total_count,
    points_awarded: result.points_awarded,
    points_total: result.points_total,
    points_tier: tier.points_tier,
    context: activityContext,
    repeat,
    updated_at: result.updated_at,
  });
}

interface SyncBody {
  last_updated?: number;
  _t?: unknown;
}
interface SyncFrappeResult {
  changed: boolean;
  updated_at: number;
  points?: number;
  gems?: number;
  current_learning_unit?: string | null;
  last_activity_type?: string | null;
  last_submission?: RawSubmission | null;
}

async function sync(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "read");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as SyncBody;
  if (typeof body.last_updated !== "number" || !Number.isInteger(body.last_updated)) {
    throw invalidInput("last_updated missing or not an integer");
  }

  const result = await fetchFrappe<SyncFrappeResult>(env, FRAPPE_METHODS.progressSync, {
    student_id: studentId,
    last_updated: body.last_updated,
  });

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  const data: Record<string, unknown> = { changed: result.changed, updated_at: result.updated_at };

  if (result.changed) {
    data.points = result.points;
    if (typeof result.points === "number") {
      const tier = tierInfo(result.points);
      data.points_tier = tier.points_tier;
    }
    data.gems = result.gems;
    data.current_learning_unit = result.current_learning_unit;
    data.last_activity_type = result.last_activity_type;

    if (result.last_submission) {
      data.last_submission = await signSubmission(env, result.last_submission, cfg);
    }
  }

  return ok(data);
}

interface LastSubmissionBody {
  last_updated?: number;
  _t?: unknown;
}
interface LastSubmissionFrappeResult {
  has_update: boolean;
  points: number;
  gems: number;
  last_submission?: RawSubmission | null;
}

async function lastSubmission(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "read");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as LastSubmissionBody;
  if (typeof body.last_updated !== "number" || !Number.isInteger(body.last_updated)) {
    throw invalidInput("last_updated missing or not an integer");
  }

  // Frappe's last_submission must return points/gems on EVERY call now, not only when
  // an update exists.
  const result = await fetchFrappe<LastSubmissionFrappeResult>(env, FRAPPE_METHODS.lastSubmission, {
    student_id: studentId,
    last_updated: body.last_updated,
  });

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  const tier = tierInfo(result.points);
  const data: Record<string, unknown> = {
    has_update: result.has_update,
    points: result.points,
    points_tier: tier.points_tier,
    gems: result.gems,
  };
  if (result.has_update && result.last_submission) {
    data.last_submission = await signSubmission(env, result.last_submission, cfg);
  }

  return ok(data);
}

export const progressHandlers = { submitVideo, submitQuiz, sync, lastSubmission };