# Build bootstrap: start here in a new chat

**Purpose.** This page gives a new chat everything it needs to start building TapApp v1. Requirements questions are discussed in a separate chat. Do not reopen them here. If a requirement is unclear, check `v1-requirements.md`, make the assumption listed in section 4, and keep going.

**How to use it.** Paste this file (or its path) as the first message. Then say which milestone (section 6) to work on.

Written 2026-10-29. Last updated 2026-11-03.

---

## 1. What we are building

TapApp v1 is a **student web app** (Flutter web). It opens in the **WhatsApp in-app browser on Android**. A student gets a WhatsApp message with a link, logs in with that link, picks their name, and does the weekly activity: **Watch** a video, **Make** (send a photo or video of their work), **Quiz**, and **Results** (feedback from TAP Buddy). The app also has a **Gallery** and a **Me** page. There are three tabs: Home, Gallery, Me.

Out of scope for v1: teacher or parent roles, the installed app, voice recording, the AI agent in Ask TAP, dark theme, Sign out, Deactivate and Delete account, iPhone, onboarding in the app, deadlines, streaks, tiered rewards, the banner and events (v1.1: leave room for them, R-94), a stronger login, and a generic group link.

**The first release (decided 2026-10-30).** A test release in mid-November for a very small group of pre-registered kids (30 to 100, not decided). Each child gets a magic link. The flow is hardcoded and linear: greeting, video, submission, then quiz (R-61), as in the lead's Glific flow. The kids' WhatsApp curriculum is separate, with no sync. The three daily feedback windows are not changed.

## 2. Rules for the chat

- **The user handles git.** Do not commit, push or change branches unless asked.
- **Explain before commands that need approval:** say what and why.
- **Simple English.** The team are not native speakers: short sentences, common words, in chat and in docs.
- **Ask only blocking questions.** If a safe default exists, state it and continue.
- **Say "done" only after the user says yes.** Do not claim a change is finished before that.
- **The v1 test runs on the dev server, not on production.** Do not change production `frappe_tap` logic, and do not deploy to production, without approval. Most items were approved on 2026-11-05; the exception is making `submit_artwork` refuse calls with no key. The list is in `v1-requirements.md`, "Rules for our changes". New backend work lives in the `tapapp` module. Reading `frappe_tap` data is fine.
- **The Frappe key lives only in the Worker** (R-82). The app and the browser never see it.
- **Flutter is pinned to 3.47.1** (`pubspec.yaml`: `>=3.47.1 <3.48.0`). Build releases with `scripts/build_web.sh`, not plain `flutter build web`.
- **Follow `architecture-tenets.md`:** dependencies go `app → features → shared → domain → core`. A feature never uses another feature. Repositories are the only way to data. Screens stay thin. Move code or change code, not both in one commit. Check with `dart scripts/check_architecture.dart`.
- **Never copy secrets** (tokens, keys) into docs, code or chat.

## 3. Where things are

| What | Where |
|---|---|
| The app, the Worker and the docs | `/var/home/rjs/dev/tap/flutter_native_webapp` (`lib/`, `worker/`, `documentation/`) |
| `frappe_tap` (the real backend), branch `journey_2026` | `/var/home/rjs/dev/tap/frappe_tap` (read it, do not edit it) |
| `tapapp` prototype backend (module `tap_lms/tapapp`) | `/var/home/rjs/dev/tap/frappe_tap_dd`, branch `pal-v2`. Only this module moves into `frappe_tap` branch `journey_2026` (R-46). The other branches are not needed. |
| `tap_plg`, `rag_service`, `tap_ai` | `/var/home/rjs/dev/tap/tap_plg`, `rag_service`, `Ai` (health or monitoring branches; may not be the latest) |
| The Figma exports | `/home/rjs/dev/tap/app_design_v1/Student App Direction/` |

