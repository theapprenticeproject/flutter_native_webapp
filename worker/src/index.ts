/**
 * index.ts — entrypoint: fetch handler only. There is no scheduled() cron handler
 * anymore: the nightly Analytics Engine → BQ mirror and the R2 dead-letter replay job
 * have both been removed.
 *
 *  - Analytics Engine (per-request logs from router.ts) now stays in Analytics Engine
 *    only — query it directly (via the Cloudflare dashboard, GraphQL Analytics API, or
 *    SQL API) rather than through a BQ mirror table.
 *  - BQ now receives ONLY chat_turns and telemetry_* rows, written directly from the
 *    StudentSession / ChatSession Durable Objects on their idle/lifetime alarms. There
 *    is no R2 spill path anymore, so there is nothing left for a replay job to do.
 *
 * If you re-add any cron-triggered job in the future, wire it here via a `scheduled()`
 * export and a matching `[triggers]` block in wrangler.toml.
 */

import { handleRequest } from "./router";
import type { Env } from "./env";

export { StudentSession } from "./durable-objects/StudentSession";
export { ChatSession } from "./durable-objects/ChatSession";

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    return handleRequest(req, env, ctx);
  },
};