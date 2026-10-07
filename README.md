# TapApp

TapApp is a learning app for students. It has two parts:

- A **Flutter app** (the screens students use).
- A **Cloudflare Worker** (the backend that sits between the app and other services).

Students learn science, coding, money skills and art. Each lesson follows the same steps: **watch a video → submit your work → take a quiz**. An AI helper called **TapBuddy** answers questions and gives feedback on submitted work.

The app is built for slow or unstable internet and low-cost phones, so it tries to make as few network requests as possible.

---

## Main idea

> Fetch data once. Save it on the device. Update it locally. Use the network only when it is really needed.

Most design choices in this project follow this idea.

---

## Folder structure

```
worker/                     Cloudflare Worker (the backend)
  src/
    worker.js               Entry point. Handles CORS, rate limits and special routes.
    routes.js               Table of routes. Sends requests on to the Frappe backend.
    auth.js, jwt.js         Login tokens (JWT, signed with HMAC-SHA256)
    cors.js                 Checks which websites may call the API
    ratelimit.js            Limits how many requests one IP address can make
    groq.js                 Client for the Groq AI API (chat, image, speech-to-text)
    tapbuddy.js             POST /tapbuddy/chat: the AI study helper
    submission_review.js    POST /submission-review/review: AI feedback on student work

lib/                        Flutter app
  core/
    cache/                  Local storage and cache keys (the most important folder)
    router/                 Page navigation (go_router) and login checks
    theme/                  Colors and fonts
  data/
    remote/                 HTTP client (Dio) and API endpoints
    repositories/           Code that loads data and saves it in the cache
  data_loader/              Loads JSON files that are bundled inside the app
  models/                   Plain data classes (toJson / fromJson written by hand)
  providers/                Riverpod providers that connect data to screens
  screens/                  Screens: auth, onboarding, class, home, settings, ...
  widgets/                  Shared widgets (header, bottom bar, TapBuddy panel)

assets/                     Courses (en, hi, kn, mr, pa), lesson flows, images
documentation/              Full documentation (see below)
scripts/export_content.py   Script that exports course content
test/                       Flutter tests
```

---

## How the Worker works

The Worker does not store student data. It does these jobs:

1. **CORS**: allows only approved websites (set in `ALLOWED_ORIGINS`).
2. **Rate limiting**: limits requests per IP address.
3. **Login checks**: verifies the token on each protected request.
4. **AI calls**: talks to Groq for TapBuddy and for submission review.
5. **Proxy**: sends all other requests to the Frappe backend (`tap_lms.tapapp.api.*`).

Order of work in `worker.js`:

```
OPTIONS request              → answer the CORS preflight and stop
rate limit check             → return 429 if the limit is reached
POST /tapbuddy/chat          → TapBuddy (Groq chat)
POST /submission-review/review → AI review of student work
anything else                → routes.js → Frappe
```

`routes.js` is a simple list. Each item names the Frappe method to call and the login type it needs: an access token, a reset token, or none. To add an endpoint, add one item to the list.

### Login tokens

`jwt.js` creates and checks tokens with the Web Crypto API, because Workers do not run on Node.js. There are two token types:

- **access**: valid for 90 days. Used for normal requests.
- **reset**: valid for 10 minutes. Used only to reset a password.

The token refreshes itself. When a request arrives and the token has less than 30 days left, the Worker adds a new token to the response body. The app saves it. There is no separate refresh request.

### Rate limits

Limits are counted per IP address and per route group, using Cloudflare KV:

| Route group | Limit |
|---|---|
| Send OTP (`/auth/forgot-password/send-otp`) | 5 per hour |
| AI routes (TapBuddy, submission review) | 20 per hour |
| Everything else | 60 per minute |

These limits are approximate. Many students on one school network share one IP address, so they also share the limit.

### Response shape

Frappe wraps its answers in `{ "message": ... }`. The Worker removes this wrapper, so the app receives plain JSON.

---

## How the app saves data

### LocalCache

`lib/core/cache/local_cache.dart` uses Hive for storage. On web it uses an in-memory store if IndexedDB does not work. It has **no expiry time**. Data stays until the app knows it is out of date. Main methods: `getForever` and `setForever`.

Cache keys include a version (`v2:...`). When the data format changes, the app uses new keys and the old ones are ignored.

### Local progress first, server later

> **Important:** this works well only if browser storage survives between visits. The WhatsApp in-app browser may start fresh on every visit. In that case progress that is not yet on the server can be lost. See `documentation/known-gaps.md` (P3, P7, P8) and `documentation/whatsapp-link-login.md`.

