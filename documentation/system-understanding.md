# TAP system: how it works today

**For:** the TapApp team. Use this page so you do not have to read the backend code each time.
**Based on:** `frappe_tap`, branch `journey_2026` (last commit 2026-10-27), read on 2026-10-29. It replaces the older `TAP_LMS_System_Understanding.md` from branch `pal-v2-health` for everything TapApp needs.
**Confirmed (2026-11-04):** the deployed branch is `journey_2026`. Flows and code on every other branch are not relevant.
**How it was checked:** by reading the code. Nothing was run. Each fact is marked:
- **Verified**: seen in the code on `journey_2026`.
- **Not verified**: we could not confirm it from the code. Ask the team (see section 9).

Short codes (R-, O-, PL-) are explained in [codes.md](codes.md).

---

## 1. Read this first

The older document describes the **Summer Program** engine as the live system. On `journey_2026` that is no longer true. The main changes:

| Older document says | `journey_2026` shows |
|---|---|
| A job runs every minute and moves each student through a state machine (`ProgramEnrollment`). | **Verified:** all of that is commented out in `hooks.py`. The state machine, escalations, weekly advance and points hooks do not run. |
| `summer_program/save_submission` is the active submission call. `imgana/submission.py` is deprecated. | **Verified:** the other way round. `imgana.submission.submit_artwork` works on its own. `save_submission` still exists, but it needs an active `ProgramEnrollment` and nothing creates one now. |
| Glific calls `ready_to_receive_feedback` when the student asks for feedback. | **Verified:** feedback is requested when the work is submitted. A scheduled job starts the Glific feedback flow three times a day. |
| Quizzes run on the server (`start_quiz`, `submit_answer`) and store each answer. | **Verified:** the live quiz calls only read data. No quiz answer, score or points are stored in Frappe. |
| A monitoring job reads the dead letter queues every 5 minutes. A middleware logs every request. | **Verified:** none of that is on `journey_2026`. It exists only on `pal-v2-health`. |
| Student, points and level live in `ProgramEnrollment`. | **Verified:** nothing fills those fields on the live path. |

**Two submit calls exist on `journey_2026`:**
- The **regular** call, `imgana.submission.submit_artwork(assignment_id, student_id, submission)`, for a registered student. TapApp uses this one. **Confirmed by the lead developer (2026-10-30):** a production call is `POST /api/method/tap_lms.imgana.submission.submit_artwork` with a JSON body of `submission` (a file link), `student_id` and `assignment_id`. (The header line was removed from the sample before it was shared.) This matches the code on `journey_2026` and supports our assumption that it is the deployed branch. The sample shared with us had the header removed before sharing, so it says nothing about authentication.
- A **demo** call, `imgana.demo_submission.submit_artwork(assignment_id, glific_id, submission, language)`. It has no registered student: it uses one fixed demo student for each language and keeps the Glific id in a comment. It is not for real students, and TapApp does not use it.

---

## 2. The services

```
Student (WhatsApp)
      |
   Glific  ----- API calls ----->  tap_lms (Frappe)
      ^                                 |
      |                          [submission queue]
      |                                 v
      |                             tap_plg  (plagiarism, AI-image check)
      |                                 |
      |                       [plagiarism feedback queue]
      |                                 v
      |                           rag_service (AI feedback, Gemini)
      |                                 |
      |                       [feedback results queue]
      |                                 v
      |                 tap_lms feedback consumer (saves feedback, makes audio)
      |                                 |
      +---- scheduled job starts the Glific "feedback" flow (15:00, 16:30, 21:00 IST)
```

