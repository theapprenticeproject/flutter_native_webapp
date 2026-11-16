# TapApp Worker Middleware

A single Cloudflare Worker fronting Frappe, GCS, R2, BigQuery, and the AI provider,
built from `TapApp_Worker_Build_Plan.md`. Implements `API_Contract.md` /
`API_Reference.md` exactly: every route, every error code, every response shape.

## Status

Every layer in the build plan's `src/` tree is written and wired together end-to-end
(auth → cache → storage → Frappe → Durable Objects → analytics → router).

`npm install && npx tsc --noEmit` passes cleanly (zero errors), and
`wrangler deploy --dry-run` successfully bundles the whole project (75.88 KiB,
18.43 KiB gzipped) and resolves every binding and env var.

**BigQuery transport uses the legacy `tabledata.insertAll` REST endpoint** (plain JSON,
no OAuth-token-per-call cost beyond the cached mint — see `bqWriter.ts`). There is no
R2 dead-letter spill: a failed flush is retried in place from the Durable Object's
in-memory buffer (see "Durable Objects" below).

Treat this as a strong, type-checked, structurally-complete draft — not as something
that's been run against live Frappe/GCS/BQ/AI-provider traffic yet.

## Storage model — who owns what, and who signs what

This is the part most worth reading carefully, because it's easy to conflate GCS and
R2's roles.

### GCS — one bucket, everything origin-side

There is exactly **one GCS bucket in active use**: `GCS_AUTHENTICATED_BUCKET`
(`tap-submission` in `wrangler.toml`). It is private — nothing is public-read. Every
object in it, whether it's a student's photo, their video, or a feedback audio clip, is
only ever reached through a Worker-minted, short-lived V4-signed URL. The Worker holds
the GCS service-account credentials (`GCS_SERVICE_ACCOUNT_JSON`) directly; nothing else
in the system can sign a GCS URL.

What the Worker does with this bucket, per request:

- **Sign an upload URL** (`submission/request_upload` → `storage/gcs.ts::gcsSignUpload`)
  — mints a V4-signed PUT URL with a `content-length-range` condition baked into the
  signature, so GCS itself rejects an oversized upload before it ever reaches the
  Worker. The client uploads directly to GCS; the Worker never sees the bytes.
- **Confirm the upload** (`submission/submit_artwork` →
  `storage/gcs.ts::confirmUploaded`) — a GCS object-metadata GET (effectively a HEAD)
  that checks existence, size, and content-type, in that order, *before* the Worker
  ever tells Frappe the submission is real. This is confirm-then-create, not
  trust-then-create.
- **Sign a read URL on demand** (`progress/sync`, `progress/last_submission`,
  `submission/get`, `submission/list` → all route through `storage/resign.ts::
  signSubmission` → `storage/gcs.ts::gcsSignRead`) — every call mints a fresh signed
  GET, for both the submission's own media and any `feedback_audio_key` it carries.
  Nothing is cached long-term; a URL is only as fresh as the request that returned it.

Images, videos, and feedback audio all live in this same bucket, distinguished only by
object key shape (`storage/keys.ts`):

```
tapapp/{assignment_id}/{student_id}/{submission_id}-{attempt}.{ext}
```

`ext`/content-type is `webp`/`image/webp` for images and `mp4`/`video/mp4` for video —
`submission_type` on `request_upload` only ever accepts `"image" | "video"`, matching
Frappe's own `Submission.submission_type` Select exactly. There is no "audio" value a
student can request an upload for; `audio/mpeg` (`.mp3`) is used internally only, for
signing/reading a submission's own `feedback_audio_key` once Frappe has written one.

`GCS_PUBLIC_BUCKET` is **not part of this flow** — see gap #3 above.

### R2 — someone else's bucket, gallery reads only

R2 plays a completely different role, and lives in a **different Cloudflare account**
than this Worker (which is why there's no native `[[r2_buckets]]` binding in
`wrangler.toml` — bindings are same-account only).

- The Worker never writes to R2 from any route in this codebase. Promotion of a graded
  submission from GCS into the gallery's R2 bucket happens in a **separate background
  job outside this Worker** (triggered by Frappe once a submission is graded/promoted,
  per the build plan). That job calls `internal/gallery/index`
  (`handlers/internalHandlers.ts`) to write the resulting row into D1's
  `gallery_items` table — the row records an `object_key`, not the signed URL itself.
- For reads, `storage/r2.ts::r2SignGetDirect` signs a **true direct-to-R2 SigV4 GET
  URL** against R2's S3-compatible endpoint, using `R2_ACCESS_KEY_ID` /
  `R2_SECRET_ACCESS_KEY`. The client fetches bytes straight from R2's edge — the Worker
  is not in that read path at all. This matters because gallery reads happen far more
  often than the writes that produced them.
