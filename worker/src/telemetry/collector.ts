/**
 * telemetry/collector.ts — Contract §9.5 step 5: binding happens once, uniformly,
 * regardless of which route carried _t. This file strips _t off the request, forwards
 * the whole batch to the calling student's StudentSession DO in one call, and never
 * tries to reassemble a row's "start" and "end" across two different calls — by the
 * time a row reaches here it is already a complete, finished record (§9.1-§9.4); the
 * app is responsible for that completeness.
 *
 * A malformed/oversized _t on a piggybacked call is dropped silently and never fails
 * the real request it rode in on (§9.5 step 6) — collectTelemetry never throws.
 */

import type { Env } from "../env";

interface TelemetryBatch {
  sessions?: Array<Record<string, unknown>>;
  screen_activity?: Array<Record<string, unknown>>;
  errors?: Array<Record<string, unknown>>;
}

function isTelemetryBatch(v: unknown): v is TelemetryBatch {
  return typeof v === "object" && v !== null;
}

function rowCount(batch: TelemetryBatch): number {
  return (batch.sessions?.length ?? 0) + (batch.screen_activity?.length ?? 0) + (batch.errors?.length ?? 0);
}

async function forwardToStudentSession(env: Env, studentId: string, batch: TelemetryBatch): Promise<void> {
  const id = env.STUDENT_SESSION.idFromName(studentId);
  const stub = env.STUDENT_SESSION.get(id);
  await stub.fetch("https://do.internal/touch", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ studentId, routeClass: "telemetry", batch }),
  });
}

/** Piggybacked path — never throws, never blocks the real request's own response. */
export async function collectTelemetry(env: Env, studentId: string, batch: unknown): Promise<void> {
  if (!isTelemetryBatch(batch)) return;
  if (rowCount(batch) === 0) return;
  try {
    await forwardToStudentSession(env, studentId, batch);
  } catch {
    // telemetry must never fail the calling request
  }
}

/** /telemetry/flush path — the one route where a bad _t IS an error, so this can surface INVALID_INPUT. */
export async function collectTelemetrySync(env: Env, studentId: string, batch: unknown): Promise<boolean> {
  if (!isTelemetryBatch(batch) || rowCount(batch) === 0) return false;
  await forwardToStudentSession(env, studentId, batch);
  return true;
}