| Service | What it does | Notes |
|---|---|---|
| `tap_lms` | The main app (Frappe v14, Python, PostgreSQL). Students, batches, courses, assignments, submissions. | Repo `frappe_tap`. Branch `journey_2026` is the latest. |
| `tap_plg` | Plagiarism and AI-generated image check (CLIP, perceptual hash, FAISS or pgvector). Not Frappe. | Branch on this machine: `integ-health-mon` (August 2026). Not checked for newer branches. |
| `rag_service` | Writes the AI feedback. Frappe app. Providers: Stub, OpenAI, TogetherAI, Gemini. Models in code: `gemini-2.5-flash-lite` (text), `gemini-2.5-pro` (audio and video). | Branch on this machine: `va-health-mon`. The older document said Vertex AI. |
| Glific | The WhatsApp platform. Runs the student flows. Not our code. | Streams its logs to BigQuery. |
| `tap_ai` | A conversational AI engine (voice and text). Models: `gpt-4o-mini`, `text-embedding-3-small`. | Branch `monitoring` (June 2026). TapApp does not call it in v1. |

---

## 3. Infrastructure

- **Verified:** the deploy scripts (`tap-devops`) install each service on its own server with nginx, supervisor, Postgres 15 and Redis 7. The feedback consumer runs as a systemd service (`tap-lms-feedback-consumer.service`), not as a Frappe job.
- **Not verified:** whether production uses one shared CloudAMQP broker (the older document) or a RabbitMQ on each server (the install scripts suggest this). Also not verified: Frappe 14.29.0, bench 5.16.2 and the VM sizes.
- **Queues** (names are settings in the `RabbitMQ Settings` doctype in `tap_lms`):

| Queue | From | To |
|---|---|---|
| `submission_queue` | `tap_lms` | `tap_plg` |
| `plagiarism_feedback` (the setting is called `plagiarism_results_queue`) | `tap_plg` | `rag_service` |
| `feedback_results_queue` | `rag_service` | `tap_lms` consumer |

  `tap_plg` keeps its queue names in its own `.env` (defaults `plagiarism_submissions` and `plagiarism_feedback`). Names must match in all three places. **Not verified** in production.
- **Storage (GCS):** two buckets, chosen by the `GCS Settings` doctype. **Authenticated** holds submitted work (path `submissions/{submission_id}_{filename}`). **Public** holds feedback audio (path `audio_feedback/...`). The saved URL is a plain `https://storage.googleapis.com/<bucket>/<path>` link with no signature.
- **Audio feedback:** made with ElevenLabs (text to speech), uploaded to the Public bucket.

---

## 4. What runs in `tap_lms` on `journey_2026`

**Scheduled jobs (all in `hooks.py`):**

| When (IST) | Job | What it does |
|---|---|---|
| 02:00 daily | `teacher_bot.bigquery_sync.sync_submission_images` | Attaches image links from BigQuery to teacher submissions. Does nothing unless BigQuery Settings is on. |
| 15:00, 16:30, 21:00 | `imgana.feedback_delivery.dispatch_*` | Starts the Glific feedback flow for every submission with feedback ready. Does nothing unless "Enable Batch Feedback Delivery" is on (default: on). |
| 02:00 daily (20:30 UTC) | `student_sheet_registration_job` | Registers students from Google Sheets (see 5.1). |

**Not running** (commented out): the one-minute dispatcher, escalations, the weekly advance and content sweeps, the hourly watchdogs, the points hooks on `StudentContentLog` and `StudentQuizAttempt`.
**Only live document event:** `School.before_save`.
**Not on this branch:** the middleware and monitoring files, the dead letter queue monitor, rate limits. Nothing in `tap_lms` limits request rates.

**Settings doctypes:** Feedback Delivery Settings, RabbitMQ Settings, GCS Settings, Glific Settings (and Glific Sync Settings), BigQuery Settings, ElevenLabs Settings, Gupshup OTP Settings, SwiftChat Settings, WhatsApp API Settings, Voice Agent Settings (VocaLabs), `API Key`.

---

## 5. The student journey in WhatsApp

### 5.1 Registration and identity

