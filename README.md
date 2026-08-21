# TapApp 📚⚡

A learning app for students, built like every network request is personally costing us money — because on a school Wi-Fi in 2026, it kind of is.

TapApp is a Flutter frontend + Cloudflare Worker backend that teaches kids stuff (science, coding, money, art) through bite-sized video → submit-your-work → quiz loops, with an AI buddy (TapBuddy) hanging around to answer questions and grade homework. It's built for spotty connectivity, cheap devices, and the eternal question: *"why did that just refetch the entire roster to show one avatar?"* — the answer here, mostly, is "it doesn't."

---

## The one-sentence philosophy

**Fetch it once. Cache it forever. Patch it locally. Only go back to the network when you have no other choice, or when the user did something that actually needs a server to know about it.**

That's it. That's the whole architectural personality of this repo. Everything below is just that sentence, wearing different clothes.

---

## 🗂️ Repo structure

```
worker/                    → Cloudflare Worker (the entire backend)
  src/
    worker.js               → HTTP entrypoint, routes 3 special paths + delegates rest
    routes.js                → Generic route table → proxies to Frappe (the real backend)
    auth.js / jwt.js         → Hand-rolled JWT (HMAC-SHA256, access + reset tokens)
    cors.js                  → Origin allow-listing
    ratelimit.js             → KV-backed sliding-window-ish rate limiter
    groq.js                  → Groq API client (chat completions, vision, whisper)
    tapbuddy.js               → "/tapbuddy/chat" — the AI study buddy
    submission_review.js      → "/submission-review/review" — AI grades homework

lib/                        → Flutter app
  core/
    cache/                    → THE most important folder in this repo (see below)
    router/                    → go_router with auth-aware redirects
    theme/                     → colors, fonts, one ThemeData to rule them all
  data/
    remote/                     → Dio HTTP client + typed API endpoints
    repositories/                → Cache-first repositories (fetch → cache → serve)
  data_loader/                 → Same cache-first pattern but for bundled JSON assets
  models/                     → Plain Dart data classes, hand-written toJson/fromJson
  providers/                   → Riverpod providers wiring repos → UI
  screens/                    → Feature screens (auth, onboarding, class, home, ...)
  widgets/                    → Shared UI (header, bottom nav, TapBuddy chat panel)
```

The Worker is a thin, opinionated proxy. It does **auth, rate-limiting, CORS, and AI calls** — and forwards everything else to a Frappe/ERPNext backend (`tap_lms.tapapp.api.*`). It does not own the domain model. It's a bouncer with a translator earpiece, not the club.

---

## 🧠 The caching model (a.k.a. "why does this feel instant")

### `LocalCache` — the forever box

`lib/core/cache/local_cache.dart` wraps Hive (falling back to an in-memory store if IndexedDB is having a bad day on web) and exposes exactly one philosophy: `getForever` / `setForever`. There is no TTL. There is no "stale after 5 minutes." Once something is fetched, it lives in the box until something **specific and known** tells the app it's wrong.

```dart
T? getForever<T>(String key, T Function(Map<String, dynamic>) fromJson)
Future<void> setForever<T>(String key, T value, ...)
```

No expiry timestamps to manage, no cache-invalidation-is-one-of-the-two-hard-problems hand-wringing. Just: did we fetch this before? Yes → use it. No → fetch, then never ask again (until told otherwise).

### The "cached-first, refresh-in-background" pattern

Repositories generally do this dance (see `learner_state_provider.dart`, `profile_provider.dart`):

1. Return the cached value **immediately** — UI paints instantly, zero spinner.
2. Kick off a network refresh **in the background**, unawaited.
3. If the fresh data differs, quietly swap it into the provider state.

The user never watches a loading spinner for data they already have. They watch it once, on first load ever, and that's the deal.

### Local-first progress, server-eventually

The really spicy bit lives in `learner_state_repository.dart`: when a kid watches a video or submits an assignment, progress is written to `LocalCache` **first** (`applyLocalProgress`), the UI updates immediately, and the actual "hey server, log this" call (`submitProgress`) only fires when a whole unit is complete — batched, not per-click. If the network is bad mid-lesson, the kid doesn't notice; the sync just catches up later via `syncCompletedLocalProgress`.

Combine that with `ClassSessionWindowRepository` tracking weekly activity limits **client-side against a window key**, and you get an app that behaves correctly offline-ish, without a sync engine you'd need a PhD to debug.

### Invalidation is a scalpel, not a nuke

There's no "clear cache and refetch everything" button hiding in here (well — `clearAll()` exists, but it's reserved for logout). Instead:

- `invalidateLearner(id)` — nukes just that learner's state/achievements/progress
- `invalidateRosterAndProfiles(phone)` — clears roster/profile search pages for one account
- `RosterCacheSync.patchRow(...)` — updates *a single row* inside a *cached list* in place, so renaming a kid doesn't blow away the entire class roster cache just to fix one name

Precision invalidation everywhere. Cache keys are versioned (`v2:...`) so a schema change just orphans old keys instead of requiring a migration script nobody wants to write on a Friday.

### Assets get the same treatment

