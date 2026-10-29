# Production readiness review

The Flutter app, the Worker and the Frappe `tapapp` module are prototypes. This page lists what must change before real students use them.

**Codes used in these documents:** see [codes.md](codes.md).

It adds to [Known Gaps](known-gaps.md) and [TODO](todo.md). It does not repeat them. Items there (OTP `000000`, `allow_guest`, 90-day tokens, large files, few tests) still apply.

**How it was made.** Two code reviews, one for the Frappe `tapapp` module and one for `lib/`. Then we spot-checked the most serious findings in the code. Nothing was run against a live site or a phone. "Checked" below means we confirmed it by reading the code. Later we also read parts of `frappe_tap`, `tap_plg` and `rag_service` (section 8).

**Requirement update (2026-10-22).** The prototype keeps progress on the phone and syncs it later. That is **no longer the requirement**. Every step must be saved to the server at once, so a child can continue on WhatsApp or an installed app (see [v1 requirements](v1-requirements.md), R-40, R-48). This changes the items below:
- **AP2 and AP3** (weekly cap never lifts, a failed sync blocks class) come from the local-first design. They go away with a design that saves each step to the server and reads the state from the server. Fix them in that design, not one by one.
- **Known gaps GP7 and GP8** (progress and the weekly count are kept only on the device) are now **must fix**.
- **The "cache forever" learner state and the local weekly window count** must go. The server's numbers are the only ones.
- **Backend:** the server must store the child's exact step. Today it stores counts per course (`videos_completed`, `quizzes_completed`, `submission_index`) and the point calls fire at unit completion. We did not check if a position inside a unit (for example quiz question 3) can be stored. The backend items B5 and B7 (races, repeats, half-saved steps) now matter more, because there will be many small writes.

**Scope update (2026-10-22).** v1 has **no teacher role** and no installed app. It uses the same student-only flow as WhatsApp. So the teacher and roster parts of the prototype are not needed in v1: the `teacher` and `admin_code` fields, the `/students/*` endpoints, the roster cache, and the client-side `checkAdminCode`. Remove or switch them off. This also removes an attack surface and the plain-text `admin_code` in the browser cache (section 4, Storage).

**Constraint and code-review update (2026-10-22).** `frappe_tap` is in production, so we do not change its existing logic without the client's approval (see [v1 requirements](v1-requirements.md), "Rules for our changes"). Because the WhatsApp system's `ProgramEnrollment` is the single progress record (R-48), most of the `tapapp` backend is not needed: `Tapapp Learner`, `Tapapp Enroll`, `Tapapp Learner Achievements`, the XP, streak and window code, and the nightly jobs. Then backend items B1 to B7 are not fixes to make, but code to drop. B8 stays only if the content export stays. The ownership check in the Worker (R-81) stays in every case. The new backend problems now come from the existing pipeline: see section 8.

Priority: **P1** fix before real students. **P2** fix soon after. **P3** cleanup.

## 1. Fix before real students (P1)

### Backend (Frappe)

| # | Problem | Why it matters | Fix |
|---|---|---|---|
| B1 | **Progress calls do not check who owns the learner** (`learner.py`, `achievements.py`). Checked. The Worker only matches the phone to the token. It does not check `learner_id`. Learner ids run in order (`TL00000001…`). | Any logged-in learner can read another child's profile, or add XP, gems and enrollments to any learner. | Call `_require_access_token` and `_owned_learner_id` in every handler, as `profile.py` does. Use the phone from the token. |
| B2 | **`Student` role can read every learner** (`Tapapp Learner` permissions, `read: 1`, no owner rule). Checked. | The standard Frappe REST API may return all learners' birthdates, schools and XP to anyone with that role. We did not check who holds the role in production. | Remove the role, or add a user permission rule. |
| B3 | **No unique index for `ON CONFLICT (parent, achievement)`** in `achievements.py`. We found none in the doctype or patches. | On a fresh site, every "award achievement" call fails. | Add a patch that creates the unique index. |
| B4 | **`/achievements/award` probably fails today.** It uses plain `@frappe.whitelist()`, which needs a Frappe login, and the Worker sends none. `submission_verified_webhook` has the same setup and no secret check. | Awards do not work, or (for the webhook) anyone with a Frappe login can call them. | Decide who calls each method. Add a token and ownership check, or a role or secret check. |
| B5 | **XP, streak and weekly cap can be farmed.** The cap check and the write are separate steps with no lock. XP and indexes come from the client with no limit. Retrying a finished unit gives XP again. The webhook can award twice. | Parallel taps beat the cap. A changed client can send any XP. | Check the cap and write in one conditional `UPDATE`. Work out XP on the server. Accept an idempotency key. Pick one source of truth for submission XP. |
| B6 | **Nightly job is not safe to re-run** and also stops streaks from growing. It shifts the daily XP history with no "done today" marker. It moves the window start date, so the request path never sees an expired window. | A failed run that is re-run shifts the history twice. Weekly learners never gain a streak. | Add a per-learner `xp_rotated_on` date. Put window and streak rollover in one function used by both the request path and the job. |
| B7 | **Commits in the middle of requests** (`frappe.db.commit()` in `learner.py`, `profile.py`, `onboarding.py`). | A later failure leaves half-saved progress (gems saved, no XP, error returned). | Remove the commits. Check the cap before any write. |
| B8 | **Content export is open to any logged-in user** and includes quiz answers (`export.py`). It also runs thousands of queries in one request. | A student can download all answers. A request can hold a worker or time out. | Restrict to a role. Run it as a background job that writes a file. |

