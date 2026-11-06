# API contract: Worker to backend (draft v0)

**Status:** first draft, written on 2026-11-04. The names and fields are **proposals**. The frontend and the backend developer agree on them together, before B5 starts. After that, **change this file first, then the code.**
**Who uses it:** the backend developer builds the Frappe methods in `tapapp`. The Flutter app talks only to the Worker, never to Frappe.
**Related:** `v1-task-breakdown.md` (tasks B and C), `v1-requirements.md` (R-numbers), `handoff-backend.md`.

## 1. The rules for every call

| Rule | What it means |
|---|---|
| Transport | `POST /api/method/tap_lms.tapapp.api.<method>`. JSON body. JSON answer. |
| Credential | The Worker sends `Authorization: token <key>:<secret>` on every call. A call with no credential, or a wrong one, is refused. No method is open to guests. |
| Who is the student | Every call about a student takes `student_id`. The Worker takes it from the student token. The backend uses only this `student_id`. It never uses a phone number, and it never reads a `student_id` from anywhere else (R-81). |
| Answer shape | Success: `{"ok": true, "data": {...}}`. Failure: `{"ok": false, "error": {"code": "...", "message": "..."}}`. Frappe puts this inside its own `message` field. Do not raise exceptions for expected failures. |
| Safe repeats | Calls that write must be safe to repeat. The same call sent twice does the work **once** and returns the **same answer** as the first time, with `"repeat": true`. It is not an error. Where the key is kept: **`create_submission`** takes an `idempotency_key`, stored in the `upload_key` field of the Unit Progress row. **`quiz_submit`** uses the `attempt_id` from `quiz_start`, stored in `quiz_json` of the row. **`save_step`** needs no key: the time field of the step in the row says it is done. |
| Time | All times are ISO 8601 with a time zone, for example `2026-11-04T16:00:00+05:30`. |
| Secrets | Never put a key, a token or a phone number in an answer or a log. |

### Error codes

| Code | When | Worker shows |
|---|---|---|
| `UNAUTHORIZED` | The credential is missing or wrong. | A friendly error. |
| `STUDENT_NOT_FOUND` | The `student_id` does not exist or has no active enrollment. | A friendly error. |
| `INVALID_INPUT` | A field is missing, has the wrong type or is too big. `message` names the field. | A friendly error. |
| `NOT_FOUND` | The unit, the attempt or the submission does not exist **for this student**. | A friendly error. |
| `NOT_READY` | The feedback is not ready yet. This is normal, not a failure. | The waiting screen. |
| `UPSTREAM_ERROR` | A call inside the backend failed (`submit_artwork`, Glific). Safe to retry with the same key. | Retry button. |
| `NOT_SAVED` | The Worker could not put the interaction events in its queue (section 3.7). The app keeps them and sends them again. | Nothing (silent). |
| `SERVER_ERROR` | Anything else. | Retry button. |

The messages are for developers and logs. The Worker maps each code to a friendly text and never sends `message` to the app.

## 2. Points rules (R-75)

The backend is the only place that gives points. It answers with the points for the call and the new total.

| Event | Points | When |
|---|---|---|
| Video marked as watched | +10 | At once. |
| Work sent (shared) | +25 | At once, when the submission is accepted. |
| Quiz: each correct answer | +1 | When the server checks the answers. |
| Valid feedback | +10 | Once for each submission, when the backend sees valid feedback. Grade 0, or the text "technical issue", is **not valid** (R-92). A repeated or retried read of the feedback must never give it twice. |

## 3. Calls

### 3.1 Login

**`link_login(phone)`**
- In: `phone` (text).
- Out: `data.students`: a list of `{student_id, name}` for the phone.
- Notes: the phone is checked here and only here. No data about a student is returned except the id and the name.

**`select_student(phone, student_id)`**
- In: `phone`, `student_id`.
- Out: `data: {student_id, first_name, language}`.
- Errors: `STUDENT_NOT_FOUND` if the student does not belong to the phone or has no enrollment in an active batch.
- Notes: after this call the Worker uses only `student_id`.

### 3.2 Progress and home

