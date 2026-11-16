/**
 * durable-objects/StudentSession.ts — one instance per student. Holds the telemetry
 * queue exactly as Contract §9 describes it: three streams (sessions, screen_activity,
 * errors), each row already a finished record by the time it arrives here (§9.5 step
 * 4 — no reassembly across calls). Flushed to BigQuery on an idle alarm, with a hard
 * lifetime cap for a session that never goes idle. Also carries the per-student daily
 * chat-exchange budget, since that must survive across multiple ChatSession instances.
 *
 * In-memory only — no storage.put per request except the alarm registration. If a BQ
 * flush fails (network error, budget exhausted), the buffer is kept and retried after
 * bqFlushRetryDelayMs — nothing is spilled to R2. Retries are capped at
 * bqMaxFlushRetries (default 1 retry total): once exhausted, the buffer is DROPPED and
 * logged rather than scheduling another alarm. This bounds DO active-time (= DO cost)
 * for a persistently-failing BQ call — without a cap, a bad batch would re-arm the
 * alarm forever.
 */

import { resolveAnalyticsConfig } from "../config/analytics";
import type { Env, RouteClass } from "../env";
import { bqInsertAll } from "./shared/bqWriter";
import { packTapsToBase64, type RawTap } from "../storage/packTaps";
import { utcDateString } from "../util/time";

interface TelemetrySessionRow {
  session_id: string;
  started_at: string;
  os?: string;
  app_version?: string;
  screen_width?: number;
  screen_height?: number;
}

interface TelemetryScreenActivityRow {
  session_id: string;
  screen: string;
  from_screen?: string;
  occurred_at: string;
  active_ms: number;
  tap_count?: number;
  scroll_max?: number;
  taps?: RawTap[];
}

interface TelemetryErrorRow {
  session_id?: string;
  screen?: string;
  occurred_at: string;
  error_type: string;
  error_message?: string;
}

interface TelemetryBatch {
  sessions?: TelemetrySessionRow[];
  screen_activity?: TelemetryScreenActivityRow[];
  errors?: TelemetryErrorRow[];
}

interface BufferedScreenActivityRow {
  session_id: string;
  screen: string;
  from_screen?: string;
  occurred_at: string;
  active_ms: number;
  tap_count: number;
  scroll_max?: number;
  packed_taps: string | null;
}

interface TelemetryBuffer {
  sessions: TelemetrySessionRow[];
  screenActivity: BufferedScreenActivityRow[];
  errors: TelemetryErrorRow[];
}

const EMPTY_BUFFER = (): TelemetryBuffer => ({ sessions: [], screenActivity: [], errors: [] });

// Hard-coded rate limits, same table the config layer exposes — read live from config
// per-request would need an env; DO reads its own copy to avoid importing config/index's
// D1-coupled resolver into the DO runtime.
const RATE_LIMITS: Record<RouteClass, { max: number; windowSeconds: number }> = {
  write: { max: 20, windowSeconds: 60 },
  read: { max: 60, windowSeconds: 60 },
  chat: { max: 10, windowSeconds: 60 },
  telemetry: { max: 30, windowSeconds: 60 },
  auth: { max: 120, windowSeconds: 60 },
};

export class StudentSession {
  private state: DurableObjectState;
  private env: Env;
  private studentId: string | null = null;
  private counters: Partial<Record<RouteClass, number[]>> = {};
  private buffer: TelemetryBuffer = EMPTY_BUFFER();
  private firstActivityAtMs: number | null = null;
  private chatExchangesToday = 0;
  private chatExchangesDayKey = "";
  /** Consecutive failed flush attempts for the CURRENT buffer contents. Reset to 0 the
   *  moment a flush succeeds or the buffer is dropped/cleared. */
  private flushFailureCount = 0;

  constructor(state: DurableObjectState, env: Env) {
    this.state = state;
    this.env = env;
  }

  async fetch(req: Request): Promise<Response> {
    const url = new URL(req.url);

    try {
      switch (url.pathname) {
        case "/touch": {
          const { studentId, routeClass, batch } = (await req.json()) as {
            studentId: string;
            routeClass: RouteClass;
            batch?: TelemetryBatch;
          };
          this.studentId = studentId;
          const allowed = this.checkRateLimit(routeClass);
          if (batch) this.addTelemetry(batch);
          await this.scheduleAlarms();
          return Response.json({ allowed });
        }
        case "/chat-cap-check": {
          const { maxPerDay } = (await req.json()) as { maxPerDay: number };
          const allowed = this.checkAndIncrementDailyChatCap(maxPerDay);
          await this.scheduleAlarms();
          return Response.json({ allowed });
        }
        case "/force-flush": {
          await this.flushToBigQuery();
          return Response.json({ flushed: true });
        }
        default:
          return new Response("not found", { status: 404 });
      }
    } catch (err) {
      return Response.json({ error: err instanceof Error ? err.message : "unknown DO error" }, { status: 500 });
    }
  }

  private checkRateLimit(routeClass: RouteClass): boolean {
    const now = Date.now();
    const limit = RATE_LIMITS[routeClass];
    const windowMs = limit.windowSeconds * 1000;
    const existing = this.counters[routeClass] ?? [];
    const recent = existing.filter((t) => now - t < windowMs);
    if (recent.length >= limit.max) {
      this.counters[routeClass] = recent;
      return false;
    }
    recent.push(now);
    this.counters[routeClass] = recent;
    return true;
  }