### App (Flutter)

| # | Problem | Why it matters | Fix |
|---|---|---|---|
| AP1 | **Login errors are never handled.** Checked: nothing catches `AuthException`, nothing calls `logout()`, there is no log-out button. | After a token expires or is rejected, every screen shows an error and Retry does nothing. The learner is stuck. | One place (a Dio interceptor) clears the session and sends the learner to login. Add a visible log-out. Show a friendly message for 429. |
| AP2 | **Weekly cap never lifts.** Cached learner state is used forever. `windowResetsOn` is saved but never compared with today. The cap is a fixed `2` (checked), and the server value `maxWeeklyUnits` is ignored. | A learner capped this week still sees "cap reached" next week. | Refresh on app start and on each Home visit, and use the cache only when offline. Use the server's cap. |
| AP3 | **A failed progress sync can lock a learner out of class** (`class_session_bootstrap_provider.dart`). No try/catch around the sync. A conflict is not cleared. | Every visit repeats the failed sync and shows "Something went wrong". Offline learners with a finished unit are blocked the same way. | Catch errors. On a conflict, reconcile or drop the local progress. On a network error, continue with local state. |
| AP4 | **Photo and video submissions always pass** and are never uploaded (`class_chat_controller.dart`, checked). | Any picture, even a blank one, earns XP and a gem. Nothing is stored. | Needs the real submission pipeline (known gap GP10). Until then, do not call it reviewed. |
| AP5 | **If the AI review call fails, the learner is told their work was not good enough.** | A correct answer gets "try again" when the network drops or the limit is hit. | Separate "not accepted" from "could not reach the reviewer". Offer Retry for the second and keep the answer. |
| AP6 | **Onboarding can finish with failed saves** (checked: a failed "mark complete" is only printed). Enrolling can send an empty course id. | The learner is sent back to onboarding with no message. | Do not move on after a failure. Show Retry and block the step. |
| AP7 | **Splash image is 7.6 MB** and it is the first screen. The `.mp4`, `.webm` and `.html` next to it (about 2.4 MB) are never used. | On a slow connection inside WhatsApp, the first paint waits for it. | Use a small WebP or a static splash in `index.html`. Delete the unused files. |
| AP8 | **Fonts come from Google at runtime** (30 files use `GoogleFonts.inter`, nothing is bundled). | On a slow or filtered network, text is late or in a fallback font, especially Hindi, Marathi, Kannada and Punjabi. | Bundle Inter and one Noto font per script. Set `GoogleFonts.config.allowRuntimeFetching = false`. |
| AP9 | **Child data stays on shared phones.** Hive holds chats, birthdate, school and name. Only `logout()` wipes it. The phone number is also in the URL (`?phone=`). | Another child on the same phone can see the data. The number stays in browser history. | Log-out clears everything. Pass the phone through state, not the URL. |

## 2. Make content central (replace hardcoded and bundled data)

**Today.** The app bundles 17 MB: 14 courses × 5 languages as JSON, 14 thumbnails, about 20 screen images, one reveal image, and flows for English only. All of it is cached "forever" with no version.

**What is good.** The app already reads content through one class, `AssetDataSource`, behind the `DataLoader` cache. A remote source with the same methods can slot in without changing screens.