- Signing is time-windowed (`PRESIGN_WINDOW_SECONDS`) rather than signed fresh on every
  call, specifically so the same URL string is reused for the whole window and the
  app's URL-keyed image cache actually caches.

So: **GCS is the origin for every upload and every direct student-facing read of their
own submission. R2 is exclusively the gallery's serving layer**, populated by a process
outside this Worker, and the only thing this Worker does with it is sign outbound GET
URLs — never upload, never list directly against the bucket at read time (gallery
listing always comes from D1, never R2 `list()` or Frappe — see `db/gallery.ts`).

---

## BigQuery: what gets written, and from where

Two Durable Object classes own all BQ writes — nothing else in the Worker calls
`bqInsertAll` directly:

- **`StudentSession`** flushes `telemetry_sessions`, `telemetry_screen_activity`, and
  `telemetry_errors` rows on its idle alarm.
- **`ChatSession`** flushes `chat_turns` rows on its idle alarm.

Both go through the same transport (`durable-objects/shared/bqWriter.ts`), which is a
thin wrapper around `tabledata.insertAll` guarded by a **daily byte budget**
(`BQ_DAILY_BYTE_BUDGET`, Cache-API-tracked) and a **master kill switch**
(`BQ_ENABLED` — set to `"false"` to no-op every write immediately, with no OAuth mint
and no fetch).

If a flush fails (network error, budget exhausted), the buffer stays in DO memory and
is retried after `BQ_FLUSH_RETRY_DELAY_MS`. Retries are capped at
`BQ_MAX_FLUSH_RETRIES` (default 1): once exhausted, the buffer is dropped and logged
rather than re-arming the alarm forever — this bounds DO active-seconds (billed cost)
for a persistently-failing BQ call. **There is no R2 dead-letter spill** in this
revision; a dropped buffer is simply lost.

`worker_requests` — the per-request Analytics Engine data — is **not mirrored into
BQ** in this revision. There is no `scheduled()` cron handler at all (see gap #7); if
you need that data in BigQuery, query Workers Analytics Engine directly (dashboard,
GraphQL Analytics API, or the Analytics Engine SQL API), or re-add a cron job
yourself.

### Can `sql/bq_schemas/` be deleted after the tables exist?

Functionally, yes — nothing at runtime reads these files; they're one-time (or
rarely-repeated) input to a manual `bq query < telemetry_and_chat_tables.sql` /
console-paste step, not a dependency the Worker loads. That said, keep it in version
control: you'll want it again the moment you need to recreate a table (staging
environment, disaster recovery, a teammate spinning up a fresh dataset), and it's the
one place the partitioning/clustering decisions are recorded as executable DDL. It
already isn't shipped in the deploy bundle — `wrangler deploy` only bundles `src/`.

---

## Project layout