  private checkAndIncrementDailyChatCap(maxPerDay: number): boolean {
    const today = utcDateString();
    if (this.chatExchangesDayKey !== today) {
      this.chatExchangesDayKey = today;
      this.chatExchangesToday = 0;
    }
    if (this.chatExchangesToday >= maxPerDay) return false;
    this.chatExchangesToday++;
    return true;
  }

  /**
   * Each row arrives here already finished (§9.1-§9.4) — sessions is written once per
   * app open and never re-sent, screen_activity is one row per completed visit, errors
   * is one row per caught error. No start/end reassembly happens anywhere in this
   * method; every row pushed is appended verbatim to its stream's buffer.
   */
  private addTelemetry(batch: TelemetryBatch): void {
    const cfg = resolveAnalyticsConfig(this.env);

    if (batch.sessions?.length) this.buffer.sessions.push(...batch.sessions);

    if (batch.screen_activity?.length) {
      for (const visit of batch.screen_activity) {
        const rawTaps = visit.taps ?? [];
        // tap_count is always the client's true total, independent of how many
        // individual taps got packed below (§9.3.1) — never recomputed from taps.length.
        const trueTapCount = typeof visit.tap_count === "number" ? visit.tap_count : rawTaps.length;

        this.buffer.screenActivity.push({
          session_id: visit.session_id,
          screen: visit.screen,
          from_screen: visit.from_screen,
          occurred_at: visit.occurred_at,
          active_ms: visit.active_ms,
          tap_count: trueTapCount,
          scroll_max: visit.scroll_max,
          packed_taps: rawTaps.length > 0 ? packTapsToBase64(rawTaps, cfg.maxTapsPerRow) : null,
        });
      }
    }

    if (batch.errors?.length) this.buffer.errors.push(...batch.errors);
  }

  private async scheduleAlarms(): Promise<void> {
    const cfg = resolveAnalyticsConfig(this.env);
    const now = Date.now();

    if (this.firstActivityAtMs === null) this.firstActivityAtMs = now;

    const idleDeadline = now + cfg.sessionIdleTimeoutMs;
    const hardCapDeadline = this.firstActivityAtMs + cfg.sessionMaxLifetimeMs;

    await this.state.storage.setAlarm(Math.min(idleDeadline, hardCapDeadline));
  }

  async alarm(): Promise<void> {
    const cfg = resolveAnalyticsConfig(this.env);
    try {
      await this.flushToBigQuery();
      this.firstActivityAtMs = null;
      this.flushFailureCount = 0;
    } catch (err) {
      this.flushFailureCount++;

      if (this.flushFailureCount > cfg.bqMaxFlushRetries) {
        // Retry budget exhausted — drop the buffer rather than re-arm forever. This is
        // the cost-safety cap: an alarm that keeps firing on a persistently-failing BQ
        // call accrues DO active-seconds (billed) with no bound otherwise.
        const droppedCounts = {
          sessions: this.buffer.sessions.length,
          screenActivity: this.buffer.screenActivity.length,
          errors: this.buffer.errors.length,
        };
        console.error(
          `[StudentSession] BQ flush failed ${this.flushFailureCount} time(s) for student ` +
            `${this.studentId ?? "unknown"} — exceeded bqMaxFlushRetries=${cfg.bqMaxFlushRetries}. ` +
            `Dropping buffered telemetry: ${JSON.stringify(droppedCounts)}. Last error: ` +
            `${err instanceof Error ? err.message : String(err)}`
        );
        this.buffer = EMPTY_BUFFER();
        this.firstActivityAtMs = null;
        this.flushFailureCount = 0;
        return; // no new alarm scheduled — chain terminates here
      }

      // Still within retry budget — buffer is NOT cleared, retried after the delay.
      await this.state.storage.setAlarm(Date.now() + cfg.bqFlushRetryDelayMs);
    }
  }

  private async flushToBigQuery(): Promise<void> {
    const total = this.buffer.sessions.length + this.buffer.screenActivity.length + this.buffer.errors.length;
    if (total === 0) return;
    if (!this.studentId) return;

    const sid = this.studentId;
    const receivedAt = new Date().toISOString();
    const tasks: Promise<unknown>[] = [];

    if (this.buffer.sessions.length) {
      tasks.push(
        bqInsertAll(
          this.env,
          "telemetry_sessions",
          this.buffer.sessions.map((s) => ({ ...s, student_id: sid, received_at: receivedAt }))
        )
      );
    }
    if (this.buffer.screenActivity.length) {
      tasks.push(
        bqInsertAll(
          this.env,
          "telemetry_screen_activity",
          this.buffer.screenActivity.map((s) => ({ ...s, student_id: sid, received_at: receivedAt }))
        )
      );
    }
    if (this.buffer.errors.length) {
      tasks.push(
        bqInsertAll(
          this.env,
          "telemetry_errors",
          this.buffer.errors.map((e) => ({ ...e, student_id: sid, received_at: receivedAt }))
        )
      );
    }

    // If ANY of these throw, Promise.all rejects before clearing the buffer below — so
    // a partial failure keeps everything (including rows that successfully inserted) in
    // the retry buffer. This can cause duplicate rows on retry for the streams that did
    // succeed; acceptable for analytics data, and avoids the complexity of a 3-way
    // partial-success buffer split.
    await Promise.all(tasks);
    this.buffer = EMPTY_BUFFER();
  }
}