**Findings that change the plan**
- The bundled assets are already inside the build, so the "cache forever" step adds no speed. It only hides changes. A fixed typo in a course never reaches a returning learner unless someone bumps `schemaVersion`.
- 4 of 5 course languages (about 4 MB) are bundled but never loaded. The app only asks for `en`. There is no language switch in the UI.
- `flow_manifest.json` lists three files that do not exist (`auth_flow.json`, `auth_registry.json`, `course/science.json`).
- The reveal image for unit N does not exist for N > 1. Every unit falls back to `1.webp` after a failed lookup. The lookup also runs on every rebuild.
- The thumbnail path rule is in two places (`activity_models.dart:38`, `onboarding_flow_widgets.dart:11`).
- Unused: `assets/data/constants/`, `district/`, `states/`, `content/` (event, project, knowledge-centre). The states folder is not even in `pubspec.yaml`.

**Suggested design**
1. **One content API** (from Frappe, through the Worker) that returns, per language: the course index, the course detail, flows, thumbnail and reveal image URLs, and a **content version** for each item.
2. **Store files on a CDN** (such as the Cloudflare R2 bucket that the export code already mentions as `include_r2`). Give each file a version in its URL or an ETag.
3. **A remote data source in the app** that implements the same methods as `AssetDataSource`. The cache key includes the version. The app checks the version on start, and uses the cache only when offline.
4. **Keep a small bundled first-run copy** (one course, English) so a first visit with no network still works.
5. **Mid-unit rule.** Save the course version with the learner's local progress. If the version changes, finish the current unit on the old copy, then switch. Give each unit a **stable id**, not a position. Today a unit that is added, renamed or moved changes which unit the saved progress points to.
6. **Fail clearly.** A failed download must say "cannot load content, try again", not `courseNotFound`. Make `CourseDetailModel.fromJson` fail on missing `id` or `units` (known TODO).
7. **Use `--dart-define`** for the Worker URL (today it is a constant in `app_constants.dart:15`), one value per environment.

## 3. Hardcoded values to move out

**UI text (needs localisation, P2)**
- The fallback name 'Champ' appears in 11 places (for example `home_dashboard_provider.dart:43`, `class_chat_provider.dart:38`, `error_screen.dart:18`, `tap_buddy_panel.dart:161`). A leftover test name 'Aarav' is the default in `app_header.dart:23`.
- Almost all screen text is English in the code. The strings in `class_chat_controller.dart` bypass the flow files, so translating the flows would not cover them. `l10n.yaml` does not exist and `AppLocalizations` is never used.
- Partner text on the splash ('Brought to you by MCD Delhi', 'Govt. of Delhi x TAP Initiative').

**Business rules (should come from the server)**
- Weekly cap `2` (app and backend), `quiz = 5 points per answer`, submission XP `25` and gems `1`, default XP `10`, window `7` days, archetype rules (21 days, streak under 2), password minimum `6`, the "Bronze Buddy / 400 points" rank.
- Backend: the `7` days and default cap `2` are repeated in several places, and the analytics job repeats the level and archetype lists. Put them in one settings doctype or `site_config`.

**Flow structure in code (content)**
- Step ids such as `AF-001`, `AF-006`, `OF-001`… and the order of steps are in the controllers. If a step is missing, `_runStep` can loop without end (stack overflow). Move the order into the flow JSON and fail with a clear error.

**Other**
- Four learning tracks, with labels and emojis, in `onboarding_models.dart`. They must match the `vertical` strings in the course index.
- Many timings (1.1 s, 1.5 s, 2.5 s, welcome hold 5 s, toasts, timeouts). Keep, but name them in one file.
- Time zones: the backend mixes server time, system time, UTC+5:30 and database time. Use one IST date helper.

## 4. Fix soon (P2)

**Backend**
- Raw SQL skips validation, history and link checks. `update_profile` accepts any `language`, `district` or `birthdate`. `enroll_course` accepts any course and does not reset counters when the course changes. Use normal documents except for the hot XP counters.
- `GET` calls write to the database (`_sync_archetype`). The write is lost without a commit and takes a row lock on every read. Compute the archetype on read.
- Nightly jobs probably use the default queue and its timeout. Move the rotation to the long queue. Gate analytics on the rotation finishing.
- Input checks missing: paging values, `LIKE` wildcards, `learner_ids` size, `xp`.
- Error text leaks database and remote messages. Log it, return a code.
- Test scripts (`test/backend.py`, `write_test.py`) ship inside the app, change real passwords and add XP to real learners. `test/config.py` holds keys and is not in `.gitignore`.
- Add indexes for the analytics and filter columns. Add logging, API docs and a version in the path.
- A job hint says a `Tapapp Learner Achievements.level` cast can fail because `level` is a text field. Make it an integer.

