/**
 * config/analytics.ts — every Durable Object / BigQuery / chat timing+size knob. DO
 * duration billing is allocated_memory (fixed 128MB) × active_seconds, so the idle
 * timeout is the only lever on DO cost — kept short on purpose.
 *
 * bqMaxFlushRetries is the cost-safety cap on the BQ retry loop: without it, a
 * persistently-failing BQ call (bad creds, outage, budget exhausted every day) would
 * keep re-arming the alarm forever, which directly costs DO active-seconds with no
 * bound. After this many consecutive failed retries, the DO drops the buffered batch
 * (logs it) instead of scheduling another retry — the alarm chain terminates.
 */

export interface AnalyticsConfig {
  sessionIdleTimeoutMs: number;
  sessionMaxLifetimeMs: number;
  chatIdleTimeoutMs: number;
  chatMaxHistoryTurns: number;
  chatMaxExchangesPerSession: number;
  chatMaxExchangesPerStudentPerDay: number;
  chatMaxContextBytes: number;
  bqFlushRetryDelayMs: number;
  /** Max number of retry attempts after the first failed flush, before giving up and
   *  dropping the buffer. 0 = no retries (fail once, drop immediately). Default 1 —
   *  exactly one retry, per the "only one retry" requirement. */
  bqMaxFlushRetries: number;
  bqDailyByteBudget: number;
  maxTapsPerRow: number;
  bqWriteTimeoutMs: number;
}

export const DEFAULT_ANALYTICS_CONFIG: AnalyticsConfig = {
  sessionIdleTimeoutMs: 2 * 60 * 1000,
  sessionMaxLifetimeMs: 2 * 60 * 60 * 1000,
  chatIdleTimeoutMs: 3 * 60 * 1000,
  chatMaxHistoryTurns: 12,
  chatMaxExchangesPerSession: 40,
  chatMaxExchangesPerStudentPerDay: 150,
  chatMaxContextBytes: 2048,
  bqFlushRetryDelayMs: 60 * 1000,
  bqMaxFlushRetries: 1,
  bqDailyByteBudget: 10 * 1024 * 1024 * 1024,
  maxTapsPerRow: 200,
  bqWriteTimeoutMs: 8000,
};

export interface AnalyticsConfigEnv {
  SESSION_IDLE_TIMEOUT_MS?: string;
  SESSION_MAX_LIFETIME_MS?: string;
  CHAT_IDLE_TIMEOUT_MS?: string;
  CHAT_MAX_HISTORY_TURNS?: string;
  CHAT_MAX_EXCHANGES_PER_SESSION?: string;
  CHAT_MAX_EXCHANGES_PER_STUDENT_PER_DAY?: string;
  CHAT_MAX_CONTEXT_BYTES?: string;
  BQ_FLUSH_RETRY_DELAY_MS?: string;
  BQ_MAX_FLUSH_RETRIES?: string;
  BQ_DAILY_BYTE_BUDGET?: string;
  MAX_TAPS_PER_ROW?: string;
  BQ_WRITE_TIMEOUT_MS?: string;
}

function positiveNumberOr(value: string | undefined, fallback: number): number {
  if (value === undefined) return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

/** Like positiveNumberOr but allows 0 (valid for bqMaxFlushRetries — "no retries"). */
function nonNegativeIntegerOr(value: string | undefined, fallback: number): number {
  if (value === undefined) return fallback;
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : fallback;
}

export function resolveAnalyticsConfig(env: AnalyticsConfigEnv): AnalyticsConfig {
  return {
    sessionIdleTimeoutMs: positiveNumberOr(env.SESSION_IDLE_TIMEOUT_MS, DEFAULT_ANALYTICS_CONFIG.sessionIdleTimeoutMs),
    sessionMaxLifetimeMs: positiveNumberOr(env.SESSION_MAX_LIFETIME_MS, DEFAULT_ANALYTICS_CONFIG.sessionMaxLifetimeMs),
    chatIdleTimeoutMs: positiveNumberOr(env.CHAT_IDLE_TIMEOUT_MS, DEFAULT_ANALYTICS_CONFIG.chatIdleTimeoutMs),
    chatMaxHistoryTurns: positiveNumberOr(env.CHAT_MAX_HISTORY_TURNS, DEFAULT_ANALYTICS_CONFIG.chatMaxHistoryTurns),
    chatMaxExchangesPerSession: positiveNumberOr(
      env.CHAT_MAX_EXCHANGES_PER_SESSION,
      DEFAULT_ANALYTICS_CONFIG.chatMaxExchangesPerSession
    ),
    chatMaxExchangesPerStudentPerDay: positiveNumberOr(
      env.CHAT_MAX_EXCHANGES_PER_STUDENT_PER_DAY,
      DEFAULT_ANALYTICS_CONFIG.chatMaxExchangesPerStudentPerDay
    ),
    chatMaxContextBytes: positiveNumberOr(env.CHAT_MAX_CONTEXT_BYTES, DEFAULT_ANALYTICS_CONFIG.chatMaxContextBytes),
    bqFlushRetryDelayMs: positiveNumberOr(env.BQ_FLUSH_RETRY_DELAY_MS, DEFAULT_ANALYTICS_CONFIG.bqFlushRetryDelayMs),
    bqMaxFlushRetries: nonNegativeIntegerOr(env.BQ_MAX_FLUSH_RETRIES, DEFAULT_ANALYTICS_CONFIG.bqMaxFlushRetries),
    bqDailyByteBudget: positiveNumberOr(env.BQ_DAILY_BYTE_BUDGET, DEFAULT_ANALYTICS_CONFIG.bqDailyByteBudget),
    maxTapsPerRow: positiveNumberOr(env.MAX_TAPS_PER_ROW, DEFAULT_ANALYTICS_CONFIG.maxTapsPerRow),
    bqWriteTimeoutMs: positiveNumberOr(env.BQ_WRITE_TIMEOUT_MS, DEFAULT_ANALYTICS_CONFIG.bqWriteTimeoutMs),
  };
}