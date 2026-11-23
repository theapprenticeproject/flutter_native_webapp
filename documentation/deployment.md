# Deployment

## Flutter Web

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
scripts/build_web.sh
firebase deploy --only hosting
```

### Flutter version

Build releases with the Flutter version in `pubspec.yaml` (now 3.47.1). `flutter pub get` fails if you use another version.

This is important because the web drawing code (CanvasKit) comes from the Flutter engine that built the app. A build made with Flutter 3.41 showed the login screen zoomed and stretched in the WhatsApp browser on some Android phones (Redmi Note 13 and Samsung A31). The same code built with 3.47.1 looked correct.

`scripts/build_web.sh` builds the app and saves build details inside it. **Long-press the icon** on the "Open your TAP link" page, or the small **"TAP"** at the bottom of the Me page, to show a line like this:

```text
Build 2026-10-16T10:42Z · 9462206 · Flutter 3.47.1 (engine 5d531788) · API tapapp-worker.tapapp-middleware.workers.dev
```

The line shows:
- the build time (UTC),
- the git commit (`-dirty` means there were changes that were not committed),
- the Flutter version and the engine,
- the host of the Worker that this build talks to (`API`).

Long-press again to hide the line. A build made without the script shows `unknown`. Do not deploy that build.

### Preview deploy to the test Worker (Firebase channel)

Use this to test on phones. It does **not** touch the live site.

```bash
firebase login                       # only if your login has expired
firebase use tapapp-app-tap          # .firebaserc already says this

# Build for the test Worker. SKIP_UPLOAD=1 is only for the test Worker, whose
# upload address is fake.
SKIP_UPLOAD=1 WORKER_URL=https://tapapp-test-worker.tapific.workers.dev scripts/build_web.sh

# Deploy to a preview channel. Pick a new name, so you never overwrite another
# channel (for example the old probe page).
firebase hosting:channel:deploy m0-test --expires 14d
```

- **Always build with `scripts/build_web.sh`.** Plain `flutter build web` has no Worker address (it uses the **production** Worker), no build line, and no local CanvasKit.
- **Check the last line of the build** (`Worker: ...`) and the build line in the app (long-press the icon on the link page, or "TAP" on Me). A test build must show the test Worker.
- **`SKIP_UPLOAD=1` never goes to real students.** The script refuses it with no `WORKER_URL` or with the production Worker.
- **Magic links.** The test Worker's link (`https://<worker>/l/<code>`) does not open this app yet. The app opens two link forms: `https://<app-host>/<code>` (this is the form for the WhatsApp template button) and `https://<app-host>/#/l/<code>`. After sign-in the app removes the code from the address bar.
- **WhatsApp template (HSM) URL button.** WhatsApp allows a variable only at the END of the URL, so the template URL is `https://<app-host>/{{1}}` and the Worker sends just the code as the variable. Hosting must send every path to `index.html` (`firebase.json` already does).
- **The channel link is public** to anyone who has it, and it talks to a shared test Worker. Do not put real student data on it.
- **Get a login link** from the test Worker: see `testing-and-operations.md`.

### Deploy to production

1. All checks pass (`flutter analyze`, `flutter test`, `dart run scripts/check_architecture.dart`).
2. Build **without** `SKIP_UPLOAD` and with the real Worker: `scripts/build_web.sh` (production is the default) or `WORKER_URL=https://<dev-worker-host> scripts/build_web.sh` for the dev server.
3. Read the build line in the app: the commit has no `-dirty`, the Flutter version is the pinned one, and `API` is the Worker you meant.
4. `firebase deploy --only hosting`.
5. **Deploy the app before the Worker.** The Worker no longer has the old AI and learner routes, so an older app version would fail against it.
6. Run through the release checklist below on a real phone inside WhatsApp.

### Choose the Worker (dev or production)

The app talks to one Worker. Set it when you build, with `WORKER_URL`:

```bash
# Dev server test
WORKER_URL=https://<dev-worker-host> scripts/build_web.sh

# Production (no WORKER_URL: the production Worker is used)
scripts/build_web.sh
```

