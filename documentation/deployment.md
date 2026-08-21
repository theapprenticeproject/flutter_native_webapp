# Deployment

## Flutter Web

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release
firebase deploy --only hosting
```

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
- Worker dry run/deploy succeeds.
- `mkdocs build --strict` succeeds.
- All bundled assets load in a release build.
- Login token refresh works.
- A first unit can be deferred and resumed only after confirmation.
- A third weekly activity is blocked by frontend and backend.
- Desktop and mobile layouts have been checked.
- Rollback versions for frontend and Worker are recorded.