**App**
- TapBuddy history grows without limit, is built all at once, and the user's question is lost if the reply fails.
- Opening TapBuddy can trigger a progress sync (a network write) because its context provider watches the class bootstrap. Keep providers read-only.
- Images are decoded at full size. Camera photos have no `maxWidth`, so a 12 MP photo can be held in memory on a 2 GB phone. Set `maxWidth: 1280`, `cacheWidth`, and convert PNGs to WebP.
- Raw errors shown to children (`Failed to load dashboard: …`). Use one shared error widget with Retry.
- Language: the language is always `en`, so TapBuddy always gets English. Use the learner's profile language.
- Storage: `admin_code` is saved in plain text in Hive. The web "secure storage" keeps its key beside the data. Do not cache `admin_code`. Check what the token store really protects.

## 5. Cleanup (P3)

- **Unused dependencies (checked, no imports in `lib/`):** `cupertino_icons`, `shared_preferences`, `isar`, `isar_flutter_libs`, `path_provider`, `riverpod_annotation`, `url_launcher`. Also `isar_generator`, `riverpod_generator` and `build_runner` (no generated files). Remove them. `flutter_tts` goes with the dev page.
- **Unused code:** about 30 declared items never used, for example `AuthRepository.logout`, `checkAdminCode`, `enrollCourse`, four `ApiEndpoints` entries, `updateAvatar`, `clearTranscript`, `AssetLoader.loadRawString`, `AppTheme.softSurface`. The passport shows fixed cards and ignores stored achievements.
- Dead buttons: "Deactivate Account" and "Delete Account" do nothing. `ErrorScreen` is never reached. `_hasSibling` is always false.
- Duplicate code: `ArchetypeConstants` vs `LearnerArchetype`. Cache key prefixes written by hand in four files instead of `CacheKeys`.
- No `Semantics`, no tooltips, and fonts of 8–13 px in places.
- Backend dead code: unused `include_r2` argument, duplicate enrollment query, an unused import, and a possible copy of the `ca` module's XP code.
- Remove `/tts-test` and the `flutter_tts` package unless text-to-speech turns out to work on phones (see the WebView probe).

## 6. Suggested order

1. **Safety on the backend (B1–B5, B7).** One change set, with tests that call the endpoints with another learner's id.
2. **Login and recovery in the app (AP1, AP2, AP3, AP5, AP6).** These are the cases that strand learners.
3. **Content API and remote source (section 2).** Start with the version and the fail-safe, then move courses, then images.
4. **Weight and fonts (AP7, AP8, images).** Quick wins for slow phones.
5. **Nightly jobs and time zones (B6, queue, IST helper).**
6. **Localisation and settings (section 3).**
7. **Cleanup (section 5).** One small commit per item.

Add tests as you go. Start with: the ownership checks, the weekly cap under parallel calls, the nightly job run twice, and the router rules.

## 7. Which Frappe repo each finding applies to

The backend review read the `tapapp` code in the fork `frappe_tap_dd`, branch `pal-v2`. The plan is to merge it into `frappe_tap`, branch `pal-v2-health` (the branch with the extra logging, not yet in the main branch). The `tapapp` review above was done on the fork. We later read parts of `frappe_tap` (branch `pal-v2-health`), `tap_plg` and `rag_service`, only for the submission pipeline (section 8). These backend items still need a re-check after the merge: the scheduler queue and timeout (B6, section 4), who holds the `Student` role (B2), and the logging notes.

**How the two branches relate** (compared inside the fork, which has both):
- They share an old common commit (`710fff6`). Since then `pal-v2` has **225** commits and `pal-v2-health` has **101**.
- `pal-v2` is more than `tapapp`. Its changes since the base are in `tap_lms/tap_lms` (96 files), `tapvoice` (38), `tapapp` (19) and `ca` (19). Merging the branch brings `tapvoice` and `ca` too. Decide if that is wanted, or if only `tapapp` should move.
- Files changed on **both** sides, so likely conflicts: `hooks.py`, and the doctype files for `program`, `batch`, `course_level`, `quiz` and `assignment_submission_media_link`. We did not try a real merge, so we do not know the actual conflicts.
- `hooks.py` is the main one. `pal-v2-health` adds `before_request` and `after_request` (monitoring middleware) and an `Error Log` document event. `pal-v2` adds the `tapapp` and `ca` scheduled jobs. Both sets must stay.
- `pal-v2` added no entries to `patches.txt`, so `tapapp` has no patches. The unique index for achievements (B3) needs a new patch, and `bench migrate` must create the `Tapapp *` tables from the doctype files.
- The monitoring middleware will also cover the `tapapp` calls, which helps with the "no logging" gap. It does not fix the access checks.

