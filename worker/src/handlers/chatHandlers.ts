/**
 * handlers/chatHandlers.ts — /tapbuddy/chat (Contract §9 / Reference §7).
 *
 * `context` here is the freeform, schema-free object the app builds per-screen — it is
 * forwarded to the AI provider unvalidated via the ChatSession Durable Object, and is a
 * completely different field from the `context: "program" | "event"` enum used on the
 * progress/submission endpoints (they share a name only).
 *
 * No `refreshed_token` anywhere in the response surface, ever (Contract §3/§4.5,
 * Reference §0): tokens are fixed-TTL, minted once at /auth/redeem or
 * /auth/select_profile, and never refreshed by any subsequent call, this one included.
 */

import { requireStudentToken } from "../auth/middleware";
import type { Env } from "../env";
import { invalidInput, upstreamError } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { collectTelemetry } from "../telemetry/collector";

interface ChatBody {
  message?: string;
  context?: Record<string, unknown>;
  _t?: unknown;
}

async function chat(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "chat");

  const body = (await req.json().catch(() => ({}))) as ChatBody;
  if (!body.message || typeof body.message !== "string" || body.message.trim().length === 0) {
    throw invalidInput("message missing or empty");
  }

  const sessionId = req.headers.get("X-Chat-Session") ?? `${studentId}:default`;

  const id = env.CHAT_SESSION.idFromName(sessionId);
  const stub = env.CHAT_SESSION.get(id);

  const res = await stub.fetch("https://do.internal/turn", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ sessionId, studentId, message: body.message, context: body.context ?? {} }),
  });

  if (!res.ok) {
    throw upstreamError("AI provider call failed — safe to retry");
  }
  const { reply } = (await res.json()) as { reply: string };

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({ reply });
}

export const chatHandlers = { chat };