**`get_progress(student_id, if_modified_since)`**
- In: `if_modified_since` is optional. It is the `last_modified` value from the last answer.
- Out when nothing changed: `data: {changed: false, last_modified}`. This keeps the load on the server low (R-78).
- Out when something changed:
  ```
  data: {
    changed: true, last_modified,
    points_total, points_activity,
    completed_units: [unit_id],          // units with valid feedback (R-83)
    steps: [{unit_id, step_type, status, points, at}],
    open_submission: {submission_id, unit_id, status} | null
  }
  ```
- Notes: the content of the units (video, texts) is in the app in v1. The backend sends only the progress. The next activity opens only after valid feedback for the one before (R-83). A reload must show the same state (R-40).

### 3.3 Steps

**`save_step(student_id, unit_id, step_type, client_time)`**
- `step_type` in v1: `video_watched`. (The quiz and the submission have their own calls below.)
- Out: `data: {points_awarded, points_total, repeat}`.
- Notes: a repeat returns the first answer with `points_awarded` of the first call. **There are no watch seconds.** The app does not check that the video was watched (R-90), so it sends and stores no watch time.

### 3.4 Quiz (R-91)

**`quiz_start(student_id, unit_id)`**
- Out:
  ```
  data: {
    attempt_id,
    questions: [{question_id, text,
                 options: [{key, text}],
                 correct_key}]           // the correct answer goes to the phone on purpose
  }
  ```
- Notes: all questions come together. The answer key must **not** be in the CDN files. A retake is a new attempt. The app gives right or wrong at once, also without a network.

**`quiz_submit(student_id, attempt_id, answers)`**
- In: `answers`: a list of `{question_id, selected_key, answered_at}`. The app sends **no score**.
- Out:
  ```
  data: {
    attempt_id,
    results: [{question_id, correct, correct_key}],
    correct_count, points_awarded, points_total, repeat
  }
  ```
- Notes: the server **stores every answer first**, then checks them again with its own key and answers **at once** (no queue, no Redis cache in v1; it reads the key from Frappe each time). The server checks every answer again and stores every answer. Any score sent by the app is ignored. The server's result is the one that counts. The points, the picture badge (R-69) and the Results step use this answer, not the local one.

### 3.5 Submission (R-64, R-92)

The Worker makes the short upload link (task C5). The app uploads the file straight to storage. Then the Worker calls:

**`create_submission(student_id, unit_id, assignment_id, media_type, file_ref, idempotency_key)`**
- `media_type`: `image` or `video`. `file_ref`: the storage path of the uploaded file (never a public link). **Allowed file types:** `image/webp` (the usual photo, R-12), `image/jpeg` (the fallback when the phone cannot make WebP), and `video/mp4`. HEIC is never accepted. Other video types are to be checked with the pipeline (B0, E2). Any other type gives `INVALID_INPUT`.
- Out: `data: {submission_id, points_awarded, points_total, repeat}`.
- Errors: `UPSTREAM_ERROR` if `submit_artwork` fails. Safe to retry with the same key.
- Notes: one upload makes one `submit_artwork` call. A new attempt after a not-valid result has a new key and makes a new `Submission`. The call also sets `submission_context` = `program` and `sources` = `tapapp` on the new `Submission` (two new fields, added as Custom Fields by a `tapapp` patch and set after `submit_artwork` returns), and it stores the key in `upload_key` and the link to the new `Submission` in the Unit Progress row, and `feedback_flow_id` for app students (task B14, O-28 approved on 2026-11-05).

### 3.6 Feedback and projects

**`get_feedback(student_id, submission_id)`**
- Out:
  ```
  data: {
    status: "waiting" | "ready",
    valid: true | false | null,          // null while waiting
    messages: [{text, text_translated, audio_url}],
    points_awarded, points_total
  }
  ```
- Errors: `NOT_READY` is allowed instead of `status: "waiting"`. Pick one way and keep it (open question 1).
- Notes: feedback comes in the daily windows (15:00, 16:30, 21:00 IST). This call only **reports** the points. It must not be the only place that gives the `+10`. The `+10` is given once for each submission, with a guard in the database, so a repeated read never gives it twice. Task B7 decides if a hook, a job or the first read gives it. `audio_url` is a link the Worker can turn into a short-lived one.

