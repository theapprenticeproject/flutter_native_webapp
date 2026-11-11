# What needs to change in `tapapp`

**For:** the author of the `tapapp` module (about 4,900 lines in `frappe_tap_dd`, branch `pal-v2`).
**Date:** 2026-11-03. Updated 2026-11-06.
**Read with:** `v1-requirements.md`, `system-understanding.md`, `whatsapp-link-login.md` and `backend-plan-feedback.md`.

## How to read this

The `tapapp` module will be added to `frappe_tap`, branch `journey_2026`, as a module in the same app (R-46). Only this module moves. The other branches are not needed.

**The requirements document always wins.** If this note and the requirements differ, we follow the requirements.

We read the code. We did not run it. Where we could not check something, this note says "not verified". You wrote the code, so you may know better. Please correct us.

**The short version.** `tapapp` was built as a teacher and class app with a password login and a game layer (XP, streaks, gems, levels, archetypes). v1 is different: a test release for under 100 pre-registered kids, with a WhatsApp magic link, no streaks and no weekly limit. Some parts can be kept. Most of the login and the progress model must change.

## 1. What stays, what changes, what goes

| Part | Decision |
|---|---|
| Profile and auth plumbing, the Postgres access, the shape of the content export | Keep, with changes |
| Login with a password, the OTP reset, `check_phone`, `admin_code`, `teacher` | Remove |
| `Tapapp Learner`, `Tapapp Auth Profile` | Do not copy them. They never existed on `journey_2026` and the prototype holds no real data, so no removal patch is needed. Progress goes into `ProgramEnrollment` and its child table Unit Progress (R-48), and children come from `Student`. |
| XP, streak, gems, level window, archetype, achievements, weekly cap | Remove from v1 (R-39, R-72, section 2 of the requirements) |
| Both daily jobs (`nightly_window_maintenance`, `tapapp_analytics_report`) | Leave out of v1 |
| Progress counters, the content export | Rewrite (sections 3 and 4) |
| Quiz, submissions, points rules, valid-feedback check, the feedback link | Missing. Add (section 4). |

## 2. Fix first: security

These must be fixed before any real child uses the module.

1. **Anyone can take over an account.**
   - `login_with_password` (`tapapp_auth.py:215-219`) sets the password at the **first** login. Anyone who knows a registered phone can claim it.
   - The reset OTP is a fixed `"000000"` (`tapapp_auth.py:6`, `:291`), and no message is sent.
2. **Anyone can read or change any learner's data.** These calls are open to guests and have no token check: `get_learner_state`, `get_learner_progress`, `get_learners_progress`, `enroll_course`, `record_activity`, `update_content_progress`, `get_learner_achievements` (`learner.py:334-495`, `achievements.py:38`). They take a `learner_id` and nothing else.
3. **XP comes from the caller.** `record_activity` takes `xp` from the request (default 10). Anyone can send a huge number. The server must decide the points (R-37, R-75).
4. **Award and webhook calls only need "logged in".** `submission_verified_webhook` (`learner.py:596`) and `award_achievement` (`achievements.py:46`) have no role or key check. Anyone who is logged in could award points.
5. **Export calls only need "logged in" too** (`export.py:544`, `:604`) and return quiz data.
6. **No rate limit** on `login_with_password`, `check_phone` or the OTP calls. `check_phone` also shows whether a phone is registered.
7. **Points are added again on every retry.** Nothing stops the same call from counting twice (an idempotency key would do this). The weekly cap check and the update are two separate steps, so two calls at the same time can both pass the check (R-38).
8. **Token design.** The token lasts 90 days and is renewed silently, without checking the student again. The secret comes from a `Secrets` doctype and is cached in Redis. There is no way to revoke a token. (This describes the prototype. In v1 the Worker issues the tokens and Frappe issues none, see the **Login** row in section 3. The link secret is an encrypted Password field in our settings DocType, see section 6.)
9. **Commits in the middle of a request** (`frappe.db.commit()` and raw `SAVEPOINT` in many places) can leave half-written data after an error.
10. **Fixed values in code:** the OTP, the token lifetimes, `SUBMISSION_XP = 25`, `max_weekly_activities or 2`, the owner `'Administrator'` on raw inserts (`achievements.py:63`, `learner.py:400`), and the level `"Level 1"`. R-41 says these must be settings on the server.
11. **Raw SQL with column names built from the request** (`set_clause`, `col_list`). The names are checked against a list today, so it is safe now, but a small change could make it unsafe.

