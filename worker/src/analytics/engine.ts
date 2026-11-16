import type { Env, RouteClass } from "../env";

export interface RequestAnalyticsPoint {
  path: string;
  routeClass: RouteClass;
  studentId: string | null;
  outcome: "ok" | "error";
  errorCode: string | null;
  httpMethod: string;
  httpStatus: number;
  colo: string | null;
  tlsVersion: string | null;
  httpProtocol: string | null;
  asOrganization: string | null;
  cacheStatus: string | null;
  requestContentType: string | null;
  responseContentType: string | null;
  idempotencyRepeat: boolean | null;
  rayId: string | null;
  queryString: string | null;
  frappeMethodCalled: string | null;
  frappeCallCount: number | null;
  durableObjectClass: string | null;
  requestBodyBytes: number | null;
  responseBodyBytes: number | null;
  rateLimitRemaining: number | null;
  turnBudgetUsed: number | null;
}

const MAX_QUERY_STRING_BLOB_CHARS = 300;
const STRIPPED_QUERY_PARAMS = ["scope_cache_token", "token", "code"];

export function sanitizeQueryStringForAnalytics(rawSearch: string): string {
  if (!rawSearch) return "";
  let params: URLSearchParams;
  try {
    params = new URLSearchParams(rawSearch);
  } catch {
    return "";
  }
  for (const key of STRIPPED_QUERY_PARAMS) {
    if (params.has(key)) params.set(key, "redacted");
  }
  const out = params.toString();
  return out.length > MAX_QUERY_STRING_BLOB_CHARS ? out.slice(0, MAX_QUERY_STRING_BLOB_CHARS) : out;
}

export function writeAnalyticsPoint(env: Env, point: RequestAnalyticsPoint): void {
  try {
    env.REQUEST_ANALYTICS.writeDataPoint({
      indexes: [point.studentId ?? "anonymous"],
      blobs: [
        point.path,
        point.routeClass,
        point.outcome,
        point.errorCode ?? "",
        point.colo ?? "",
        point.httpMethod,
        point.cacheStatus ?? "",
        point.tlsVersion ?? "",
        point.httpProtocol ?? "",
        point.asOrganization ?? "",
        point.requestContentType ?? "",
        point.idempotencyRepeat === null ? "" : String(point.idempotencyRepeat),
        point.rayId ?? "",
        point.responseContentType ?? "",
        point.queryString ?? "",
        point.frappeMethodCalled ?? "",
        point.durableObjectClass ?? "",
        "",
        "",
        "",
      ],
      doubles: [
        point.requestBodyBytes ?? -1,
        point.responseBodyBytes ?? -1,
        point.httpStatus,
        point.rateLimitRemaining ?? -1,
        point.turnBudgetUsed ?? -1,
        point.frappeCallCount ?? -1,
      ],
    });
  } catch {
  }
}