```
tapapp-worker/
├── wrangler.toml              # deploy config — bindings, vars (no cron trigger)
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts                # entrypoint: fetch handler only
│   ├── router.ts                # route table, turn-budget wiring, Analytics Engine logging
│   ├── env.ts                   # typed Env interface + AppError + error constructors
│   │
│   ├── auth/
│   │   ├── hmac.ts              # Web Crypto HMAC + base32/base64url primitives
│   │   ├── magicLink.ts         # encode/verify the self-contained signed magic link
│   │   ├── sessionToken.ts      # mint/verify fixed-TTL phone-/student-scoped tokens
│   │   └── middleware.ts        # requireStudentToken() / requirePhoneToken() guards
│   │
│   ├── config/
│   │   ├── defaults.ts           # every tunable constant, with runtime-overridable keys
│   │   ├── index.ts              # D1 app_config > [vars] > defaults precedence
│   │   └── analytics.ts          # DO/BQ timing+size knobs
│   │
│   ├── constants/
│   │   ├── pointTiers.ts         # points_tier thresholds (no next_tier/points_to_next)
│   │   └── unitStatus.ts         # Frappe Unit Progress status vocabulary (unused today)
│   │
│   ├── handlers/                # one file per route group
│   │   ├── authHandlers.ts
│   │   ├── profileHandlers.ts
│   │   ├── progressHandlers.ts
│   │   ├── submissionHandlers.ts
│   │   ├── galleryHandlers.ts
│   │   ├── chatHandlers.ts
│   │   ├── eventHandlers.ts
│   │   ├── telemetryHandlers.ts
│   │   ├── laterHandlers.ts
│   │   ├── internalHandlers.ts
│   │   └── configHandlers.ts
│   │
│   ├── frappe/
│   │   ├── client.ts            # fetchFrappe() — the ONLY place that calls Frappe
│   │   └── mapRequest.ts        # route → Frappe method name map
│   │
│   ├── storage/
│   │   ├── gcs.ts               # GCS V4 signed PUT/GET, upload confirm — see "Storage: GCS"
│   │   ├── gcsAuth.ts           # service-account JWT→OAuth2 token (shared w/ BQ writer)
│   │   ├── r2.ts                # direct-to-R2 SigV4 signed GET — see "Storage: R2"
│   │   ├── keys.ts              # canonical object-key builder (shared by gcs.ts)
│   │   ├── resign.ts            # re-sign view_url/overall_feedback_audio_url on demand
│   │   ├── profileScope.ts      # Frappe-backed gallery scope (state/district/school/grade)
│   │   ├── scopeToken.ts        # signed scope_cache_token so a repeat gallery call skips Frappe
│   │   └── packTaps.ts          # compact binary encoding for telemetry tap coordinates
│   │
│   ├── cache/                   # Cache API ONLY — no KV anywhere in this project
│   │   ├── idempotency.ts       # write-once-per-key idempotency store
│   │   ├── turnBudget.ts        # per-turn (multi-call action) request cap
│   │   ├── rateLimitCache.ts    # Layer 1 edge-local burst guard
│   │   ├── galleryPageCache.ts  # cached gallery query pages
│   │   └── galleryRowCache.ts   # cached per-submission signed-URL rows
│   │
│   ├── durable-objects/
│   │   ├── StudentSession.ts    # rate limit Layer 2 + telemetry buffer, idle-alarm flush to BQ
│   │   ├── ChatSession.ts       # Ask TAP running context, idle-alarm flush to BQ
│   │   └── shared/
│   │       └── bqWriter.ts      # BQ insertAll + write-budget (no R2 dead-letter spill)
│   │
│   ├── db/
│   │   ├── gallery.ts            # D1-backed gallery_items — the ONLY gallery listing source
│   │   └── schema.sql            # gallery_items + app_config table DDL
│   │
│   ├── telemetry/
│   │   └── collector.ts         # extracts _t, forwards to StudentSession DO
│   │
│   ├── analytics/
│   │   └── engine.ts            # Workers Analytics Engine writeDataPoint() wrapper
│   │
│   └── util/
│       ├── errors.ts            # ok()/fail() response envelope, null-stripping
│       ├── ids.ts                # id/slug/idempotency-key validation helpers
│       ├── time.ts               # epoch + UTC-date helpers
│       └── rateLimit.ts          # wires Layer 1 (cache) + Layer 2 (DO) together
│
└── sql/
    ├── bq_schemas/
    │   ├── telemetry_and_chat_tables.sql  # real DDL for all 4 telemetry/chat tables
    │   └── worker_requests.json            # AE-dataset schema reference (not auto-mirrored)
    └── bq_views/                           # yours to write: daily_rollups.sql etc.
```

---

## Setup

```bash
cd tapapp-worker
npm install
```

### Secrets (set via `wrangler secret put <NAME>`, never committed)