When a student watches a video or submits work, the app saves the progress on the device first (`applyLocalProgress`). The screen updates at once. The app tells the server (`submitProgress`) when a whole unit is complete. If the network fails, `syncCompletedLocalProgress` sends the data later.

The app also counts weekly activity limits on the device (`ClassSessionWindowRepository`).

### Precise cache clearing

The app does not clear the whole cache to fix one problem:

- `invalidateLearner(id)` clears the data of one learner.
- `invalidateRosterAndProfiles(phone)` clears the roster and profile lists of one account.
- `RosterCacheSync.patchRow(...)` changes one row inside a cached list. For example, renaming one student does not remove the whole class list.
- `clearAll()` exists, but it is used only when the user logs out.

### Bundled files

Course content and lesson flows are JSON files inside the app. `FlowManifestRepository`, `FlowRepository` and `ProgramContentRepository` read each file once and keep it in memory and in `LocalCache`.

The onboarding and class flows are JSON "state machines". The app reads them from the device and decides the next step itself. It does not ask the server.

### AI review cache

The app saves each AI review on the device. The key is built from the learner, the question and the answer text. If a student sends the same answer again, the app shows the saved review and does not call the AI again. This cache is in the app only. The Worker does not cache reviews.

---

## How the app is built

- **State**: Riverpod (`FutureProvider` and `Notifier`). Most providers use `.autoDispose`.
- **Navigation**: `go_router` with one `redirect` function that does all login checks. Not logged in → login. Logged in but not onboarded → onboarding. First session → welcome screen. Otherwise → the page the user asked for.
- **Models**: `toJson` and `fromJson` are written by hand. There is no code generation.
- **Class session**: `ClassChatController` runs a chat-style lesson: video → submission → quiz → reward. The wording changes by learner "archetype" (for example, a student who has been away for weeks gets softer wording). `LocalArchetypeCalculator` works out an archetype on the device if the server has not sent one yet.

---

## AI features

Both features use Groq. Both ask the model to return strict JSON. If the answer is cut off or is not valid JSON, `submission_review.js` asks again with `STRICT_RETRY_SUFFIX`.

- **TapBuddy** (`tapbuddy.js`): a short chat helper for students. It uses the last 12 messages and some learner context (course, unit, XP, streak). It is told to guide students and not to give homework answers, and to stay on learning topics. The reply is returned in one response (no streaming).
- **Submission review** (`submission_review.js`): checks text, images, or voice notes (converted to text) against a rubric. The tone depends on the learner archetype. The result has this shape: `{ score, verdict, feedback, sms_text, strengths, improvements }`.

---

## Run the project

You need Flutter (Dart `^3.11.5`), Node.js and npm. Chrome is used for web development.

```bash
flutter pub get
npm ci
cd worker && npm ci && cd ..
```

**Flutter app**

```bash
flutter run -d chrome
```

The app calls the Worker at `AppConstants.workerBaseUrl` (`lib/core/constants/app_constants.dart`). Change it to test with another Worker.

If the app shows `LocalCacheOpenTimeoutException` on web, an old IndexedDB connection is blocking it. Clear the site data and reload.

**Worker**

```bash
cd worker
npm run dev
```

The Worker reads these settings:

| Name | Purpose |
|---|---|
| `JWT_SECRET` | Signs and checks login tokens. Must match the secret used by the Frappe backend. |
| `GROQ_API_KEY` | Key for the Groq AI API |
| `GROQ_MODEL` | AI model used for text review of submissions |
| `FRAPPE_BASE_URL` | Address of the Frappe backend |
| `ALLOWED_ORIGINS` | Websites allowed to call the API, separated by commas |
| `KV` | Cloudflare KV binding used for rate limits |

Keep secrets out of git. Use `wrangler secret put` or a local `.env` file that is listed in `.gitignore`. See `documentation/deployment.md` for the full list.

**Checks**

```bash
flutter analyze
flutter test
npm run format:check
```

---

## More documentation

The `documentation/` folder has more detail. Start with `documentation/index.md`. To read it as a website, run `mkdocs serve` (see `documentation/getting-started.md`).

| Topic | File |
|---|---|
| Setup | `documentation/getting-started.md` |
| System design | `documentation/architecture.md` |
| Flutter code and caching | `documentation/frontend.md` |
| Onboarding and class rules | `documentation/learning-flows.md` |
| API endpoints | `documentation/api-reference.md` |
| Frappe backend | `documentation/frappe-backend.md` |
| Courses, languages, images | `documentation/content-and-assets.md` |
| Release steps | `documentation/deployment.md` |
| Testing and operations | `documentation/testing-and-operations.md` |