- **Verified:** a `Student` has an id like `ST00051295` (`ST` plus 8 digits). The phone is stored as 12 digits with the `91` prefix. Lookups accept both the 10-digit and the 12-digit form.
- **Verified:** each student has their own `glific_id` field (not unique in the schema). In Glific the contacts of siblings can share a phone number but have different names. The Glific contact keeps the student's id in a field called `student_id`. That field is the link back to Frappe.
- **Three ways a student is created:**
  1. `create_student_web` (a web or WhatsApp form). It queues a Glific sync that finds or creates the Glific contact and saves `Student.glific_id`.
  2. The daily **Google Sheet job**. The Glific registration flow writes a row to a sheet (one sheet per language). The job reads it and uploads the contacts to Glific as a CSV (columns: name, phone, language, school_id, state, model, buddy_name, batch_id, grade, level, course, student_id, collection). The job does not set `glific_id`.
  3. A **bulk import** job from a spreadsheet, and an older `api.py` call `create_student`.
- **Siblings (confirmed by the lead developer, 2026-10-30):** today only **one child of a family is saved** as a `Student`, because the Glific flow cannot deal with siblings. Siblings will be saved as separate records once the app is working. This matches the code: the sheet job rejects a second row with the same phone ("Duplicate contact_phone_number"), and `create_student_web` looks the student up by phone only, so a second child updates the first student and the differences go into `Student.data_mismatch`. The older call `get_student_by_phone_and_name` uses phone and name, but it only reads. The lead developer will create new Glific contacts on the same number (Glific contact API) before the app is released. **For TapApp we assume that siblings on one phone are separate `Student` records, each with their own Glific ID.** How they are created is outside this project (v1 requirements, R-34).
- **Enrollment:** a `Student` has a child table `Student Enrollment` (batch, vertical, level, grade, date joined, school). When a student has several rows, the **latest date joined** is the active batch. Verified in `get_student_by_phone_and_name` and in the sheet job.
- **Consent:** the `Student Consent` doctype is keyed by **phone**, not by student. It only ever raises consent, never lowers it.
- **Schools, batches, teachers:** `Batch Onboarding` links a batch and a school. `School Batch Enrollment` stores the model, date of joining and grades and courses. Teachers have a role list (Principal, Head Teacher, Nodal Teacher, Teacher, Govt Nodal Officer, Mentor Teachers, Zonal Coordinators, Deputy Director Education, District Coordinator). TapApp v1 has no teacher role.
- **Hard-coded:** the map from batch id to Glific collection is in code (`GLIFIC_COLLECTION_BY_BATCH_ID`). A new batch needs a code change.

### 5.2 Weekly content: what is the week, and what comes next

