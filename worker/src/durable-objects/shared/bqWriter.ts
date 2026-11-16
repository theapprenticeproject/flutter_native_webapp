/**
 * durable-objects/shared/bqWriter.ts — tabledata.insertAll, a plain JSON REST endpoint
 * callable directly via fetch() with a cached OAuth2 bearer token.
 *
 * NOTE: there is no R2 dead-letter spill anymore. If the daily byte budget is exceeded,
 * or the insertAll call fails, this throws — the caller (StudentSession/ChatSession's
 * alarm handler) catches it, keeps the buffered rows in memory, and retries on the next
 * alarm (see bqFlushRetryDelayMs). Rows are only lost if the DO itself is evicted before
 * a retry succeeds — an accepted trade now that nothing is spilled to R2.
 *
 * BQ_ENABLED is a master kill switch, resolved from [vars] with no code change needed
 * to flip it. When "false" (or any value other than "true"/unset), bqInsertAll() returns
 * immediately with { inserted: 0 } — no OAuth token mint, no budget check, no fetch.
 * Callers (StudentSession.flushToBigQuery / ChatSession.flushToBigQuery) see this as an
 * ordinary successful flush and clear their buffers, exactly as if the rows had been
 * written. This is intentional: disabling BQ should stop accumulation too, not pile rows
 * up in DO memory indefinitely waiting for BQ to come back. Default is enabled (unset or
 * "true") to match prior always-on behavior.
 */

import { resolveAnalyticsConfig, type AnalyticsConfigEnv } from "../../config/analytics";
import { getGoogleAccessTokenCached, parseServiceAccountJson } from "../../storage/gcsAuth";
import { utcDateString } from "../../util/time";

interface BqEnv extends AnalyticsConfigEnv {
  BQ_SERVICE_ACCOUNT_JSON: string;
  BQ_PROJECT_ID: string;
  BQ_DATASET: string;
  /** Master on/off switch for all BQ writes. "false" disables; unset or "true" enables. */
  BQ_ENABLED?: string;
}

const BQ_INSERTALL_SCOPE = "https://www.googleapis.com/auth/bigquery.insertdata";
const BQ_API_BASE = "https://bigquery.googleapis.com/bigquery/v2";

const LIVE_BUDGET_NAMESPACE = "bq-write-budget";

function isBqEnabled(env: BqEnv): boolean {
  return env.BQ_ENABLED !== "false";
}

function buildInsertAllBody(rows: Record<string, unknown>[]): { body: string; byteLength: number } {
  const body = JSON.stringify({ ignoreUnknownValues: false, rows: rows.map((json) => ({ json })) });
  return { body, byteLength: body.length };
}

async function checkAndReserveWriteBudget(estimatedBytes: number, budget: number): Promise<boolean> {
  const cache = await caches.open(LIVE_BUDGET_NAMESPACE);
  const dayKey = new Request(`https://bqbudget.internal/${utcDateString()}`);

  const hit = await cache.match(dayKey);
  const usedBytes = hit ? Number(await hit.text()) : 0;
  if (usedBytes + estimatedBytes > budget) return false;

  const recheck = await cache.match(dayKey);
  const recheckUsed = recheck ? Number(await recheck.text()) : usedBytes;
  if (recheckUsed + estimatedBytes > budget) return false;

  await cache.put(dayKey, new Response(String(recheckUsed + estimatedBytes), { headers: { "Cache-Control": "max-age=86400" } }));
  return true;
}

async function refundWriteBudget(estimatedBytes: number): Promise<void> {
  const cache = await caches.open(LIVE_BUDGET_NAMESPACE);
  const dayKey = new Request(`https://bqbudget.internal/${utcDateString()}`);
  const hit = await cache.match(dayKey);
  const usedBytes = hit ? Number(await hit.text()) : 0;
  const refunded = Math.max(0, usedBytes - estimatedBytes);
  await cache.put(dayKey, new Response(String(refunded), { headers: { "Cache-Control": "max-age=86400" } }));
}

interface InsertAllRowError {
  index: number;
  errors: Array<{ reason: string; message: string }>;
}

async function bqInsertAllCall(env: BqEnv, table: string, body: string, writeTimeoutMs: number): Promise<void> {
  const sa = parseServiceAccountJson(env.BQ_SERVICE_ACCOUNT_JSON);
  const token = await getGoogleAccessTokenCached(sa, BQ_INSERTALL_SCOPE);

  const url = `${BQ_API_BASE}/projects/${env.BQ_PROJECT_ID}/datasets/${env.BQ_DATASET}/tables/${table}/insertAll`;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), writeTimeoutMs);
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body,
      signal: controller.signal,
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`BQ insertAll to ${table} failed: ${res.status} ${text.slice(0, 500)}`);
    }

    const resultBody = (await res.json().catch(() => ({}))) as { insertErrors?: InsertAllRowError[] };
    if (resultBody.insertErrors && resultBody.insertErrors.length > 0) {
      throw new Error(
        `BQ insertAll to ${table} returned ${resultBody.insertErrors.length} row-level error(s): ${JSON.stringify(
          resultBody.insertErrors
        ).slice(0, 500)}`
      );
    }
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Inserts rows into BQ. Throws on budget-exhaustion or on any insert failure — the
 * caller is responsible for keeping rows buffered and retrying (no R2 spill here).
 *
 * When BQ_ENABLED is "false", this is a no-op: returns { inserted: 0 } immediately,
 * before the budget check, before minting an OAuth token, before any fetch. Callers
 * treat the return the same as a successful write and clear their buffers.
 */
export async function bqInsertAll(env: BqEnv, table: string, rows: Record<string, unknown>[]): Promise<{ inserted: number }> {
  if (rows.length === 0) return { inserted: 0 };

  if (!isBqEnabled(env)) {
    return { inserted: 0 };
  }

  const cfg = resolveAnalyticsConfig(env);

  const { body, byteLength: estimatedBytes } = buildInsertAllBody(rows);
  const budgetOk = await checkAndReserveWriteBudget(estimatedBytes, cfg.bqDailyByteBudget);
  if (!budgetOk) {
    throw new Error(`BQ daily write budget exhausted — insert to ${table} (${estimatedBytes} bytes) was not sent`);
  }

  try {
    await bqInsertAllCall(env, table, body, cfg.bqWriteTimeoutMs);
    return { inserted: rows.length };
  } catch (err) {
    await refundWriteBudget(estimatedBytes);
    throw err;
  }
} 