**Read in this order:**
1. `documentation/v1-requirements.md`: what we build. Rows marked **Decided** are final. Sections 11 and 12 list open decisions and risks.
2. `documentation/system-understanding.md`: how the TAP backend works today (verified on `journey_2026`).
3. `documentation/whatsapp-link-login.md`: the login by WhatsApp link (decisions A1 to A17, the link format, the Worker and Frappe calls).
4. `documentation/content-spec.md`: the content files and the CDN (draft).
5. `documentation/production-readiness.md`: prototype problems to fix (AP1 to AP9).
6. `documentation/v1-task-breakdown.md`: the list of tasks with their effort and tests. `documentation/tapapp-changes.md`: what must change in the `tapapp` backend module.
7. `documentation/architecture-tenets.md`, `frontend.md`, `deployment.md`, `codes.md`.

## 4. Assumptions to build on

Treat these as true. Each one has a place in the docs. If one turns out false, the rows named in `v1-requirements.md` ("Assumption about the backend") need a second pass.

1. **The deployed backend is `frappe_tap` branch `journey_2026`.** The submit call is `imgana.submission.submit_artwork(assignment_id, student_id, submission)`.
2. **The Worker sends `Authorization: token <key>:<secret>`** on every call to Frappe. Production may or may not require it, but sending it is always safe.
3. **`ProgramEnrollment` is an empty table.** The Summer Program engine that filled it is switched off. `tapapp` stores progress itself: every step (video marked as watched, each quiz answer, work sent) is a row in a new table, `Tapapp Step`, linked to `ProgramEnrollment`, and `ProgramEnrollment` keeps only the summary points (R-40, R-48, R-75, R-87, R-91).
4. **Nothing in `frappe_tap` stores** "video watched", quiz answers or points. We store them.
5. **Siblings on one phone are separate `Student` records** with their own Glific ID. How they are created is not our job (R-34).
6. **There is no weekly release and no deadline in v1.** The flow is linear and hardcoded. The next activity opens after the work is submitted and the feedback is valid (R-83). The weekly release file (R-93) is later.
7. **The v1 flow is hardcoded, and its content is downloaded from the CDN** (R-18, decided 2026-11-02). The curriculum team provides the content. The tech team builds the JSON files (by hand or with a small script) and uploads them to R2 with a manifest, in the shape of `content-spec.md`. The Publish step from Frappe is later. Languages in v1: Hindi and English.
8. **Feedback is shown in the Results step.** A scheduled job in `frappe_tap` starts the Glific feedback flow at 15:00, 16:30 and 21:00 IST. The WhatsApp message carries a signed magic link that opens the Results step (R-50, R-68). How the app students get that message (a new Glific flow) is recommended in O-28 and is not approved yet.
9. **The test content (task B0).** The lead's Glific flow reads the video links, the quiz questions, the answer key and the assignment ids from a Google Sheet. Find out where the test content will live before you build the quiz (B5, B11), and check that every assignment id exists in Frappe, because `submit_artwork` fails for an unknown assignment.
10. **Points:** video +10, sharing the work +25, correct quiz answer +1, correct submission +10. The +10 comes after valid feedback. A result with grade 0 or the "technical issue" text counts as not valid (R-75, R-92).

## 5. Where the code is today

The app is a **prototype**. It must become production ready.

- `lib/` is layered: `app`, `features` (auth, classroom, home, onboarding, passport, settings, splash, welcome, error), `shared`, `domain`, `core`. Routes use the hash form (`/#/...`).
- `worker/src/`: `worker.js`, `routes.js`, `auth.js`, `jwt.js`, `cors.js`, `ratelimit.js`, plus prototype parts to **remove**: `groq.js`, `tapbuddy.js`, `submission_review.js` (the AI review in the Worker will not be carried forward).
- Content is **bundled** in `assets/data/courses/...` and `assets/flows/...`. The target is the CDN (R-18).
- Prototype problems (hard-coded values, the 7.6 MB loader GIF, the Google font download, "2 units a week", streak and gems) are listed in `production-readiness.md` and `v1-requirements.md` (R-43 to R-45, R-39).
- A probe branch `proto/tts-probe` holds the WhatsApp browser test pages (`web/storage-probe.html`). Test results are in `v1-requirements.md` ("What we tested in the WhatsApp browser"). Phones tested: Samsung Galaxy S20 FE and A31. Not tested: Redmi Note 13, iPhone, the video camera.
- Check which branch is checked out with `git branch` before you start.