**What to do.** Remove `allow_guest` from all of these. Every call must take **one Worker credential** (an API key or an HMAC), and the Worker tells you the phone and the student. The Worker checks once, at `select_student`, that the student belongs to the phone. After that, every call carries the `student_id` and not the phone (R-81). Use that `student_id`. Never trust a typed phone number (R-33) or a `student_id` that comes from the request body.

## 3. Change to match the requirements

| Area | Today | What we need | Requirement |
|---|---|---|---|
| **Login** | A password. Teacher and class model (`teacher`, `admin_code`, grade, division, roll number). | A signed WhatsApp magic link that carries the phone. **Frappe may create the link** (one function makes every link, A16), using a secret that it shares with the Worker. The **Worker** checks the link and issues the access tokens. Frappe does not issue login tokens and does not store a one-time token. The backend trusts only the Worker. No password and no OTP. | R-31 to R-34, R-81, `whatsapp-link-login.md` |
| **Children of a phone** | A `Tapapp Auth` row for each phone, with a profile table. Nothing in `tapapp` creates the profile rows (not verified where they come from). `Auth Profile.student` is a link that is not unique. | Read the children from `Student where phone = X`, in both the 10-digit and 12-digit forms. Only students with an enrollment in an active batch. No profile table. | R-34, LS4 |
| **Progress record** | `Tapapp Learner` with `xp`, `level`, `streak` and more, plus `Tapapp Enroll`. | One record, `ProgramEnrollment`. It is empty today because the old Summer Program engine is off. It keeps only the summary numbers (the point fields it already has). The steps are in its child table, Unit Progress, with one row for each unit. No second copy. | R-48 |
| **Progress counters** | `update_content_progress` keeps counters (`videos_completed`, `quizzes_completed`, `submission_index`) and uses the SQL function GREATEST, which keeps the larger number. | One **Unit Progress** row for each unit (a child table of `ProgramEnrollment`). Each step has its own time field and its own points. A step is written only once, so a repeat gives no extra points (the exception is "send again": a new `Submission` updates the link to the latest one, and the points for sharing and for valid work are still given once). The quiz answers are stored as JSON in the same row. | R-38, R-40 |
| **Points** | The client sends the XP. `SUBMISSION_XP = 25` is given when a webhook arrives. | The server decides. Video +10, sharing the work +25 (at once), each correct quiz answer +1, correct submission +10 (after valid feedback only). Values are settings. | R-37, R-41, R-75 |
| **Level** | A string, `"Level 1"` by default. | Worked out from the points with thresholds in settings. | R-41 |
| **Profile edits** (later, task B17, R-74) | Written to the Tapapp tables only. `school` cannot be edited. | Writes to `Student` are approved (2026-11-05), but the profile edit is later, so it is not built in v1. | R-74, "Rules for our changes" |
| **Content export** | `export_program_content` returns the whole payload in the HTTP answer. `include_r2` is not used. `export_content` reads the table `Citizenship Content` (the wrong one). It includes quiz data. | Write JSON files to R2 as in `content-spec.md`, one for each unit and language, with a manifest. Remove the correct answers from files the browser gets. | R-18, R-91 |

## 4. Missing: please add