**Suggested merge steps** (for the `tapapp` developer):
1. Create a branch from `pal-v2-health` and merge `pal-v2` into it, not the other way round. Resolve `hooks.py` by hand and keep both sets of hooks.
2. Run `bench migrate` on a test site and check that the `Tapapp *` doctypes and the scheduled jobs exist.
3. Run the backend fixes from section 1 on that branch, so they land in the branch that will be delivered.
4. Re-check the items listed above against the merged `hooks.py` and the real roles.

## 8. Findings in the existing pipeline (`frappe_tap`, `tap_plg`, `rag_service`)

These came from read-only reviews of the code on `pal-v2-health`, `integ-health-mon` and `va-health-mon`. They are not checked live, and the branches may differ from production. All of this is production code. We do not change it without the client's approval. The decisions are in the v1 requirements (O-13 and O-22, and R-91 for the quiz and R-92 for the pipeline).

| # | Finding | Why it matters |
|---|---|---|
| PL-1 | If the AI evaluation fails, the result is published as "Valid" with grade 0, and the points step looks only at the plagiarism flags. | A failed run can earn on-time points and looks like a good result. |
| PL-2 | If `tap_plg` cannot download a photo, it passes it on as "original" and drops the failure flag. | A photo nobody checked looks fine. |
| PL-3 | An unopenable file (HEIC, corrupt) is retried 3 times and then dead-lettered. Nothing goes to the student or to `frappe_tap`. | The student waits for ever. |
| PL-4 | Nothing enforces the "12 hours", and no code looks for submissions that never get feedback. The plan for watching dead letter queues (docs, sections 16 and 17) is written, but we did not see it wired in `hooks.py`. | The app needs a "taking longer than expected" state. |
| PL-5 | `save_submission`, `get_submission_feedback` and `ready_to_receive_feedback` accept calls with no key and check nothing per student. `update_batch_week` and `admin_drop_student` check no role. | The Worker must do all checks. A service key can do more than we intend. |
| PL-6 | The quiz sends the correct answer to the client with each question, enforces no time limit and allows unlimited retakes. | Fine in WhatsApp, where Glific shows only the text. A browser could read the answer, so the Worker removes that field before the question reaches the app. |
| PL-7 | No idempotency key: every call to `save_submission` creates a record, and repeated messages are published again downstream. | Retries from the app create extra records and duplicate feedback. |
| PL-8 | `tap_plg` can mark flat or low-noise drawings and screenshots as AI-generated, and compares a photo's small fingerprint with all other students across assignments. | Original work can get 0 points and an "invalid" message. |
| PL-9 | The system is designed for 100,000 students. `tap_plg` runs one process. `rag_service` handles one message at a time. `Submission` and `StudentContentLog` have no index on `student_id`, `assign_id` or `week`. | The roadmap expects 500,000 children by July 2027. |
| PL-10 | The child's photo, voice and text go as raw files to Google Vertex AI. Nothing filters personal information. Logs contain the prompts and results. Request logs hold phone and name as `student_id`. | Data protection (O-13). |
| PL-11 | The file type comes from the URL extension first (`.webm` counts as video). HEIC cannot be opened. There is no size limit. | The app must convert photos to JPEG and voice notes to WAV or MP3 (R-12, R-14). |
| PL-12 | `phone` is not unique and the data holds 10-digit and 12-digit forms. `resolve_student` picks an arbitrary student when several share a phone. | The app must always use the student id, never a phone, for calls. |
| PL-13 | Some documents are wrong: they say the dispatcher handles 100,000 students per cycle (the code does 1,000 per run), and that `save_submission` checks an API key (the code does not). | Do not trust those two statements. |

## Not checked

- No live site, database, phone or WebView was used. The reviewers read code only.
- Backend: the scheduler queue timeout, who holds the `Student` role, and real table sizes and query plans.
- App: about half of the widget files were not read in full (`class_message_content.dart`, `class_reveal_widgets.dart`, `onboarding_flow_widgets.dart`, `onboarding_chat_widgets.dart`, `profile_details_view.dart`, most of `class_submission_card.dart`). Tap-target sizes, text scaling and rebuild cost there are unchecked.
- Whether the server enforces the weekly cap or recomputes XP, and what causes a `conflict` response.
- How `flutter_secure_storage` behaves on web, and how Flutter 3.47 handles the YouTube view factory registered on each build.