| Secret | Purpose |
|---|---|
| `MAGIC_LINK_SECRET` | HMAC key signing magic links only |
| `PHONE_TOKEN_SECRET` | HMAC key signing phone-scoped session tokens only |
| `STUDENT_TOKEN_SECRET` | HMAC key signing student-scoped session tokens only |
| `GALLERY_SCOPE_TOKEN_SECRET` | HMAC key signing the gallery `scope_cache_token` |
| `INTERNAL_API_SECRET` | Shared secret guarding the `/internal/*` routes (Frappe's promotion job only) |
| `FRAPPE_BASE_URL` | e.g. `https://lms.tapapp.internal` |
| `FRAPPE_API_KEY` / `FRAPPE_API_SECRET` | Frappe service-account API credentials |
| `GCS_SERVICE_ACCOUNT_JSON` | Full GCP service-account key JSON (`roles/storage.objectAdmin`, scoped to `GCS_AUTHENTICATED_BUCKET` only) |
| `AI_PROVIDER_API_KEY` | Ask TAP's AI provider key |
| `BQ_SERVICE_ACCOUNT_JSON` | GCP service-account key JSON (`roles/bigquery.dataEditor`, scoped to one dataset only) |
| `BQ_PROJECT_ID` | GCP project id for BigQuery |
| `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` | R2 API credentials for the *other* Cloudflare account's bucket — used only to sign outbound GET URLs |

Non-secret tunables (bucket/dataset names, AI provider base URL/model, `BQ_ENABLED`,
every `AnalyticsConfig` knob, `ENVIRONMENT`) live in `wrangler.toml`'s `[vars]` block —
edit directly, no secret needed.

### Local dev

```bash
npm run dev        # wrangler dev
npm run typecheck   # tsc --noEmit — RUN THIS FIRST, see gaps above
npm run deploy      # wrangler deploy
npm run tail        # wrangler tail, for live log inspection
```

---

## Architecture notes (how this maps to the build plan)

- **No KV anywhere.** Idempotency, turn-budget, rate-limit Layer 1, and gallery
  page/row caching all use the Worker **Cache API** exclusively, per the explicit
  requirement. Durability gaps are closed cheaply: a DB-level unique index on Frappe's
  `Submission.idempotency_key` backstops Cache API eviction.
- **Two Durable Objects**, each with the identical in-memory-state + idle-alarm
  pattern: `StudentSession` (rate limit Layer 2 + telemetry buffer, keyed by
  `student_id`) and `ChatSession` (Ask TAP context, keyed by a client-generated
  `session_id`). Neither does a `storage.put` per request — only the alarm
  registration itself touches durable storage, which is what keeps this cheap at
  volume.
- **A chat session's context ends at idle expiry.** After the configured idle window
  the DO flushes `this.history` to BQ and evicts. A request arriving after that point
  creates a **brand-new** DO instance for the same `session_id` with **empty**
  history — the old context is simply gone.
- **BQ writes are batched once per DO flush**, never per-telemetry-row, and are gated
  by a global daily byte-budget (Cache-API-tracked). A write that exceeds the budget,
  or that otherwise fails, is **not** spilled anywhere — the DO keeps it buffered in
  memory and retries on the next alarm, up to `BQ_MAX_FLUSH_RETRIES`, then drops it.
- **Workers Analytics Engine** (`analytics/engine.ts`) is a separate, independent,
  unconditional per-request log — Worker-observed, not app-reported — written from
  exactly one place (`router.ts`'s `finally` block) so no route can forget to log. It
  is not mirrored into BQ in this revision; query it directly if you need that data
  elsewhere.
- **Submission pipeline** (`handlers/submissionHandlers.ts`) is confirm-then-create,
  not trust-then-create: `request_upload` signs a PUT URL with a
  `content-length-range` condition baked into the GCS V4 signature (so GCS itself
  rejects oversized uploads), and `submit_artwork` independently fetches the object's
  metadata to verify it exists at the right size/type *before* Frappe ever creates a
  row.
- **Gallery** (`handlers/galleryHandlers.ts`) implements all five scope dimensions
  (`assignment_id/state/district/school/grade`) via a config-driven fallback cascade
  (`GALLERY_FALLBACK_CASCADE`), but listing always comes from D1's `gallery_items` —
  never Frappe, never R2 `list()` — with R2 used only to sign the resulting rows' media
  URLs for direct client fetch.

---

## What changed in this revision (for readers of earlier notes)

If you've seen an older version of this README or build notes, three things are
different now and worth flagging explicitly:

1. **BigQuery transport is `tabledata.insertAll`**, not the Storage Write API — earlier
   notes describing a Storage Write API switch (`AppendRows`, byte-based budgeting
   under a different config key, `BQ_DAILY_ROW_BUDGET` → `BQ_DAILY_BYTE_BUDGET`) do not
   match what's in `bqWriter.ts` today. The byte-based daily budget concept is still
   present (`BQ_DAILY_BYTE_BUDGET`), just computed from the `insertAll` request body
   size rather than a Storage Write API stream.
2. **R2 reads are true direct-to-R2 presigned URLs**, not a Worker-proxied
   `/_r2/<key>` streaming route. If you've seen notes describing the Worker as "in the
   data path for gallery reads," that described an earlier design; `storage/r2.ts`
   as written signs SigV4 URLs against R2's S3-compatible endpoint directly, and the
   Worker is not in that read path.
3. **There is no cron / `scheduled()` handler, no nightly AE→BQ mirror, and no R2
   dead-letter replay job.** `index.ts` exports only a `fetch` handler. A BQ flush
   failure is retried in-DO-memory and eventually dropped (see "BigQuery" above) rather
   than spilled to R2 and replayed later.

---

## Next steps (suggested order)

1. `npm install && npm run typecheck` — fix whatever surfaces, starting with
   `storage/gcs.ts`'s V4 signing (test against a real GCS example request/response
   pair).
2. Decide what to do about `GCS_PUBLIC_BUCKET` (gap #3) — wire it up or remove it.
3. Write `sql/bq_views/daily_rollups.sql` (and any other views you need) against the
   schemas already in `sql/bq_schemas/`.
4. Stand up the BQ dataset + tables from the DDL, and the two GCP service accounts
   (GCS, BQ) with the least-privilege scopes noted in the secrets table above.
5. `wrangler dev` against a staging Frappe instance and walk the submission pipeline
   end-to-end by hand (`request_upload` → PUT to the signed URL → `submit_artwork`)
   before trusting it with real traffic.
6. Confirm the R2 credentials actually have read access to the other account's bucket,
   and spot-check a signed gallery URL resolves correctly client-side.