1. **The quiz on the server (R-91).** Start a quiz and send the answers. The start call returns all questions with the correct answers (decided on 2026-11-04), so the app can show right or wrong at once, also without a network. The app sends all answers when the quiz ends. The server checks every answer again, stores the attempt and every answer, and gives the points. The correct answers must not be in the CDN files.
2. **Submissions (R-27, R-89; task B6).** Nothing links to `Submission` today. The **Worker** makes the short upload link, because it holds the Google Cloud service account (task C5). The **backend** gets the file link from the Worker, makes sure one upload is sent only once, and calls `submit_artwork(assignment_id, student_id, submission)`. The call has no duplicate check of its own, so the backend must supply one.
3. **Valid or not valid (R-76, R-92).** Read `Submission.submission_validity`. A result with grade 0 or the text "technical issue" counts as **not valid**. Give the +10 only for a valid result. Nothing checks this today.
4. **The valid-feedback gate (R-83).** The next activity opens only after the work is submitted and the feedback is valid.
5. **"My projects" data (R-87),** from `Submission`, the points and steps you store, and the course assignments.
6. **Placeholder tags (R-95).** A fixed set for every student. The app keeps the list, so the backend needs no field and no call.
7. **Deletion (R-96), after the test release (task B13, Later).** Photos, videos and the R2 copies are deleted when the student moves to a new batch. This is a once-a-year rule, so it is not part of the test release.
8. **No banner call in the backend.** The Worker returns the empty banner list (R-94). No event code in v1. We only leave room for it.
9. **Tools for the test group:** register the kids who are missing, check that each test kid has a Glific contact with the field `student_id` (without it the feedback job skips the kid and does not retry), and a script that makes the magic links for the 30 to 100 kids.
10. **The feedback link for app students (O-28, Option B; task B14).** (a) Right after the upload, set `feedback_flow_id` on the `Submission` to the new Glific flow for app students. (b) Record that the student is an app student at the first login with the link. Store this flag in a `tapapp` table (for example the student id and the time of the first login), not as a new field on `Student`, so it needs no `Student` write. (c) A webhook that makes the signed feedback link, which carries the student and the Results step (R-50). This needs the product team's approval and the Glific team's new flow.
11. **Find where the test content lives first (task B0).** The lead's Glific flow reads the video links, the quiz questions, the answer key and the assignment ids from a Google Sheet, not from the Frappe quiz tables. `submit_artwork` fails when the assignment id is not in Frappe. Check this before you build the quiz. Also decide, in the same task, where the quiz answer key is kept on the server: a small Frappe table, or private storage that the Worker reads. The answer key must never be in the files that the CDN serves.
12. **Audio clips, example works and the quiz answer key (task B18).** Build the part of the content that is not the unit and flow files: the audio clips with their status (a clip is out of date when its text changed, R-54, R-55), the curriculum's example works (R-58), and the quiz answer key for the server only. This is needed even if the first test bundles the content in the app.
13. **Smaller points:** +1 point for each correct quiz answer (R-75). The level thresholds (the points needed for each level) go in the settings (R-41). The idempotency key for an upload is made for each upload attempt, so "send again" after an invalid result (R-76) makes a new `submit_artwork` call.
14. **Two new fields on `Submission` (decided 2026-11-06).** Add `submission_context` (program, event or challenge) and `sources` (whatsapp or tapapp), and nothing else. After `submit_artwork` returns, set them to `program` and `tapapp`. The default is `whatsapp`, and an empty value counts as `whatsapp`. They are only labels: they are not sent to RabbitMQ (the message is built from a fixed list of fields). Add them with a `tapapp` patch as Custom Fields. **Do not edit the `Submission` DocType file in `tap_lms`.** "My projects" is read through the Unit Progress rows, not through these fields. The copy to R2 is made only for `tapapp`. If the update fails, try it again. A simpler option, if the tech lead prefers it: `Submission.program_enrollment` already exists and the live path does not set it, so setting it marks app work without a new field. The lead's approval of the two fields is recorded in one place, `v1-requirements.md`, "Rules for our changes".

**Not your task:** saving every interaction of the student (R-84). The events go through the Worker and a Cloudflare Queue to BigQuery (tasks C9 and C10). Frappe is not involved, so `frappe_tap` carries no extra load (R-78). **Later (not in v1):** the edit-profile route (task B17, R-74). The plan and the effort are in `v1-task-breakdown.md`.

## 5. Leave out of v1

- Streaks, gems, archetypes, achievements, the weekly cap and the level window (R-39, R-72).
- Both daily jobs. The analytics job sends data to an outside Apps Script address, which we do not need.
- The teacher bulk tools: `search_student`, `get_bulk_students`, `bulk_update_students`.
- `Tapapp Content` news and events (events are v1.1).

## 6. Moving the module to `journey_2026`

We compared the two branches. Copy **only** `tapapp/` and its DocTypes. These items fail or differ on `journey_2026`:

