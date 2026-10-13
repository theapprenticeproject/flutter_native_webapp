# Known Gaps and Security Issues

TapApp (this repo) and the Frappe `tapapp` module are **prototypes**. They were built quickly to show how the product will work. This page lists the gaps found in a review. Fix the **High** items before real students use the app.

## What was reviewed

- **This repo:** `worker/src/*`, `wrangler.toml`, part of `lib/`, `README.md`.
- **Frappe fork** `frappe_tap_dd`, branch `origin/pal-v2`: only the file `tap_lms/tapapp/api/auth/tapapp_auth.py`.

## Not yet reviewed

- Frappe: `profile.py`, `onboarding.py`, `learner.py`, `achievements.py`, the jobs, and the doctype definitions.
- Flutter: most of `lib/` (screens, and providers not listed above).
- Whether the Frappe host can be reached without the Worker (see S3).

## Severity

- **High:** account takeover or data exposure.
- **Medium:** weakens security or can cause outages.
- **Low:** cleanup.

## Security

| # | Sev | Where | Issue | Suggested fix |
|---|---|---|---|---|
| S1 | High | Frappe `login_with_password` | If a phone has no password yet, the first password sent becomes the password, and the caller is logged in. Anyone who knows a registered phone can take over the account. | Do not set a password at login. Students log in with a WhatsApp link instead (see [WhatsApp link login](whatsapp-link-login.md), D9). |
| S2 | High | Frappe `forgot_password_send_otp` and `forgot_password_verify_otp` | The OTP is always `"000000"` and nothing is sent. Anyone can reset the password of any registered phone. | Lock or remove these methods for students. If any user keeps passwords, use a random OTP sent through Glific, limit the tries, and store only a hash. |
| S3 | High | Frappe (all `allow_guest=True` methods) | If the Frappe host can be reached from the internet, callers can skip the Worker and its rate limits. The server setup guide (`docs/server_setup.md`, a dev setup) shows a standard bench nginx in front of Frappe, Let's Encrypt, and a GCP firewall rule that opens ports 80 and 443. It shows **no** IP allow-list, no authenticating proxy and no gateway. GCP opens such a rule to all addresses unless a source range is set. This is the dev guide. Production uses a different, larger setup (OQ-2), and the proxy question is open (OQ-3). So it is **not verified** for production. | Let only the Worker reach these methods (network rule, or a secret header that Frappe checks). Add limits in Frappe too. |
| S4 | High | Frappe `check_phone` and `forgot_password_send_otp` | The answers show whether a phone is registered and whether it has a password (`exists`, `has_password`, `phone_not_registered`). Someone can use this to list registered phone numbers. | Give the same answer for every phone. |
| S5 | Medium | `worker/wrangler.toml` | `ALLOWED_ORIGINS = "*"`. The Worker accepts requests from any website. | List the real website addresses. The WhatsApp browser opens the same site, so the address does not change. |
| S6 | Medium | `worker/src/worker.js` and `routes.js` | The 500 response returns `err.message` to the client. `routes.js` also returns `err.message` as `detail` in a 502 response. | Write the detail to the server log. Return only an error code. |
| S7 | Medium | `worker/src/ratelimit.js` | Limits are per IP address. Many students on one school network share them (for example 20 AI calls per hour). The counter is read and then written, which is not atomic, so limits are approximate. A request without `CF-Connecting-IP` goes into one shared `unknown` group. | Add a limit per phone after login. Use a Durable Object or the Cloudflare rate-limiting binding for exact counts. |
| S8 | Medium | Access tokens (Worker `jwt.js`, Frappe) | Tokens last 90 days and cannot be cancelled. The `jti` field is created but never checked. The link login plan uses long sessions (30 days), so this matters more. | Keep a list of cancelled tokens, or a token version for each account. Add a visible "Log out" in the app. Fix this before launch. |
| S9 | Medium | Frappe `login_with_password` | There is no lock after failed passwords. Only the Worker's per-IP limit applies. | Count failures for each phone. Slow down or lock after a limit. |
| S10 | Low | `worker/src/tapbuddy.js` | `validateAccessToken(request, env, phone)` skips the phone check when the request body has no `phone`. Any valid token works. The impact is low, but the behavior is not expected. | Use the phone from the token and ignore the body. |
| S11 | Low | Git history | `worker/.env` and `scripts/.env` are tracked by git. The owner says the values in them are not the current ones. | Add them to `.gitignore`. Run `git rm --cached` on both files. Rotate any key that is still in use. |
| S12 | Low | Frappe `tapapp_auth.py` | `int(fd.get("page"))` and similar calls fail with a server error when the input is not a number. | Check the inputs and limit them to a safe range. |
| S13 | High | Frappe, existing WhatsApp system (`save_submission`, `update_flow_status`, and other endpoints called by Glific) | These are `allow_guest=True`. The system documentation says `save_submission` "authenticates the API key (Authorization header)". Test calls use Frappe's standard API token (`Authorization: token <key>:<secret>`). Frappe checks that token itself, before the function runs. In the code we found **no check inside** `save_submission.py`, `flow_callback.py`, `utils.py` or `student_progression_sp.py` that rejects a call without a token. **Tested on a local setup (`save_submission`, existing student, repeated submission):** a call with a correct token works; a call with a **wrong** token is refused (HTTP 401, `AuthenticationError`); a call with **no** token **works** and returns the same data (flow state, program status, current path and submission ID of the student). So the token is checked only when it is sent. Anyone who knows a student ID can skip it. **Confirmed:** each repeated call, including the one with **no token**, created a new `Submission` record (marked "Success - Flagged", plagiarism "Not Checked"). So without a token, anyone who knows a student ID can **write** records for that student, not only read data. A first submission would probably do more (advance the student's state, give points, enter the queue). This was not tested. The team also reports that a wrong student ID is not rejected at the door: the message goes into RabbitMQ and gets stuck there, because the student and assignment details are only fetched later, during evaluation. So bad input fails late and leaves stuck messages (the system doc describes `not_found` messages ending in the dead letter queue). `auth_hooks` is commented out in `hooks.py`, and `middleware.py` does not check keys. The only identity is `student_id`, which can be a student name, a `glific_id` or a **phone**. Student IDs look like `ST00052222`, which are easy to guess. If these endpoints can be reached from the internet, anyone can submit work as a student or change a flow status. Some older endpoints in `api.py` use an `api_key` in the request body instead. A reverse proxy or network rule may protect them: the documentation lists this as open question OQ-3 ("client is checking"). So the code and the documentation disagree, and the real protection is **not known**. | Remove `allow_guest=True` from the endpoints that Glific calls with a token. Do it in steps, so that Glific flows do not break: (1) for a week, log every call that arrives as Guest (the flows that do not send a token will show up); (2) fix those flows; (3) then remove `allow_guest=True`. Also ask the client's technical team (OQ-3): is there a proxy or network rule in production, and does the server check the Authorization header somewhere? (The dev setup guide shows none.) Then add a secret that Glific sends (for example a header in the webhook). This needs the client's technical team, because the Glific flows must send the secret. Do not copy this pattern in new endpoints. |

