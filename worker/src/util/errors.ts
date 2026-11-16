import type { AppError, ErrorCode } from "../env";

function stripNulls<T>(value: T): T {
  if (Array.isArray(value)) {
    let changed = false;
    const mapped = value.map((v) => {
      const s = stripNulls(v);
      if (s !== v) changed = true;
      return s;
    });
    return (changed ? mapped : value) as unknown as T;
  }
  if (value !== null && typeof value === "object" && !(value instanceof Date)) {
    const entries = Object.entries(value as Record<string, unknown>);
    let changed = false;
    const out: Record<string, unknown> = {};
    for (const [k, v] of entries) {
      if (v === null || v === undefined) {
        changed = true;
        continue;
      }
      const s = stripNulls(v);
      if (s !== v) changed = true;
      out[k] = s;
    }
    return (changed ? out : value) as T;
  }
  return value;
}

export interface OkOptions {
  httpStatus?: number;
}

/** v5: no more refreshed_token — tokens are fixed-TTL and never refreshed on a call. */
export function ok(data: Record<string, unknown>, opts: OkOptions = {}): Response {
  const body: Record<string, unknown> = { ok: true, data: stripNulls(data) };
  return new Response(JSON.stringify(body), {
    status: opts.httpStatus ?? 200,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

export function fail(code: ErrorCode, message: string, httpStatus = 400): Response {
  const body = { ok: false, error: { code, message } };
  return new Response(JSON.stringify(body), { status: httpStatus, headers: { "content-type": "application/json; charset=utf-8" } });
}

export function failFromAppError(err: AppError): Response {
  return fail(err.code, err.message, err.httpStatus);
}