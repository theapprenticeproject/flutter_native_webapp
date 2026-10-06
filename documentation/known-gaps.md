# Known Gaps and Security Issues

TapApp (this repo) and the Frappe `tapapp` module are **prototypes** built quickly to show how the product will work. This page lists the gaps found during a review. Fix the **High** items before real students use the app.

Sources reviewed:

- This repo: `worker/src/*`, `wrangler.toml`, `lib/` (partly), `README.md`.
- Frappe fork `frappe_tap_dd`, branch `origin/pal-v2`, file `tap_lms/tapapp/api/auth/tapapp_auth.py` only. The other `tapapp` files (`profile.py`, `onboarding.py`, `learner.py`, jobs, doctypes) were **not** reviewed.

Severity: **High** = account takeover or data exposure. **Medium** = weakens security or can cause outages. **Low** = cleanup.

## Security

| # | Sev | Where | Issue | Suggested fix |
|---|---|---|---|---|
| S1 | High | Frappe `login_with_password` | If a phone has no password yet, the first password sent becomes the password and the caller is logged in. Anyone who knows a registered phone can claim the account. | Do not set a password on login. Set it only after proof of phone ownership (OTP over WhatsApp, or a valid signed link). |
| S2 | High | Frappe `forgot_password_send_otp` / `verify_otp` | The OTP is the constant `"000000"` and nothing is sent. Anyone can reset the password of any registered phone. | Generate a random OTP, send it through Glific, limit tries, store only a hash. |
| S3 | High | Frappe (all `allow_guest=True` methods) | If the Frappe host is reachable from the internet, callers can skip the Worker and its rate limits. This is **not verified**. | Allow only the Worker to reach these methods (network rule, or a shared secret header checked in Frappe). Add limits in Frappe too. |
| S4 | High | Frappe `check_phone`, `forgot_password_send_otp` | The answers show whether a phone is registered and whether it has a password (`exists`, `has_password`, `phone_not_registered`). This allows phone number enumeration. | Return the same answer for every phone. |
| S5 | Medium | `worker/wrangler.toml` | `ALLOWED_ORIGINS = "*"`. The Worker accepts any website. | List the real origins. Note that the WhatsApp in-app browser opens the same site, so the origin does not change. |
| S6 | Medium | `worker/src/worker.js` | The 500 response returns `err.message` to the client. `routes.js` also returns `err.message` as `detail` on a 502. | Log the detail on the server. Return only an error code. |
| S7 | Medium | `worker/src/ratelimit.js` | Limits are per IP. Many students behind one school IP share them (20 AI calls per hour). The KV read-then-write is not atomic, so limits are approximate. A missing `CF-Connecting-IP` falls into one shared `unknown` bucket. | Add a per-phone limit after login. Use a Durable Object or the Cloudflare rate-limiting binding for exact counts. |
| S8 | Medium | Access tokens (Worker `jwt.js`, Frappe) | Tokens live 90 days and cannot be revoked. The `jti` field is created but never checked. | Keep a revocation list or a per-account token version. Consider a shorter life for link-created sessions. |
| S9 | Medium | Frappe `login_with_password` | No lockout after failed passwords. Only the Worker's per-IP limit applies. | Count failures per phone and slow down or lock after a limit. |
| S10 | Low | `worker/src/tapbuddy.js` | `validateAccessToken(request, env, phone)` skips the phone match when the body has no `phone`. Any valid token works. Low impact, but unexpected. | Use the phone from the token and ignore the body. |
| S11 | Low | Git history | `worker/.env` and `scripts/.env` were committed. The owner says the values in them are no longer current. | Add them to `.gitignore`, run `git rm --cached`, and rotate the keys if any value is still in use. |
| S12 | Low | Frappe `tapapp_auth.py` | `int(fd.get("page"))` and similar calls raise a server error on bad input. | Validate and clamp inputs. |

## Product and design gaps

| # | Sev | Area | Gap |
|---|---|---|---|
| P1 | High | Login | WhatsApp students have no passwords. The current flow assumes they set one on first login (see S1). A new login path is needed. See [WhatsApp link login](whatsapp-link-login.md). |
| P2 | Medium | Data model | `Tapapp Auth` has `teacher` and `admin_code` fields, and profiles have grade, division and roll number. It looks designed for teacher rosters. It is not confirmed that it fits parents with several children. |
| P3 | High | Web storage | The app depends on a long-lived local cache and a stored token. Under the rule that every WhatsApp visit is a fresh launch, the cache gives no benefit between visits and the session is lost. |
| P4 | Medium | Web routing | The app uses Flutter's default hash URLs (`/#/login`). Deep links from WhatsApp need a route that works with this. |
| P7 | High | Progress | Video, submission and quiz points are saved only on the device (`applyLocalProgress`). They go to the server when the unit completes (`submitProgress`, `unit_complete`) or at the next session start. If storage is wiped mid-unit, that progress is lost. |
| P8 | Medium | Weekly limit | Completed units per week are counted on the device (`ClassSessionWindowRepository`). After a storage wipe the count is 0. Whether the server also enforces the limit was **not checked**. |
| P9 | Low | AI cost | Saved AI reviews and the TapBuddy chat history live on the device only. After a wipe, repeated answers call Groq again and the chat starts empty. |
| P5 | Low | Dependencies | `isar`, `isar_generator`, `shared_preferences` and `riverpod_generator` are in `pubspec.yaml`. Use in `lib/` was not confirmed. |
| P6 | Low | Docs | `documentation/deployment.md` says `FRAPPE_API_KEY` and `FRAPPE_API_SECRET` are not read by the Worker. Remove them from config if nothing else uses them. |

## Not yet reviewed

- Frappe: `profile.py`, `onboarding.py`, `learner.py`, `achievements.py`, jobs, and the doctype definitions.
- Flutter: most of `lib/` (screens, providers beyond those already read).
- Whether the Frappe host is reachable without the Worker (S3).