- `WORKER_URL` must be an `https://` address with no path. A trailing `/` is removed. Plain `http://` works only for `localhost` (for a local `wrangler dev`). The script stops with a message for anything else.
- Before you deploy, long-press the logos and check the `API` host in the build line. A dev build must show the dev Worker.
- `DRY_RUN=1 scripts/build_web.sh` checks the settings and prints the command without building.
- The Worker itself needs its own dev settings (Frappe address and secrets, allowed origins). That is separate from this build setting.

You can also check the engine from outside the app:

```bash
curl -s https://<host>/flutter_bootstrap.js | grep -o '"engineRevision":"[a-f0-9]\{8\}'
```

To change the Flutter version:
1. Upgrade on a separate branch and build.
2. Test the "Open your TAP link" page and a real sign-in on real phones inside the WhatsApp browser.
3. Then change the version range in `pubspec.yaml`.

`firebase.json` serves `build/web` and rewrites all routes to `index.html`, which is required for `go_router` browser navigation.

## Worker configuration

The Worker needs these bindings:

| Variable/binding  | Purpose                                   |
| ----------------- | ----------------------------------------- |
| `FRAPPE_BASE_URL` | Frappe origin, without `/api/method`      |
| `JWT_SECRET`      | Must match the Frappe TapApp JWT secret   |
| `ALLOWED_ORIGINS` | Comma-separated trusted frontend origins  |
| `KV`              | Cloudflare KV namespace for rate limiting |

Store secrets with Wrangler, not in `wrangler.toml`:

```bash
cd worker
npx wrangler secret put JWT_SECRET
npm run deploy
```

The AI code (Groq) was removed from the Worker in M0 (task C1). If a `GROQ_API_KEY` secret still exists on a deployed Worker, delete it: `npx wrangler secret delete GROQ_API_KEY`. Run the Worker tests with `cd worker && npm test`. They check that no AI route or setting comes back.

`FRAPPE_API_KEY` and `FRAPPE_API_SECRET` are present in the current configuration but are not read by the current Worker source. Remove them unless another deployed implementation uses them.

!!! danger "Rotate exposed credentials"
Never commit production JWT, Frappe API, or analytics secrets. If a secret has appeared in Git history, rotate it; removing it from the latest file is not sufficient.

## Frappe deployment checks

1. Apply DocType/schema migrations.
2. Confirm all Worker-targeted whitelisted methods exist.
3. Confirm JWT secrets match Worker configuration.
4. Test the link sign-in, the name picker, the points, the video and quiz steps, the work upload, and the feedback through the Worker URL.

## Release checklist

- No secrets or learner data in the commit.
- Flutter analysis and tests pass.
- Built with `scripts/build_web.sh` on the pinned Flutter version, and the build line (long-press the icon on the link page, or "TAP" on Me) shows the expected commit, Flutter version and Worker host.
- The build was **not** made with `SKIP_UPLOAD=1`. The script refuses that for the production Worker, but check the build line's `API` host anyway.
- Worker tests pass (`cd worker && npm test`), and the Worker dry run/deploy succeeds.
- `mkdocs build --strict` succeeds.
- All bundled assets load in a release build.
- A student can open a magic link, pick a name (a phone with several children), switch profile, and reopen the link after the session ends without losing progress.
- Every `course_id` the backend can send is one of the 14 bundled ids (`test/domain/program_content/bundled_course_test.dart`).
- The storage bucket allows the browser `PUT` for uploads (CORS, including the `x-goog-content-length-range` header).
- Desktop and mobile layouts have been checked.
- Rollback versions for frontend and Worker are recorded.

## A phone shows the old version after a deploy

Two caches can hold the old app:
1. **The browser's HTTP cache.** `firebase.json` now sends `Cache-Control: no-cache` for the files that decide which version runs (`index.html`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `main.dart.js`, `version.json`, `manifest.json`), so the browser asks the server every time. Before, Firebase's default let a phone reuse them for an hour. `test/core/firebase_headers_test.dart` keeps this.
2. **Flutter's service worker.** After a deploy the first load still shows the old version, while the new one downloads in the background. The new version shows on the next load. Flutter 3.47 has no build option to turn it off (it is deprecated, see `todo.md`).

To check what a phone runs, long-press the icon on the "Open your TAP link" page (or "TAP" at the bottom of Me): the build line shows the build time and commit. To get the new version in the WhatsApp browser: close the page completely and open the link again (twice), or clear WhatsApp's cache (Android Settings, Apps, WhatsApp, Storage, Clear cache; this is not Clear data).
