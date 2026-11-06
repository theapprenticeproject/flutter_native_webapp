# Feedback on the TapApp backend plan

**For:** "TAP APP New Things" (plan dated 2026-11-01).
**Date:** 2026-11-02. Updated 2026-11-06.

## How to read this

This note compares the plan with our **latest requirements**. It uses short codes: R-27 is a row of `v1-requirements.md`, O-28 is an open decision there, A-, B-, C-, D- and E- numbers are items in `v1-task-breakdown.md`. All codes are explained in `codes.md`.

**The requirements document (`v1-requirements.md`) always wins.** It was reviewed with the product team and the other stakeholders. If this plan and the requirements say different things, we follow the requirements. Please also read `system-understanding.md`. It describes how the current TAP backend works, checked in the code on branch `journey_2026`.

**What v1 is.** v1 is a **test release in mid-November** for a very small group of kids (30 to 100). They are already registered. Each kid gets a magic link. The flow is simple and fixed: greeting, video, submission, then quiz. We keep v1 small. Many items in the plan are good ideas for later, not for v1.

The `tapapp` code will be added to the `frappe_tap` branch `journey_2026`, as a module in the same app (R-46).

---

## 1. Please change these (the plan conflicts with a decision)

| # | The plan says | What we need instead |
|---|---|---|
| 1 | **Remove Student Enrollment** and put it into Program Enrollment. | Do not remove it. The live WhatsApp content calls read the Student Enrollment rows (batch and date of joining) to find the student's active batch. Removing it breaks WhatsApp. We do not change existing production behavior without approval. |
| 2 | **`Student.phone` is unique.** | Do not add this rule. Brothers and sisters share one phone, and each is a separate Student (R-34). Your own login (step 5b, "more than one match") also needs several students on one phone. The data also has both 10-digit and 12-digit phones. |
| 3 | A **new submission flow**: Frappe makes a signed upload link, the phone uploads the file to Google Cloud Storage (GCS), a queue worker checks the file, a `finalize` call marks it as ready, and then the plan hands it to an "external review system". | Use the existing call `submit_artwork(assignment_id, student_id, submission)` as it is (R-27, R-89). The "external review system" already exists: `tap_plg`, `rag_service` and the feedback consumer. You do not need handoff code or a result webhook. |
| 4 | **New Submission statuses**: Uploading, Pending Review, In Review, Approved, Rejected, Expired. | Keep the existing statuses (Pending, Processing, Completed, Failed). Valid or not valid comes from the field `submission_validity` (Valid or Invalid) (R-76). |
| 5 | **Overwrite `submission_url`** with the R2 URL after approval. | Do not overwrite it. The student's own work stays in GCS. Only the Gallery gets a copy in R2 (Cloudflare storage), made after the feedback says the work is valid (R-88). The existing pipeline also uses `submission_url`. |
| 6 | **One retry only**, then the state `attempt_limit_reached`. | After invalid work the student sends corrected work (R-76). The next activity opens only after valid feedback (R-83). If we stop after one retry, a student with a second invalid result is stuck. Do not limit the attempts in v1. |
| 7 | **GCP keys in Shared Settings** inside Frappe, and Frappe makes the signed URLs. | The Cloudflare Worker holds the Google Cloud service account (an account made for programs, not for people). The Worker gives the app a short upload link and reads the files (R-82, R-88, R-89). Keys must not be stored in the Frappe database. |
| 8 | A magic link that is **single use** (a token stored in Redis that is deleted the first time it is used). | A link must work more than once until it expires. A phone can lose its saved data, and the student must be able to open the same link again. (`whatsapp-link-login.md`, settings LS1 and LS2, says how long a link works.) |
| 9 | **Weekly cap, weekly reset, streaks and gems.** (The plan also notes a "Tuesday 4 pm" traffic spike. That is only context: v1 has no weekly release.) | v1 has **no weekly limit and no deadline** (R-39, R-72). **Streaks are paused** (kids do not understand them). Gems are not in the design. The only pace rule is R-83. |
| 10 | A **Program Enrollment** with new fields and new status values. | `ProgramEnrollment` already exists in `frappe_tap` with other fields (`program_status`, `resolved_flow_state`, `current_week` and more). It is empty today because the old Summer Program engine is switched off. We use it as our progress record, but it keeps only the summary points (R-48). Please show how your fields fit into the existing table. Do not create a second table with the same name. |
| 11 | **Unit Progress as a child table** of Program Enrollment (video seconds, quiz answers, status). The plan also says "not required in v1" (see the question in section 7). | **Agreed (tech lead, 2026-11-05):** Unit Progress is a child table of Program Enrollment, with one row for each unit (about 10) and the quiz answers as JSON in the same row. It replaces the separate step table we proposed. It is required in v1. Please add: a time field and a points field for each step (video, quiz, share, valid work), so a step is written once and gives points once; a lock on the parent row while you save; and update only the child row, not the whole parent. We do not track watch seconds in v1: the student taps "I watched it" (R-90). |
| 12 | **Frappe makes and checks the magic link** (a one-time token in Redis) and issues the JWTs (login tokens, in `jwt_utils.py`). | **Frappe may create the signed link**, using a secret that it shares with the Worker (one Frappe function makes every link: A16 in `whatsapp-link-login.md`). The link carries its own signature, so the **Worker** can check it without storing anything. The Worker also issues the access tokens. Frappe does **not** issue login tokens, does **not** store a one-time token in Redis, and trusts only the Worker (R-33, R-81). This is the biggest difference between the plan and our design. |
| 13 | A new **`tap_lms/shared/` engine** that "WhatsApp could call". | Put everything inside the `tapapp` module (R-46). Do not create a `shared/` folder that WhatsApp uses, because we do not change production behavior without approval. |
| 14 | **New fields on the production `Submission` table** (`submission_context`, `source`, `attempts`, `feedback`, the course id, a Rejected Submissions child table) and a database rule that allows only one open submission for each student and course. | **Only two new fields are planned (decided by the tech team on 2026-11-06; the lead's approval is recorded in `v1-requirements.md`):** `submission_context` (program, event or challenge) and `sources` (whatsapp or tapapp). They are only labels that `tapapp` sets after `submit_artwork` returns. The default is `whatsapp`. They are not sent to RabbitMQ. The rest is not accepted: no `attempts` and no `feedback` field (the existing `overall_feedback` and `overall_feedback_translated` already hold the feedback), no course id, no Rejected Submissions child table and no database rule for one open submission. Each `submit_artwork` call makes its own `Submission`, so a retry is a new row. |
| 15 | **`profile.edit_profile` writes to `Student`.** | Writes to `Student` are approved (2026-11-05), but the Edit profile screen is **later** (R-74, decided on 2026-11-05). Do not build it for v1 (task B17). |

## 2. Please add these (in the requirements, missing in the plan)

1. **The valid-feedback gate (R-83).** Your function `advance_unit` moves the student to the next unit when a video or quiz is done. Something must keep the next activity closed until the feedback for the submission is valid.
2. **A quiz that runs on the server (R-91).** We need two calls: one to start the quiz and one to take the answers. The start call sends **all questions with the correct answers**, so the app can give right or wrong feedback at once, also without a network (decided on 2026-11-04). At the end, the app sends all answers in one batch. The server checks every answer again with its own key, stores each answer, and gives the points. The server's result is the one that counts. The correct answer must not be in the CDN files. This is close to your plan, where the app sends the answers in one batch.
3. **Safe repeats (R-38, R-40).** If the phone sends the same step twice, points must be given only once. Use an idempotency key for each step (a key that stops the same step from being saved twice), not only for the points queue. For a submission, make the key for each upload attempt, so "send again" after an invalid result makes a new `submit_artwork` call.
4. **The point rules (R-75).** Video +10, sharing the work +25 (given at once), each correct quiz answer +1, correct submission +10 (given after valid feedback). Your settings have no separate value for the +25. The settings also need the level thresholds (the points needed for each level, R-41).
5. **The full feedback (R-16, R-56).** Feedback has a text, a translated text and an audio file. Your plan has one `feedback` field. The Results screen needs all three.
6. **Valid or not valid (R-92).** A result with grade 0 or the text "technical issue" counts as **not valid**.
7. **Login details** (`whatsapp-link-login.md`):
   - look up the phone in both the 10-digit and 12-digit forms;
   - a link can name one student (with the prefix `st:`) and a place to open;
   - the list of children comes from students with an enrollment in an **active batch**;
   - the Worker checks that the student belongs to the phone once, when the student picks a name. After that, every call carries the `student_id` from the student token, not the phone number (R-81). So your calls take `student_id` and never trust a typed phone number or a `student_id` from the request body.
8. **Content beyond units** (`content-spec.md`): the messages of the standard flow, the audio files, example works, picture pieces. Your export covers only units. Languages for v1 are Hindi and English.
9. **The Gallery rules (R-59, R-85):** only valid work, only pictures and videos, **initials** and not the full name, random order, a small number of items each time.
10. **Deletion (R-96), after the test release:** photos, videos and the R2 copies are deleted when the student moves to a new batch. This is a once-a-year rule, so it can wait.
11. **Tools for the test group:** a way to register kids who are missing, and a script that makes the **magic links for the 30 to 100 kids**. The plan has only a link action inside the ops dashboard, which is "not in focus". Also check that each test kid has a Glific contact with the field `student_id`. Without it the feedback job skips the kid and does not retry.
12. **The feedback link for app students (R-16, R-50, O-28).** After the AI has checked the work, a Glific flow sends the student a WhatsApp message. For an app student, that message must carry a link to the feedback in the app. Your plan has no way to do this. O-28 is the open decision about which Glific flow sends the message. We recommend a **new Glific flow for app students** (Option B in O-28). It needs three things from the backend: (a) right after the upload, set the field `feedback_flow_id` on the `Submission` (it tells the delivery job which Glific flow to start) to the new flow; (b) record that the student is an app student at the first login with the link, in a `tapapp` table and not as a new field on `Student`; (c) a webhook (a web address that Glific calls) that makes the signed feedback link, which carries the student and the Results step. This needs the product team's approval.
13. **Check where the test content lives first.** The lead's Glific flow reads the video links, the quiz questions, the answer key and the assignment ids from a **Google Sheet**, not from the Frappe quiz tables. `submit_artwork` fails when the assignment id is not in Frappe. Your content export reads Frappe, so check this before you build the quiz or the export. Decide where the quiz answer key is kept on the server. It must never be in the CDN files (the files that the app downloads from internet storage).
14. **Save every interaction of the student (R-84). This is needed in v1 (P1), but it is not backend work.** It covers the chat conversation and every other interaction (taps, screens opened, steps done, errors), so we can study how the kids use the app. The events go from the app to the Worker, then through a Cloudflare Queue to a new BigQuery table (tasks C9 and C10 in `v1-task-breakdown.md`). `frappe_tap` is not involved (R-78). You do not need to build anything for it.

## 3. Good ideas, but not for v1 (please keep them for later)

- **Ask TAP with an AI chat** (Durable Object, LLM, BigQuery). v1 has prepopulated questions only (R-70).
- **Events** (`Event Campaign`, `Student Event Enrollment`, `events.json`). These are for v1.1 (R-86). For v1 we only **leave room** for them (R-94). The banner may also target a batch, a school, a state or a random group, and show information messages. Your event scope does not cover those.
- **The Gallery list by school, district and state.** When there is little work, your plan widens the search step by step (school, then district, then state). For v1 the Gallery shows any valid work in random order. Choosing whose work is shown is a later setting (R-85).
- **The ops dashboard, the Redis points queue, rate limits at several layers, nightly analytics and the load-test suite.** For a test with under 100 kids this is too much. The Worker already has rate limits.
- **BigQuery.** Your current plan uses it only for Ask TAP. We also need **every interaction of the student with the app** in BigQuery (P1, tasks C9 and C10). **The Worker does this, not the backend**, so `frappe_tap` carries no extra load. The notes below are for information.
  - **What is an event?** One row for each thing a student does in the app: a login with the link, a screen opened, a step finished (video marked as watched, each quiz answer, work sent), the feedback opened, an error shown. The section "Events to log" in `whatsapp-link-login.md` has a first list.
  - **Why?** Glific already sends the WhatsApp events to BigQuery. The product team wants the app's events in the same place and **in the same format**, so one analysis can cover both WhatsApp and the app (O-18).
  - **A duplicate row is possible.** BigQuery's own duplicate check works only for a short time. If a retry comes much later, there can be a second row for the same event. Use the event's unique id as the row id, and keep that id in every row. The analysis then removes duplicates later (keep one row for each event id).
  - **Not real time.** The events can be sent in batches, for example every few minutes or once a day. A failed send must be tried again later.
  - **The format is not known yet.** Manu will give us the format of the WhatsApp events (A15 in the task breakdown). Do not design the table before you see it.
  - **The flow (decided on 2026-11-05):** the app sends its events to the Worker, the Worker puts them in a Cloudflare Queue, and a consumer writes them to BigQuery in batches. The backend is not in the path.
  - **Privacy:** use the student id. Never use the phone number or the name.
  - **Access:** the Worker needs a Google Cloud service account key for BigQuery (A19). The `BigQuery Settings` doctype in `frappe_tap` is not used for this.
- **Outreach stages** (`no_response`, `reengagement_exhausted`, `delivery_failure`) and their nudge jobs. They need Glific messages that v1 does not have.

## 4. Please fix inside the document

- In section 4 of your plan the uploads go to **Google Cloud (GCP)**, but in the API list they go to a **private R2 bucket** (Cloudflare). The consumer is called both a "GCP event" consumer and an "R2 event" consumer. Pick one.
- **Names differ in places:** Student Event Enrollment statuses (active, completed, missed, versus enrolled, active, completed, missed); the Program Enrollment field is called `points` in one place and `weekly_points` and `total_points` in another; the folder is `tap_app`, `tapapp` and `app_submission`.
- The dashboard's **stage funnel** uses values (`video_watched`, `binge_limit`) that are not in the Program Enrollment stage list.
- **`skills_json` and a "skill-weight map"** are still mentioned, but the field was removed.
- The plan says the **Worker lives in the frappe repo.** Our Worker is in the Flutter repo (`flutter_native_webapp/worker`).

## 5. About the last note in the plan

The note says progress is stored on the Glific side and not in our LMS, so a student could not continue from WhatsApp in the app.

What we know: `frappe_tap` does **not** store the video steps, quiz answers or points of the WhatsApp flow (from the code on `journey_2026`). The WhatsApp flow keeps points, streak and gems in **Glific contact fields** (fields on the student's Glific contact that the flow can read and change: `total_points`, `activity_points`, `streak`, `special_gems`), as the lead's flow export shows. Our backend and the app cannot read them.

So the worry is right, and it is **decided**: in v1 the app does **not** sync with Glific. The kids' WhatsApp curriculum and the app curriculum are separate. The app keeps its own progress in `ProgramEnrollment` (R-48).

## 6. What we agree with

A magic link by phone with no OTP, a profile list and a phone token for siblings, each step saved at once, no answer key in the content files, content served as static files from R2, and the Gallery served from R2.

## 7. Next step

Please make a **smaller v1 version** of the plan that follows the requirements, and put the rest in a "later" section. The v1 version should cover: login, progress and quiz, the existing `submit_artwork` and feedback, and the Gallery copy (P2). Please send the updated plan for review before you start building.

Answered (2026-11-05): Unit Progress is needed in v1, as a child table (row 11).
