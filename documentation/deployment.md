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

`scripts/build_web.sh` builds the app and saves build details inside it. On the login screen, **long-press the logos** to show a line like this:

```text
Build 2026-10-16T10:42Z · 9462206 · Flutter 3.47.1 (engine 5d531788)
```

The line shows:
- the build time (UTC),
- the git commit (`-dirty` means there were changes that were not committed),
- the Flutter version and the engine.

Long-press again to hide the line. A build made without the script shows `unknown`. Do not deploy that build.

You can also check the engine from outside the app:

```bash
curl -s https://<host>/flutter_bootstrap.js | grep -o '"engineRevision":"[a-f0-9]\{8\}'
```

To change the Flutter version:
1. Upgrade on a separate branch and build.
2. Test the login screen on real phones inside the WhatsApp browser.
3. Then change the version range in `pubspec.yaml`.

`firebase.json` serves `build/web` and rewrites all routes to `index.html`, which is required for `go_router` browser navigation.

## Worker configuration

The Worker needs these bindings:

| Variable/binding  | Purpose                                   |
| ----------------- | ----------------------------------------- |
| `FRAPPE_BASE_URL` | Frappe origin, without `/api/method`      |
| `JWT_SECRET`      | Must match the Frappe TapApp JWT secret   |
| `GROQ_API_KEY`    | Tapbuddy and submission review            |
| `GROQ_MODEL`      | Submission review text model              |
| `ALLOWED_ORIGINS` | Comma-separated trusted frontend origins  |
| `KV`              | Cloudflare KV namespace for rate limiting |

Store secrets with Wrangler, not in `wrangler.toml`:

```bash
cd worker
npx wrangler secret put JWT_SECRET
npx wrangler secret put GROQ_API_KEY
npm run deploy
```

`FRAPPE_API_KEY` and `FRAPPE_API_SECRET` are present in the current configuration but are not read by the current Worker source. Remove them unless another deployed implementation uses them.

!!! danger "Rotate exposed credentials"
Never commit production JWT, Groq, Frappe API, or analytics secrets. If a secret has appeared in Git history, rotate it; removing it from the latest file is not sufficient.

## Frappe deployment checks

1. Apply DocType/schema migrations.
2. Confirm all Worker-targeted whitelisted methods exist.
3. Confirm JWT secrets match Worker configuration.
4. Confirm the default weekly maximum is two.
5. Enable and schedule XP rotation, weekly rollover, and analytics jobs.
6. Test login, profile selection, learner state, and unit completion through the Worker URL.

## Release checklist

- No secrets or learner data in the commit.
- Flutter analysis and tests pass.
- Built with `scripts/build_web.sh` on the pinned Flutter version, and the build line on the login screen shows the expected commit and Flutter version.
- Worker dry run/deploy succeeds.
- `mkdocs build --strict` succeeds.
- All bundled assets load in a release build.
- Login token refresh works.
- A first unit can be deferred and resumed only after confirmation.
- A third weekly activity is blocked by frontend and backend.
- Desktop and mobile layouts have been checked.
- Rollback versions for frontend and Worker are recorded.