`FlowManifestRepository`, `FlowRepository`, and `ProgramContentRepository` all apply the exact same "cache forever" logic to **bundled JSON assets** (onboarding flow scripts, course content). Why re-parse `activity_flow.json` every time you open a class session? You don't. Load once, memory-cache it, done — with an in-memory `Map` on top of the `LocalCache` layer for good measure, because apparently once wasn't enough of a flex.

---

## 🌐 Minimal API calls, on purpose

A few deliberate design choices that all point the same direction:

- **Auth token refresh is opportunistic, not scheduled.** `tokenNeedsRefresh()` checks expiry only when a request is already happening (`auth.js`), and the Worker quietly stuffs a new token into the response body. No separate "refresh token" round trip, ever.
- **The Worker unwraps Frappe's `{message: {...}}` envelope** so the Flutter side gets clean JSON without needing its own normalization pass on every single response.
- **Rate limits are bucketed by route, not global** (`ratelimit.js`) — OTP requests get a tight 5/hour, Groq-backed AI routes get 20/hour, everything else gets a generous default. You spend your limited quota where it actually costs money (LLM calls), not on cheap CRUD.
- **Submission reviews get cached by content hash** (`CacheKeys.submissionReview`) — resubmit the exact same answer, get the same AI verdict back instantly, no second Groq call, no second bill.
- **The onboarding/class flows are declarative JSON state machines**, walked entirely client-side (`ActivityFlowModel`, `OnboardingFlowStep`). The server isn't polled for "what's the next screen" — the client already knows, because it fetched the flow *once* and cached it *forever*.

The net effect: open the app twice and the second time is nearly all cache hits. The network is treated as an expensive, unreliable friend you call only when you genuinely need something from them — not someone you text "wyd" to every 30 seconds.

---

## 🏗️ Backend: Worker as a very opinionated proxy

`worker/src/worker.js` is deliberately tiny:

```
OPTIONS          → CORS preflight, short-circuit
/tapbuddy/chat            → Groq chat completion, streaming personality-as-system-prompt
/submission-review/review  → Groq (text/vision) grades homework against a rubric
everything else            → routes.js → Frappe backend, JWT-checked, CORS-wrapped
```

`routes.js` is a route **table**, not a route **framework** — each entry says which Frappe method it maps to and whether it needs an access token, a reset token, or nothing. Auth middleware runs once, centrally, before any proxying happens. Adding an endpoint is adding one object to an array, not writing a new handler.

The JWT implementation (`jwt.js`) is hand-rolled Web Crypto (`HMAC-SHA256`), because Cloudflare Workers don't get to just `npm install jsonwebtoken` and call it a day — everything here runs on V8 isolates, not Node. Two token types: `access` (90-day, because re-logging in a 9-year-old in every week is a UX crime) and `reset` (10-minute, for password resets, because security still matters).

---

## 📱 Frontend: Flutter + Riverpod, no ceremony

- **State**: Riverpod `FutureProvider`/`Notifier`, mostly `.autoDispose` so screen state doesn't leak memory when you navigate away.
- **Routing**: `go_router` with a single `redirect` function acting as the entire auth gate — logged out → login, logged in but not onboarded → onboarding, first session → welcome-back screen, otherwise → wherever you're going. One function, one source of truth, no scattered `if (!loggedIn) Navigator.push(...)` landmines.
- **Models**: hand-written `fromJson`/`toJson`, no codegen. Verbose? A little. Debuggable at 2am without running `build_runner`? Absolutely.
- **The class session** (`ClassChatController`) is a chat-style state machine driving video → submission → quiz → reward, archetype-aware (a kid who's been dormant for 3 weeks gets gentler copy than a submission streak machine — see `ArchetypeStepSelector` and `LocalArchetypeCalculator`, which computes a fallback archetype client-side if the server hasn't sent one yet, because waiting on the network to decide "how do I talk to this kid" is a bad look).

---

## 🤖 The AI bits

Two Groq-backed features, both prompt-engineered to return **strict JSON**, both with a retry path if the model gets chatty and blows the token budget mid-JSON (`STRICT_RETRY_SUFFIX` in `submission_review.js` — basically "no, seriously, just the JSON, we don't need your feelings about it"):

- **TapBuddy** (`tapbuddy.js`) — a study-buddy chat, told explicitly to guide rather than hand out homework answers, and to stay on-topic (no, TapBuddy will not discuss your fantasy football league).
- **Submission review** (`submission_review.js`) — grades text, images, or transcribed voice notes against a rubric, tone-adjusted by learner archetype, always emitting `{score, verdict, feedback, sms_text, strengths, improvements}`.

---

## Running it

- **Worker**: standard Cloudflare Workers dev flow (`wrangler dev`), needs `JWT_SECRET`, `GROQ_API_KEY`, `FRAPPE_BASE_URL`, `KV` binding, `ALLOWED_ORIGINS`.
- **Flutter**: `flutter run`, points at `AppConstants.workerBaseUrl`. Hive initializes lazily and falls back gracefully on web if a stale IndexedDB connection is being clingy about a previous session — see `LocalCacheOpenTimeoutException` for the world's most specific error message.

---

*Built with the unshakeable belief that the fastest API call is the one you never make. 🐢💨 (the turtle wins here, don't ask)*