## 6. Build plan

Each milestone can start now. The "stub" column says what to fake until an answer arrives.

| # | Milestone | What to build | Docs | Stub until |
|---|---|---|---|---|
| M0 | Clean up the prototype | Remove the Groq code and the AI review. Remove hard-coded values. Bundle fonts. Replace the loader GIF. Make errors friendly with a Retry button. | `production-readiness.md` (AP1 to AP9), R-43, R-44 | none |
| M1 | App shell | Three tabs (Home, Gallery, Me). "Who is learning". Welcome back. Offline screen with Retry (R-71). Settings. The Edit profile screen is later (R-74). The TAP Buddy picture is the profile picture (R-60). No photos of students. All text in Hindi and English, with one translated fallback for "Champ" (R-23 to R-25). The Gallery tab has an empty state with example works. | R-1 to R-8, R-60, R-71, R-73, R-74 | fake data behind repositories (R-53) |
| M2 | Login and Worker | Verify the signed WhatsApp link, issue a login token, list the phone's children, `select_student`. The Worker checks that the student belongs to the phone at `select_student`; after that every call carries the `student_id` (R-81). Rate limits. | `whatsapp-link-login.md`, R-31 to R-34, R-81, R-82 | siblings: assume they exist |
| M3 | Activity: Watch and Quiz | Watch step with an "I watched it" button that turns on after 5 minutes (R-90). The quiz starts with one server call that returns all questions with the correct answers. The app gives feedback at once, also offline, and sends the answers when the quiz ends. The server checks them again and stores every answer (R-91). Steps saved at once (R-40). | R-61, R-62, R-67, R-90, R-91 | content from local JSON |
| M4 | Activity: Make | Photo or video capture. Resize photos to JPEG on the phone (R-12). Upload through a temporary link. The Worker calls `submit_artwork` (R-89). Retry on failure (R-13). A message when the camera is refused (R-11). | R-9, R-11 to R-15, R-63, R-64, R-89 | the upload target: a test bucket |
| M5 | Results and points | The Results chat: feedback messages with speaker icons, "Yes" button, the "YOU WON" card (R-68). Points for each step. Valid or not valid, and "send again" (R-76). "Points will be provided after feedback" label. The waiting screen and the "taking longer than expected" state. The audio player that is hidden when a clip is missing (R-17, R-54, R-55). The picture badge, also when Make is postponed (R-69). | R-68, R-69, R-75, R-76, R-83, R-92, F-6 | feedback from a fake record; the message and link: a fake "feedback ready" message |
| M6 | Progress in `tapapp` | The new `Tapapp Step` table (one row for each step, with a unique key so a repeat is saved once), linked to `ProgramEnrollment`, which keeps the summary points. Keep it behind an interface, so the storage can change later. The level is worked out from the points. | R-37 to R-41, R-48, R-87 | none; mark every write to a production table |
| M7 | Content from the CDN | A loader that reads the manifest and the files from the CDN, with the small first-run copy in the app (R-20). Download retry (R-22). Build the content files for the hardcoded flow. | `content-spec.md`, R-18 to R-22, R-79 | a local folder until the R2 bucket exists |
| M8 | Gallery and Me | Gallery with valid work only, the student's initials (not the full name), random order. My projects. Copy to R2 after valid feedback. The skill chips are the fixed placeholder tags (R-95). Copies in R2 are deleted when the student moves to a new batch (R-96). | R-6, R-7, R-58, R-59, R-85, R-87, R-88, R-95, R-96 | none |
| M10 | Feedback link for app students | Set `feedback_flow_id` after the upload, mark the app student at the first login, a webhook that makes the signed feedback link, a Worker route for the link, and a deep link to the Results step (O-28 Option B, R-50). The Glific team builds the new flow. | R-16, R-50, O-28 | a fake "feedback ready" message until the product team approves |
| M9 | Leave room for the banner and events (v1.1) | A banner slot above the activity card, and one Worker place that returns an empty banner list. No event code in v1. | R-5, R-86, R-94 | none |

