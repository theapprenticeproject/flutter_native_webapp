/**
 * frappe/client.ts — every Worker -> Frappe call carries Frappe's own API Key/Secret
 * header (Contract §3), against a dedicated service-account User scoped to only what
 * one dispatch module needs. A write is never blindly retried — a timed-out write that
 * actually committed, then retried, would double-award points or double-create a row.
 */

import { upstreamError, studentNotFound, notFound, conflict, invalidInput, serverError } from "../env";

interface FrappeEnv {
  FRAPPE_BASE_URL: string;
  FRAPPE_API_KEY: string;
  FRAPPE_API_SECRET: string;
}

const FRAPPE_TIMEOUT_MS = 8000;

const RETRYABLE_READ_METHODS = new Set([
  "get_profile",
  "progress_sync",
  "last_submission",
  "check_attempt_cap",
  "list_submissions",
  "get_submission",
  "get_profile_scope",
  "is_enrolled",
]);

async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function mapFrappeError(res: Response): Promise<never> {
  let frappeErrorCode = "";
  try {
    const body = (await res.json()) as { error_code?: string };
    frappeErrorCode = body.error_code ?? "";
  } catch {
    // unparseable error body — fall through to status-based mapping
  }

  if (res.status === 404) throw notFound("The requested resource was not found.");
  if (res.status === 409) throw conflict("This action has already reached its limit.");
  if (res.status === 403 || res.status === 401) throw upstreamError("Upstream authorization failure.");
  if (res.status === 417 || res.status === 400) {
    if (frappeErrorCode === "student_not_found") throw studentNotFound();
    throw invalidInput(frappeErrorCode || "Invalid input.");
  }
  if (res.status >= 500) throw upstreamError("Upstream service error — safe to retry.");
  throw serverError();
}

function jitter(ms: number): number {
  return ms + Math.floor(Math.random() * 150);
}

export async function fetchFrappe<T = Record<string, unknown>>(
  env: FrappeEnv,
  method: string,
  params: Record<string, unknown>,
  opts: { timeoutMs?: number } = {}
): Promise<T> {
  const url = `${env.FRAPPE_BASE_URL}/api/method/${method}`;
  const timeoutMs = opts.timeoutMs ?? FRAPPE_TIMEOUT_MS;
  const methodName = method.split(".").pop() ?? method;
  const canRetry = RETRYABLE_READ_METHODS.has(methodName);
  const maxAttempts = canRetry ? 2 : 1;

  let lastNetworkError: unknown = null;
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      if (attempt > 0) await new Promise((r) => setTimeout(r, jitter(200)));

      const res = await fetchWithTimeout(
        url,
        {
          method: "POST",
          headers: {
            Authorization: `token ${env.FRAPPE_API_KEY}:${env.FRAPPE_API_SECRET}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(params),
        },
        timeoutMs
      );

      if (!res.ok) {
        if (res.status >= 500 && canRetry && attempt < maxAttempts - 1) continue;
        return mapFrappeError(res);
      }

      const json = (await res.json()) as { message?: T } | T;
      return (json as { message?: T }).message !== undefined ? (json as { message: T }).message : (json as T);
    } catch (err) {
      lastNetworkError = err;
      if (canRetry && attempt < maxAttempts - 1) continue;
    }
  }

  throw upstreamError(
    `Frappe call to ${method} failed: ${lastNetworkError instanceof Error ? lastNetworkError.message : "network error"}`
  );
}