- **Content model (verified):** `Batch` has dates and a program. A `Course Level` has a list of `Learning Units` with a **week number**. A `Learning Unit` has content items: `VideoClass`, `Quiz`, `Assignment`, `NoteContent`, `CourseProject`. A video has links per language (YouTube or Plio). A quiz has questions, options, a correct option, `points` and `failed_points`, with translations.
- **What the live Glific flow really uses (from the lead's flow export, 2026-11-02):** the TLM26 flow does **not** call these content calls or `Weekly Student Flow`. For each step it reads a row of a **Google Sheet** (`link_google_sheet`), chosen by the student's batch group (`TLM26_AllStudents_Batch1`, `Batch2`, `Batch MCD`, `Batch Moga_P`). The row gives the video link, the assignment id, the activity name, the allowed media types (`submission_type_1`, `submission_type_2`), `audio_check` and the quiz questions with their answer keys. See section 5.8.
- **Who sets the week (confirmed by the lead developer, 2026-10-30):** the Tuesday 4 pm release is **triggered by hand in Glific**. The activity for a week is the **same for all students in a batch**, and the team **updates it by hand each week**. Nothing in `frappe_tap` does it (no cron, no code). Given the flow export, the update is most likely made in the Google Sheet. `Weekly Student Flow` and `get_student_current_week` exist in `frappe_tap` but this flow does not use them. The old code that built `Weekly Student Flow` was removed from `journey_2026` and was never in `hooks.py`.
- **Who decides the next step:** the Glific flow. The read calls return the current week's content every time. They do not check what the student already did. There is no limit on activities per week on this path.
- **Content calls that exist in `api.py` (all read-only). The TLM26 flow does not use them:**

| Call | Auth | Returns |
|---|---|---|
| `get_student_by_phone_and_name` | api_key in the body | student id, course level, batch, batch active, date joined |
| `get_student_all_enrollments` | logged-in session | every enrollment with batch dates |
| `get_student_video_content` | api_key | current week plus the video link (YouTube or Plio) |
| `get_student_all_week_videos` | logged-in session | videos grouped by week |
| `get_student_quiz_content` and `get_quiz_by_id` | api_key | quiz name, number of questions, question texts (no options) |
| `get_quiz_question_details` | api_key | the question, options a to f, **and the correct answer** |
| `get_multiple_questions` | logged-in session | looks broken (see section 8) |
| `get_course_level_api`, `get_youtube_url` | api_key | onboarding and teacher lookups |

### 5.3 Video and quiz: what is stored

- **Verified:** nothing on the live path records "video watched", "quiz started", each answer, a score, a pass or fail, points, a level, a streak or gems. All the content calls only read.
- The doctypes for that exist (`StudentQuizAttempt` with its answers, `StudentContentLog`, `ProgramEnrollment` with points and streaks), but only the **switched-off** `summer_program` code writes to them.
- **The quiz runs inside Glific** (verified in the flow export): 5 questions with 3 options (A, B, C), the answer key from the Google Sheet, +1 point for each correct answer. Glific adds the points to its contact fields `total_points` and `activity_points`. The answers themselves are not saved in Frappe.
- **Where WhatsApp progress lives (verified in the flow export):** in **Glific contact fields**: `total_points`, `activity_points`, `streak`, `special_gems`, `last_flow_incomplete`, `activity2026_submission_id`, `wrong_sub`, `quiz_notdone` and others. Not in `frappe_tap`.
- **Result for TapApp:** the app's backend has to store video, quiz and points records itself. No existing record fits.

### 5.4 Submitting work

**The call (verified, `imgana/submission.py`):** `POST /api/method/tap_lms.imgana.submission.submit_artwork` with `assignment_id`, `student_id` and `submission`.
- The code does not check a key (`allow_guest`, and the record is inserted with `ignore_permissions`) and checks no phone and no enrollment. Frappe rejects a call whose `Authorization` header is wrong. **A test on a local server (the `save_submission` family) confirmed this:** a valid token works, a wrong token is rejected with 401 `AuthenticationError`, and **no token works** and returns the same data as a valid one. The nginx setup in `tap-devops` and `docs/server_setup.md` has no key rule either. **Not verified:** production (a layer in front of Frappe could differ), and `submit_artwork` itself. The Worker sends the header anyway (R-82). `ready_to_receive_feedback` and `submission_feedback` are open in the same way.
- The demo call (see section 1) takes `glific_id` and `language`. It always uses the demo student of that language, does not look at enrollment, and sets the feedback flow to the old id `34108`. It is not for real students.
- It checks that the assignment and the student exist and that the student has a language. Errors come back as a flat object with `success: false`, `status` and `error_detail`.

**What it does:**
1. Creates a `Submission` (status `Pending`, `is_primary = 1`, feedback flow id `41954`, `feedback_requested_at = now`). It answers at once with `submission_id`.
2. A background job (queue `long`, 10 minutes) processes it:
   - If the `submission` text is a web link: it finds the media type (file **extension first**, then a HEAD request for Content-Type or the file name, then it defaults to image). It downloads the file (30 seconds for images, 60 for audio and video) and uploads it to the Authenticated bucket. `submission_url` is the bucket link.
   - Otherwise it stores the text as `submission_text`. The type is `emoji` if there are no letters or digits, else `text`.
   - Status becomes `Processing`, then the job publishes a message to `submission_queue` (fields: submission id, assignment, student, grade, level, language, type, text, url, is_primary, created_at).
3. If the upload fails, the status is `Failed` and the error is stored in `upload_error_log`.

**Other calls:** `submit_artwork_audio(submission_id, audio)` adds a voice explanation to a submission. `get_assignment_context(assignment_id)` (open, no key) returns rubrics, objectives and reference images.

**Rules that do not exist on this path:** no "one submission a week", no duplicate check, no idempotency key. Every call creates a new primary submission. (The `save_submission` version had those rules, but it needs an active `ProgramEnrollment`.)

**Answered (2026-11-02):** the TLM26 flow calls the regular `submit_artwork` with `student_id` (section 5.8). Which other flows call the demo one is not needed for TapApp.

### 5.5 Feedback and how it reaches the student

1. `tap_plg` checks images. Video, audio and text skip the plagiarism check.
2. `rag_service` writes the feedback and publishes to `feedback_results_queue`.
3. The `tap_lms` consumer (`feedback_handler/feedback_consumer.py`) reads the result and saves it on the `Submission`:
   - status `Completed`, `result_status` (`Success - Flagged` if plagiarised or AI-generated, else `Success - Original`)
   - plagiarism and AI fields, `grade` (a number, default 0), `submission_validity` (`Valid` or `Invalid`)
   - text: `overall_feedback`, `overall_feedback_translated`, strengths, areas to improve, encouragement, and the full JSON
   - `audio_feedback_url` and the rubric rows (Content Knowledge, Creativity)
4. **Valid or not:** `submission_validity` is just what the AI sends. The only change is its capital letters. Nothing in `frappe_tap` decides it.
5. **Stock feedback:** if the work is flagged, or the AI answers "system error" or "submission does not match assignment requirements", the student gets a stock text and stock audio (`stock_feedback_and_audio.json`, per language). If no stock entry exists, the text and audio stay empty.
6. **Audio:** ElevenLabs makes it for valid work. If that fails, `audio_feedback_url` is the text `Null` and the submission still completes.
7. **Delivery (batch, verified):** when "Enable Batch Feedback Delivery" is on (default), the consumer does **not** start the Glific flow. The jobs at 15:00, 16:30 and 21:00 IST do:
   - They pick submissions with status `Completed` or `Failed`, a flow id, no earlier flow start, fewer than 3 attempts, and a request date within the last 7 days.
   - 100 submissions per page, 2 Glific calls per second, one run at a time. The run is stored in `Feedback Delivery Run`.
   - Each submission is claimed, the Glific contact is found, and the flow starts with the variables `submission_id`, `feedback`, `overall_feedback` and `overall_feedback_translated`.
   - **Finding the contact (in order):** a demo comment; a `student_id` without the `ST` prefix is used as the Glific id; `Student.glific_id`; or a lookup by phone, accepted only if the contact's `student_id` field equals the student. A match is saved to `Student.glific_id`.
   - Missing data sets `feedback_delivery_status = skipped:<reason>` (no retry). Glific failures retry at the next window. After 3 attempts the status is `parked` and an Error Log entry "Feedback Delivery DLQ - manual replay required" is written. To retry, clear `feedback_delivery_status` and `feedback_delivery_attempts`.
   - When batch delivery is off, the consumer starts the flow at once (with an old flow id `34108` as a fallback).
8. **What can read feedback from outside:**
   - `imgana.submission.submission_feedback(submission_id)` (open, no student check) returns status, both feedback texts, `audio_feedback_url` and `submission_validity` once the status is `Completed`.
   - `save_submission.get_submission_feedback` returns the same without validity.
   - No call lists a student's submissions. `grade`, strengths, areas to improve and the plagiarism fields are not exposed by any call, but they are on the `Submission` and `tapapp` can read them.

### 5.6 Points, levels, weekly limits

- **Verified:** no points are awarded on the live path. The points hooks are off, and `submit_artwork` and the consumer award none.
- The only points code for submissions is `summer_program.feedback_consumer_hook.on_feedback_ready`. The consumer calls it for `ST…` students. It needs an active `ProgramEnrollment` in state `submitted_awaiting_feedback`, so it returns `no_pe` and awards nothing.
- Quiz and video points were in the switched-off hooks. The `Quiz Question` has `points` and `failed_points`, but nothing uses them now.
- `Student.level` (L1, L2, L3) is a difficulty level, not the "Bronze Buddy" level of the design. There are no points, streak or gem fields on `Student`.
- **Weekly limit:** none on the live path. The week cap (`max_allowed_week`), grace window and next-action times belong to the switched-off engine.
- **Events and campaigns:** nothing exists. `ProgramEventLog` is an audit log of the switched-off engine.

### 5.7 The Summer Program engine (switched off on `journey_2026`)

The code is still there and some calls are still whitelisted (`save_submission`, `get_submission_feedback`, `ready_to_receive_feedback`, `student_progression_sp.*`, `program_enrollment_api.*`, `flow_callback.update_flow_status`). Nothing schedules it. Its calls need an active `ProgramEnrollment`, so they fail or do nothing for students who have none. It has: a `ProgramEnrollment` state machine (11 states), a per-minute dispatcher, an escalation chain (help notes, voice note, parent call through VocaLabs), archetypes and A/B arms, `BatchProgramRun`, points, streaks and gems, and a `update_flow_status` bridge. The older `journey/*` calls return `status: deprecated`.

The Glific flow files of the Summer Program (in `/var/home/rjs/dev/tap`) call these switched-off endpoints. Under our assumption they are not relevant, so this page does not list them.

---

### 5.8 The live Glific flow (TLM26 main flow, version `Tlm26_MainFlow_FirstStep_v1`)

This is the flow the lead developer gave us (`Tlm26_MainFlow_FirstStep.json`, 2026-11-02). The v1 app mimics it. The file also holds the flows `Tlm26_Quiz_Flow` and `TLM26_Activity_FeedabckFlow`, and flows for other programs (`Godrej_tomorrow_maker`, `HourOfAI_2026`) that do not matter for TapApp.

**The order of the steps in the flow:** greeting ("Activity time"), then the **video**, then the **submission**, then the **quiz**, then the **feedback** later.

| Step | What the flow does | Points |
|---|---|---|
| Video | Sends a link to the video (from the sheet row). Waits **5 minutes**, then gives the points. There is no check that the student watched it. | +10 |
| Submission | Waits up to 1 hour for the student's message. It accepts an image or a video. It checks the **media type after the student sends it** against the allowed types in the sheet. If the type is right: +25 points and a call to `submit_artwork` with `student_id` (from the contact field), `assignment_id` (from the sheet) and the file link. The call returns `submission_id`, which the flow stores in `activity2026_submission_id`. If the type is wrong: "You will get 25 points only if you submit your work as photo/video", then **a second chance** (a "Try Again" button). After the second wrong try the flow goes on without the 25 points. | +25 |
| Voice note (some activities) | If the sheet row says `audio_check` is not "No", the flow asks for a voice note and calls `submit_artwork_audio` with the `submission_id`. | none |
| Quiz | Starts a message "Let's start the quiz". 5 questions, one at a time, 3 options each. After each answer: "Correct answer" or the correct answer is shown. At the end: "You answered x/5". | +1 for each correct answer |
| Feedback | Started later (by the delivery job, or entered after a wait). Asks the student to tap to see the feedback. Calls `submission_feedback` with the `submission_id`, then sends `overall_feedback_translated`, the audio (if the audio link is not `Null`), and then checks `submission_validity`. **Valid:** +10 points and praise images. **Invalid:** another path (the field `wrong_sub`). Then a message with total points, gems and streak. | +10 if valid |

**Calls to `frappe_tap`:** only `submit_artwork`, `submit_artwork_audio` and `submission_feedback`, all under `tap_lms.imgana.submission`. Each call sends an **`authorization` header** (the name is in the flow; we did not copy the value). This is also the answer to the question of the header: the live flow sends one.

**What it also does that the app does not need in v1:** certificates with the points (`create_certificate`), streaks (+1 for each submission) and special gems (+2 in some cases), nudge messages (templates such as `summerprogramquiz_nudge`, `sub_1main`), the groups that mark where a student stands (`Activity2026_NotStarted`, `Activity2026_Sibmission_NotReceived`), and the other programs.

**Two things the lead developer told us (2026-11-02):**
1. Because of a limit in Glific and WhatsApp, the flow can only check **afterwards** that the submission has the right media type (image or video). It gives the student **two chances**.
2. **Sending again after the work was found invalid** (by the AI feedback) is an **app-only feature**. It is not part of the WhatsApp flow.

## 6. Authentication and the API surface

| Pattern | Used by |
|---|---|
| `api_key` in the request body, checked against the `API Key` doctype | most older `api.py` calls and the teacher calls |
| No check in the code (`allow_guest`) | the student registration calls, `submit_artwork` and the other `imgana.submission` calls, `save_submission` and its family, `flow_callback`, `vocallabs_webhook`, `teacher_bot` calls |
| Frappe token (`Authorization: token key:secret`), `allow_guest=False` | the `summer_program` progression and enrollment calls, `get_student_all_enrollments`, `get_quiz_by_id` and a few more |

- The Glific flows send a token on every call. For calls that are `allow_guest`, the token is not enforced.
- Frappe does not handle `Authorization: Bearer` in a special way in this repo.
- **A local test confirmed that calls without a token work** and only a wrong token is rejected (401). Production is not tested (section 9).
- **Verified:** a secret key for a WhatsApp sender is hard-coded in `api.py` (two places) and is the default in `frappe.conf`. The Glific flow exports also hold a literal API token. Treat both as secrets to rotate. This page does not copy them.
- Nothing checks that the caller owns the `student_id` or `submission_id`.

---

## 7. What TapApp can rely on

| TapApp needs | Source today | Note |
|---|---|---|
| The student and their children by phone | `Student` (phone 12 digits, own `glific_id`, name, grade, language, enrollments) | Siblings: see section 9. |
| The active batch and course | `Student Enrollment` (latest date joined), `Course Level` | Read by `tapapp`. |
| This week's activity (video, quiz, assignment) | `Weekly Student Flow` (week) plus `Course Level`, `Learning Unit`, `VideoClass`, `Quiz`, `Assignment` | The team sets it by hand each week for the whole batch, and where is not verified (v1 requirements, R-93). |
| Quiz questions and the correct answer | `Quiz Question` and its options | The correct answer must not be in the CDN files. It goes to the app only with the quiz start call, and the server checks the answers again (R-91). |
| Save "video watched", quiz answers, points, level | **Nothing** | New records in `tapapp` or `frappe_tap` (R-87, R-90). |
| Submit work | `submit_artwork(assignment_id, student_id, submission)` | Open to anyone. The Worker must call it. R-89. |
| The student's own submitted file | `Submission.submission_url` in the Authenticated bucket | Plain link. The Worker reads GCS with a service account (R-88). |
| Feedback text and audio | `Submission` fields, or `submission_feedback` | `tapapp` can read the table. |
| Valid or not valid | `Submission.submission_validity` (set by the AI) | Grade 0 or the "technical issue" text is treated as not valid (R-92). |
| When feedback reaches the student | The batch job at 15:00, 16:30 and 21:00 IST | See R-50, R-80, O-28. |
| Events and the banner | **Nothing** | New feature (R-86). |

---

## 8. Known problems in the code (journey_2026)

- A secret key is hard-coded in `api.py` (see section 6).
- `get_student_current_week` takes the first `Weekly Student Flow` record whose end date is today or later. It has no batch filter and no sort order, so it is only right if exactly one such record exists at a time. WhatsApp content has the same problem today. TapApp reuses the same logic unchanged (v1 requirements, R-93), so the app and WhatsApp stay in step, with the same weakness.
- `get_assignment_context` uses `base64` and `mimetypes` without importing them. Every reference image fails silently, so `reference_images` is always empty, and an Error Log is written for each image.
- `get_multiple_questions` calls `get_quiz_question_details` without the `api_key`, so it probably raises an error.
- `resolve_student_id` accepts a phone number and returns an arbitrary first match, which is wrong for siblings.
- Kannada maps to the language code `ka` for ElevenLabs. The ISO code is `kn`. Unknown languages default to `mr`.
- `plagiarism_status` can be empty when `is_plagiarized` is true but the source is unknown.
- The consumer requeues errors it does not recognise with no limit, so a message could loop for ever. Retries for publishing to `submission_queue` stop after 5 and write an Error Log entry "Feedback Pipeline DLQ - manual replay required". After that the `Submission` stays in `Processing`.
- A `Submission` with status `Failed` is still eligible for feedback delivery. Empty feedback might be sent. Not tested.
- The AI sets validity. A failed AI run can be published as `Valid` with grade 0 (older finding PL-1; not re-checked in `rag_service`).
- Registration saves one student per phone. The lead developer confirmed this: siblings are added later, once the app is working (section 5.1).
- Several patch files named in `patches.txt` (for example `add_pe_glific_id_unique_index`) are missing from disk. The patch belonged to the old "siblings share one Glific id" rule and is stale.
- The batch to Glific collection map is in code.

---

## 9. Open questions for the team

1. **Which branch is deployed?** Answered: `journey_2026` (confirmed 2026-11-04).
2. **Is the `Authorization` header required and checked in production, and where?** A local test (`save_submission` family) accepted calls with no token and rejected a wrong one. Please test `submit_artwork` on production with no header, a wrong header and a valid header, and say if there is a layer in front (for example Cloudflare or a load balancer).
3. **Answered (2026-11-02):** the TLM26 flow reads the activity from a Google Sheet for each batch group, not from `Weekly Student Flow` (section 5.8). Nothing is needed for v1. For v1.1 we still need to know where the team updates the sheet each week.
4. **Siblings:** how the second child gets a `Student` record is outside this project. We assume it is done (R-34). Please tell us if the plan changes.
5. **Answered (2026-11-02):** quiz results and points live in Glific contact fields (`total_points`, `activity_points`, `streak`, `special_gems`), not in Frappe (section 5.3).
6. **Is "Enable Batch Feedback Delivery" on in production, and on the dev server?** The v1 test runs on the dev server (A18).
7. **Does anything still call `ready_to_receive_feedback`?**
8. **Is `tap_plg` / `rag_service` / `tap_ai` on a newer branch** than the health and monitoring branches on this machine? Does production use one shared RabbitMQ broker or one per server?
9. **Which `rag_service` models are used in production** (the code names Gemini models; the install notes mention a Groq key)?

---

## 10. What this page leaves out

The older document also has long sections on a monitoring plan, a dead letter queue design and error classification. They describe work on the `pal-v2-health` branch that is not on `journey_2026`. If you need them, read `docs/TAP_LMS_System_Understanding.md` on that branch.

Not checked: the Glific source in `/var/home/rjs/dev/tap/glific`, the full body of each `summer_program` file, and the hosting facts that only exist outside the code (VM sizes, domains).