| Item | Problem |
|---|---|
| **`Secrets` doctype** | It is not on `journey_2026`. `tapapp_auth.py:14-20` and the analytics job (`:95-96`) need it, so the login fails. Use an encrypted Password field in our own settings DocType (task B4), the same place as the link secret in `whatsapp-link-login.md`. |
| **Missing DocTypes** | `Assignment Submission Rule`, `Learning Unit Translation` and `Quiz Translation` do not exist there. The export reads their tables (`export.py:204`, `:299`, `:380` and others). |
| **Missing fields** | `Course Level`: `course_image_url`, `download_url`, `translations`, `zip_*`. `Video Class` and `Video Translation`: `video_url`. `Learning Unit`: `translations`. The export reads these. |
| **`hooks.py`** | The two daily jobs are not on `journey_2026`. Do not add them in v1. The `hooks.py` on `pal-v2` also has live `ca.*` entries and a comment block (lines 49-77) that mention the `ca` module. **Do not copy those.** |
| **Python packages** | The code imports `jwt` and `psutil`. `requirements.txt` on `journey_2026` does not list them. Frappe normally installs them, but we did not verify it. If login moves to the Worker, `jwt` is not needed. |
| **Tests** | The files in `tapapp/test/` need a live server and fixed test data. Do not ship them as unit tests. |
| **Migrations** | There are no `tapapp` patches or fixtures to carry. DocType files are picked up by `bench migrate`. Because you do not copy the old DocTypes, nothing needs removing and no patch is needed. Only the new DocTypes are created (Unit Progress and the settings). A unique index on the parent and the unit may need a small patch. |

**Good news.** The module does not import `summer_program`, `journey`, `api.py`, `glific_*` or `ca.*`, so it is self-contained. It uses raw Postgres SQL, and `journey_2026` is also Postgres.

`ProgramEnrollment` has the same fields on both branches. It already has point fields (`total_points`, `total_quiz_points`, `total_submission_points` and others) but no step fields. Do not add step fields to it. Put the steps in the new child table **Unit Progress**, one row for each unit: the learning unit, `video_done_at`, `quiz_json`, `quiz_attempts`, `work_sent_at`, a link to the latest `Submission`, `valid_at`, the points for each step, the status and `completed_at`. **Do not save the whole parent for each step.** Lock the `ProgramEnrollment` row, update only the child row and the summary points. A step with its time already set is not written again, except that a new `Submission` after an invalid result updates the link and the `upload_key` (the +25 and the +10 are still given once). The row also keeps the `upload_key` (the key of the latest upload) so a repeated upload makes no second `submit_artwork` call, and the quiz attempt id is in `quiz_json`. **`ProgramEnrollment` has 10 mandatory fields** (`enrollment`, `student`, `batch`, `program_type`, `glific_id`, `current_path`, `archetype`, `journey_label`, `program_status`, `resolved_flow_state`), most from the switched-off Summer Program engine. Use the values in task B4 (`enrollment` = `TAPAPP-<student_id>`). A student with no `glific_id` or no active batch cannot get a row. If the Summer Program engine is ever switched on again, it could treat these rows as real enrollments, so it must skip them. Tell us before you add any other field to `ProgramEnrollment`.

## 7. Suggested order (smallest useful step first)

0. **Find where the test content lives (B0)** before you build the quiz (see section 4, item 11).
1. Copy the `tapapp/` code only. Do not copy the old DocTypes (`Tapapp Learner`, `Tapapp Auth`, `Tapapp Auth Profile` and the others), the daily jobs or the `ca` hooks. Solve the `Secrets` problem. Check that `bench migrate` passes on `journey_2026`.
2. **Close the security holes** (section 2): no guest access, one Worker credential on every call, every call uses the `student_id` that the Worker sends (R-81).
3. **Leave out the password and OTP code,** `Tapapp Learner`, `Tapapp Auth Profile`, streaks, gems, archetype, the weekly cap and both jobs (do not carry them over). Read the children from `Student`.
4. **Add the new Unit Progress child table** under `ProgramEnrollment`, one row for each unit, with the rules above. Keep only the summary numbers on `ProgramEnrollment`. Add a small settings table for the point values and the video minimum time.
5. **Add the server quiz.**
6. **Add the submission call and the valid-feedback check,** and the +10 award.
7. **Add the data for "My projects" and the feedback link (B14).** The placeholder tags and the empty banner list are not in the backend.
8. **Fix the content export** to write the CDN files from `content-spec.md`.
9. **Rewrite the tests** as Frappe unit tests. (The deletion on batch change comes after the test release, task B13.)

Please send us the plan for steps 1 to 4 before you start. If anything in the requirements is not clear, ask. Do not guess.

## 8. Please check this for us

- Are `PyJWT` and `psutil` installed on the production server? (If login moves fully to the Worker, `jwt` is not needed.)