**Done means** the checks in `v1-requirements.md`, section 13 ("QA"), pass.

## 7. Worker routes to build (a proposal)

Names are suggestions. Keep them small and put the checks in the Worker.

- `POST /auth/link`: verify a signed link, return a phone token and the children of the phone.
- `POST /auth/select-student`: check the child belongs to the phone, return a student token. Later calls use the `student_id` in the token, not the phone (R-81).
- `GET /home`: the student, the points and the next activity for the student (from the hardcoded flow content).
- `POST /steps`: save a step (video watched, quiz answered, work sent). Needs an idempotency key.
- `POST /quiz/start` and `POST /quiz/answer`: run the quiz.
- `POST /submissions/upload-link` and `POST /submissions`: temporary upload link, then the call to `submit_artwork` once for each upload.
- `GET /submissions/:id/feedback`: the feedback, valid or not, and the audio link.
- `POST /auth/feedback-link`: verify a signed feedback link, sign the student in, and return the submission to open (the Results step).
- `GET /me/projects`, `GET /gallery`, `GET /banners` (returns an empty list in v1).

Frappe calls the Worker may use: the read calls in `api.py` (`get_student_by_phone_and_name`, `get_student_video_content`, `get_student_quiz_content`, `get_quiz_by_id`, `get_quiz_question_details`; the last one returns the correct answer, so only the Worker calls it), `submit_artwork`, `submission_feedback`, and reads of `Submission`, `Student` and `Student Enrollment`. The content read calls in `api.py` exist, but the live WhatsApp flow does not use them: it reads a Google Sheet (see `system-understanding.md`, 5.8). v1 uses hardcoded content, so the Worker does not need them.

## 8. Open items (do not wait for them)

The product team's list is in `v1-requirements.md`, section 11: O-1, O-9, O-13, O-18. (O-28 was approved on 2026-11-05.) The backend questions are in `system-understanding.md`, section 9. The ones that touch the build:

| Open | Effect on the build |
|---|---|
| Header check on `submit_artwork` (the branch is confirmed: `journey_2026`) | Test `submit_artwork` against the dev server early (the v1 test runs there). Test production before any later production release. |
| O-28: a new Glific flow for app students, chosen by setting `Submission.feedback_flow_id` right after `submit_artwork`. **Approved on 2026-11-05.** The Glific team still has to build the flow (A10). | M5 stays on a fake message until the flow exists |
| The WhatsApp nudge (R-66) needs a new Glific template and flow (new WhatsApp messages are approved in principle, 2026-11-05) | Leave it out of the test unless the Glific team builds it (A14) |
| Where the test content lives (B0): the quiz questions and the answer key are in a Google Sheet, not in the Frappe quiz tables | Find out first. B5, B11 and D4 wait for it. |
| Do all test kids have a Glific contact with `student_id`, and do the siblings exist as separate `Student` records? | If not, the feedback job skips the kid, and the name picker shows one child. |

## 9. Testing

- `flutter analyze`, `flutter test`, `dart scripts/check_architecture.dart`, `npm run format:check`, `cd worker && npx wrangler deploy --dry-run`.
- Test inside the **WhatsApp browser** on a real Android phone, not only in Chrome. Known limits: no speech synthesis, no background sending, camera, microphone and storage work. The video type is decided by the URL extension first (`.webm` becomes video).
- Add tests for: the Worker's student-belongs-to-phone check, the quiz order check, idempotent steps, and the "not valid" rule.
- Ask the lead developer to test `submit_artwork` on the dev server with no header, a wrong header and a valid header. Do the same on production before any production release.
- There is no CI. The checks run on a developer's machine with one command, and a git pre-push hook runs the quick ones. Both are task E4 in `v1-task-breakdown.md`. Run the full set before each release.

## 10. When you change a requirement

Do not edit `v1-requirements.md` in this chat. Write the change as a short note (row, old, new, why) and give it to the requirements chat. If you must record a build decision, add it to this file under a new heading, with the date.