**`get_projects(student_id)`**
- Out: `data.projects`: a list of `{submission_id, unit_id, title, status, valid, submitted_at, media_ref}`, newest first. The backend reads the list through the Unit Progress rows (which link to the `Submission`), so event and challenge submissions are not shown. `media_ref` is a storage path. The Worker makes the short-lived link (R-88).

### 3.7 Interaction events (R-84): a Worker route, **not a Frappe call**

Decided on 2026-11-05: the events do not go to `frappe_tap` (R-78). The app sends a batch to a Worker route. The Worker checks it and puts it in a Cloudflare Queue. A consumer writes the events to BigQuery (tasks C9 and C10). This section is here only so everyone knows the event shape.

**Batch from the app** (the student token gives the `student_id`; a `student_id` in the body is ignored):
- A list of at most 100 events:
  ```
  {event_id,            // unique, made by the app
   type,                // for example "screen_opened", "screen_closed", "tap", "step_done", "quiz_answer", "chat_message", "error"
   at,                  // when it happened on the phone
   screen,              // optional
   data}                // a small object: ids, any text the student typed, the tap position (x, y) for "tap", the time open in milliseconds for "screen_closed"
  ```
- Answer: `{accepted: [event_id], rejected: [{event_id, code}]}`. `NOT_SAVED` if the queue did not take the batch.
- Notes:
  - The phone keeps each event until the Worker confirms that it is in the queue, and sends it again after a `NOT_SAVED` answer.
  - The `event_id` is the row id in BigQuery. A repeated batch makes no second row. Every row keeps `event_id`, because BigQuery's own duplicate check works only for a short time.
  - Events carry `student_id`. Never the phone number. Never a name field. Text typed by the student is allowed and is stored as typed.
  - The final table format comes from the WhatsApp events (A15). Until then, use this shape.

### 3.8 Feedback link for app students (task B14, O-28 approved on 2026-11-05)

| Call | Who calls | What |
|---|---|---|
| `mark_app_student(student_id)` | Worker, at the first login | Records that this student uses the app. |
| `make_feedback_link(submission_id)` | Glific, through a webhook | Returns a signed link that opens the Results step of that submission. Uses the shared secret (A16). The Worker checks the link (task C7). |

### 3.9 Profile edit (task B17, later)

**`update_profile(student_id, fields)`**: first name, last name, language, the brother or sister question (R-74). Writes to `Student` are approved (A2). It is **later**: not built in v1 (R-74).

## 4. Not in this contract

- **Content** (units, videos, messages, audio) is served from the CDN, or bundled in the app for the first test. The backend does not serve it.
- **Gallery** and **banners** come from R2 and from the Worker. No Frappe call in v1 (banners return an empty list).
- **Upload links** are made by the Worker (task C5).

## 5. Open questions

1. **Waiting feedback:** does `get_feedback` return `status: "waiting"` or the error `NOT_READY`? Suggestion: `status: "waiting"`, and keep `NOT_READY` unused.
2. **"I watched it" after 5 minutes (R-90):** does the server check the 5 minutes in `save_step`, or does the app only turn the button on? Suggestion: the app only. Check on the server later.
3. **Where the quiz questions and the answer key come from** (task B0): Frappe or the Google Sheet. The shape of `quiz_start` does not change.
4. **`unit_id` and `assignment_id`:** are they the same value for each activity? Check with the content (B0).
5. **The format of the events** in BigQuery (A15) and which service account key the Worker uses (A19).
6. **Steps storage:** decided on 2026-11-05. The steps are stored in the Unit Progress child table of Program Enrollment, one row for each unit. This contract does not depend on it.
7. **Quiz retakes and points:** a retake is a new attempt (R-91), and the Unit Progress row keeps one set of quiz points. **Decided on 2026-11-05:** the first scored attempt gives the +1 points and a retake gives none.

## 6. How we keep this file true

- Every call has a test in the Worker that uses a fake Frappe which answers exactly as written here.
- If an answer differs, the file or the code is wrong. Fix one of them the same day.
- When a call changes, the backend developer changes this file first and informs others.