## Product and design gaps

| # | Sev | Area | Gap |
|---|---|---|---|
| P1 | High | Login | Students have no passwords, but the current login flow asks for one (see S1). A new login path is needed. See [WhatsApp link login](whatsapp-link-login.md). |
| P2 | Medium | Data model | `Tapapp Auth` has `teacher` and `admin_code` fields. Profiles have grade, division and roll number. It looks designed for teacher rosters. We have not confirmed that it fits parents with several children. |
| P3 | Medium | Web storage | The app depends on a long-lived local cache and a saved token. On two Samsung phones, the WhatsApp browser kept saved data for at least 22 hours. iPhone and other Android makers are **not tested**. If a device does not keep saved data, the student needs a new link on each visit. |
| P4 | Medium | Web routing | The app uses Flutter's default `#` web addresses (`/#/login`). Links from WhatsApp need a route that works with this. |
| P5 | Low | Dependencies | `isar`, `isar_generator`, `shared_preferences` and `riverpod_generator` are listed in `pubspec.yaml`. We have not confirmed that `lib/` uses them. |
| P6 | Low | Docs | `documentation/deployment.md` says the Worker does not read `FRAPPE_API_KEY` and `FRAPPE_API_SECRET`. Remove them from the configuration if nothing else uses them. |
| P7 | High | Progress | Video, submission and quiz points are saved only on the device (`applyLocalProgress`). They go to the server when the unit is complete (`submitProgress`, `unit_complete`) or at the start of the next session. If saved data is lost during a unit, that progress is lost. |
| P8 | Medium | Weekly limit | The number of units completed in a week is counted on the device (`ClassSessionWindowRepository`). If saved data is lost, the count becomes 0. We have **not checked** whether the server also enforces the limit. |
| P9 | Low | AI cost | Saved AI reviews and the TapBuddy chat history exist only on the device. If saved data is lost, the same answer calls the AI again and the chat starts empty. The AI review feature will be replaced (see P10), so this applies mainly to TapBuddy. |
| P10 | Medium | Submission review | The prototype sends text and images to an AI model (Groq) through the Worker (`/submission-review/review`). It has no plagiarism check, no storage of the submission, and no `Submission` record in Frappe. It will not be carried forward. TapApp will use the existing pipeline (`save_submission`, plagiarism check, AI feedback). |
| P11 | Medium | Progress models | WhatsApp uses `ProgramEnrollment` (a state machine). TapApp uses `Tapapp Learner` with its own XP, streak, gems and weekly counters. The two have not been compared. See [WhatsApp link login](whatsapp-link-login.md), "Progress between WhatsApp and the app". |
| P12 | Medium | Shared and teacher phones | The code has roster, `teacher` and `admin_code` parts. A phone may belong to a teacher with a whole class. The login-by-link plan assumes one phone belongs to a parent. Not decided. |
