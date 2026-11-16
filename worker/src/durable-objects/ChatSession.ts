/**
 * durable-objects/ChatSession.ts — one instance per chat conversation, keyed by a
 * client-generated session_id (Contract §0: "Ask TAP conversations keep running
 * context in a Durable Object between turns"). An idle alarm flushes history to BQ
 * and evicts; a request arriving after that creates a brand-new DO instance for the
 * same session_id with empty history — the old context is simply gone, which is what
 * "runs out between turns after idle" means for a DO with no persisted cross-instance
 * state.
 *
 * If a flush fails (network error, BQ budget exhausted), exchanges are kept in memory
 * and retried after bqFlushRetryDelayMs — nothing is spilled to R2. Retries are capped
 * at bqMaxFlushRetries (default 1 retry total): once exhausted, the exchanges are
 * DROPPED and logged rather than re-arming the alarm again, which bounds DO
 * active-time (= cost) for a persistently-failing BQ call.
 *
 * `context`, per Contract §10, carries fixed optional top-level keys (unit_id,
 * unit_name, grade, language, course_id, assignment_id) plus a free-form `extra` bag.
 * This DO does not validate or require any of them — it passes the whole object
 * through to the AI provider unchanged, exactly as a fully-freeform v1 object would
 * have. No `screen` field is treated specially; the Worker never keys behavior off it.
 */

import { resolveAnalyticsConfig } from "../config/analytics";
import type { Env } from "../env";
import { bqInsertAll } from "./shared/bqWriter";

interface ChatExchange {
  question: string;
  answer: string | null;
  context?: Record<string, unknown>;
  askedAt: string;
  answeredAt: string | null;
}

interface ProviderMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export class ChatSession {
  private state: DurableObjectState;
  private env: Env;
  private exchanges: ChatExchange[] = [];
  private sessionId: string | null = null;
  private studentId: string | null = null;
  /** Consecutive failed flush attempts for the CURRENT exchange buffer. Reset on
   *  success or on drop. */
  private flushFailureCount = 0;

  constructor(state: DurableObjectState, env: Env) {
    this.state = state;
    this.env = env;
  }

  async fetch(req: Request): Promise<Response> {
    const url = new URL(req.url);
    if (url.pathname !== "/turn") return new Response("not found", { status: 404 });

    try {
      const { sessionId, studentId, message, context } = (await req.json()) as {
        sessionId: string;
        studentId: string;
        message: string;
        context?: Record<string, unknown>;
      };
      this.sessionId = sessionId;
      this.studentId = studentId;

      const reply = await this.handleTurn(message, context);
      await this.scheduleIdleAlarm();
      return Response.json({ reply });
    } catch (err) {
      return Response.json({ error: err instanceof Error ? err.message : "unknown chat DO error" }, { status: 500 });
    }
  }

  private async handleTurn(message: string, context?: Record<string, unknown>): Promise<string> {
    const askedAt = new Date().toISOString();
    const exchange: ChatExchange = { question: message, answer: null, context, askedAt, answeredAt: null };
    this.exchanges.push(exchange);

    const cfg = resolveAnalyticsConfig(this.env);
    const promptExchanges = this.exchanges.slice(-cfg.chatMaxHistoryTurns);

    const providerHistory: ProviderMessage[] = promptExchanges.flatMap((ex): ProviderMessage[] =>
      ex.answer !== null
        ? [
            { role: "user", content: ex.question },
            { role: "assistant", content: ex.answer },
          ]
        : [{ role: "user", content: ex.question }]
    );

    const reply = await this.callAiProvider(providerHistory, context);

    exchange.answer = reply;
    exchange.answeredAt = new Date().toISOString();

    return reply;
  }

  private async callAiProvider(history: ProviderMessage[], context?: Record<string, unknown>): Promise<string> {
    const systemPrompt =
      "You are Ask TAP, a friendly, encouraging study buddy for a school student using the TapApp learning app. " +
      "Keep answers short, age-appropriate, and clear. Never request or reveal personal contact information.";

    const messages: ProviderMessage[] = [
      { role: "system", content: systemPrompt },
      ...(context ? [{ role: "system" as const, content: `Context for this turn: ${JSON.stringify(context)}` }] : []),
      ...history,
    ];

    const res = await fetch(`${this.env.AI_PROVIDER_BASE_URL}/v1/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.env.AI_PROVIDER_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ model: this.env.AI_PROVIDER_MODEL, messages, max_tokens: 400 }),
    });

    if (!res.ok) {
      throw new Error(`AI provider call failed: ${res.status}`);
    }
    const json = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
    return json.choices?.[0]?.message?.content ?? "Sorry, I couldn't come up with an answer just now.";
  }

  private async scheduleIdleAlarm(): Promise<void> {
    const cfg = resolveAnalyticsConfig(this.env);
    await this.state.storage.setAlarm(Date.now() + cfg.chatIdleTimeoutMs);
  }

  async alarm(): Promise<void> {
    const cfg = resolveAnalyticsConfig(this.env);
    try {
      await this.flushToBigQuery();
      this.flushFailureCount = 0;
    } catch (err) {
      this.flushFailureCount++;

      if (this.flushFailureCount > cfg.bqMaxFlushRetries) {
        // Retry budget exhausted — drop rather than re-arm forever (cost-safety cap on
        // DO active-seconds for a persistently-failing BQ call).
        console.error(
          `[ChatSession] BQ flush failed ${this.flushFailureCount} time(s) for session ` +
            `${this.sessionId ?? "unknown"} (student ${this.studentId ?? "unknown"}) — exceeded ` +
            `bqMaxFlushRetries=${cfg.bqMaxFlushRetries}. Dropping ${this.exchanges.length} buffered ` +
            `exchange(s). Last error: ${err instanceof Error ? err.message : String(err)}`
        );
        this.exchanges = [];
        this.flushFailureCount = 0;
        return; // no new alarm scheduled — chain terminates here
      }

      // Still within retry budget — exchanges stay buffered, retried after the delay.
      await this.state.storage.setAlarm(Date.now() + cfg.bqFlushRetryDelayMs);
    }
  }

  private async flushToBigQuery(): Promise<void> {
    if (this.exchanges.length === 0) return;
    if (!this.sessionId || !this.studentId) return;

    const sid = this.studentId;
    const sessId = this.sessionId;
    const receivedAt = new Date().toISOString();

    await bqInsertAll(
      this.env,
      "chat_turns",
      this.exchanges.map((ex, i) => ({
        student_id: sid,
        session_id: sessId,
        exchange_index: i,
        question: ex.question,
        answer: ex.answer,
        context: ex.context ? JSON.stringify(ex.context) : null,
        asked_at: ex.askedAt,
        answered_at: ex.answeredAt,
        received_at: receivedAt,
      }))
    );
    this.exchanges = [];
  }
}