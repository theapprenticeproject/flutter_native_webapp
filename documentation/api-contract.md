# API contract: app to Worker (follows the backend developer's API Reference)

**Status:** rewritten on 2026-11-13. It replaces our own draft v0.
**Source:** the backend developer's `TapApp API Reference` (v6, saved as v8) and the Test/Dummy Worker document. They are the final word on the shape of each call. This file does not copy every field. It says **which calls the app makes in v1, how it uses the answers, and where we differ**, so the requirements (`v1-requirements.md`) stay true.
**Rule:** the app shows what comes in the response. It does not work out points, levels or validity on the phone (decided on 2026-11-11).
**Related:** `v1-task-breakdown.md` (tasks C and D), `v1-requirements.md`, `content-spec.md` (the ids), `handoff-backend.md`.

## 1. Rules for every call

| Rule | What it means |
|---|---|
| Who is called | The app calls only the Worker, never Frappe. `POST https://<worker>/<route>`. JSON body, JSON answer. |
| Credential | `Authorization: Bearer <token>`. Most calls take the **student token**. `/auth/select_profile` takes the **phone token**. `/auth/redeem` takes no header: the login code is the credential. |
| Who the student is | Only the student token says so. The app never sends `student_id` or a phone number in a body (R-81). |
| Answer shape | Success: `{"ok": true, "data": {...}}`. Failure: `{"ok": false, "error": {"code": "...", "message": "..."}}`. The app shows a friendly text for each `code` and never shows `message`. |
| Tokens | Fixed life, never refreshed. The student token lasts 30 days, the phone token 90 days. When the student token is gone or expired, the app calls `/auth/select_profile` with the phone token. If that fails too, the child opens a new WhatsApp link. |
| Safe repeats | Every call that writes takes an `idempotency_key`. The same key sent twice does the work once and returns the first answer with `"repeat": true`. A repeat is not an error. The app makes one key for each action and keeps it until it gets an answer. |
| `context` | The app does **not** send it. It defaults to `program`. `event` is not in v1. |
| Times | ISO 8601 with a time zone. `updated_at` is a Unix time in seconds. |
| Secrets | No key, token or phone number in a log or a screen. |

### Error codes and what the app shows

| Code | When | The app shows |
|---|---|---|
| `UNAUTHORIZED` | Token missing, wrong or expired. Login code wrong or old. | Try `/auth/select_profile`. If that fails: "Open your WhatsApp link again". |
| `STUDENT_NOT_FOUND` | No student, or no active enrollment. | A friendly error. |
| `INVALID_INPUT` | A field is missing or wrong. | A friendly error, and a bug report to us. |
| `NOT_FOUND` | The unit, video, quiz or submission does not exist for this student. | A friendly error. |
| `NOT_READY` | Feedback is not ready. | The waiting screen. |
| `UPSTREAM_ERROR` | A call inside the backend failed. Safe to retry with the same key. | Retry button. |
| `RATE_LIMITED` | Too many calls. | Wait, then retry. |
| `CONFLICT` | A cap in the backend (see the rules in section 5). | See section 5. |
| `SERVER_ERROR` | Anything else. | Retry button. |

On `submit_artwork` the error can also be one of `upload_not_confirmed`, `upload_size_invalid` and `upload_type_mismatch`. The app shows "Please try again" and sends the photo again.

## 2. The calls the app makes in v1

| Route | In | Out (the fields the app uses) | Used for |
|---|---|---|---|
| `POST /auth/redeem` | `code` (from the WhatsApp link) | `phone_token`, `active_student_id`, `students[]`. Each student has `student_id`, `token`, `name`, `grade`, `points`, `points_tier`, `gems`, `current_learning_unit`, `last_activity_type`, `course_id`, `language`, `updated_at` (plus place names and ids). | Login. One answer for any number of children. Each child comes with their own token. The app picks the child (the name picker when there are two or more), and changes child by taking another cached token. |
| `POST /auth/select_profile` | `student_id`, phone token | The same fields for one student, with a new token. | Only when a cached student token is gone. |
| `POST /progress/submit_video_watched` | `unit_id`, `video_id`, `watched`, `idempotency_key` | `points_awarded`, `points_total`, `points_tier`, `repeat`, `updated_at` | Watch step. |
| `POST /progress/submit_quiz` | `unit_id`, `quiz_id`, `answers: [{question_id, selected_key}]`, `idempotency_key` | `correct_count`, `total_count`, `points_awarded`, `points_total`, `repeat`, `updated_at` | Quiz step. |
| `POST /submission/request_upload` | `assignment_id`, `submission_type` (`image` or `video`) | `upload_url`, `object_key`, `content_type`, `upload_headers`, `expires_in`, `max_size_bytes`, `attempt_number`, `attempts_remaining` | Make step: the link to upload the file to. |
| `POST /submission/submit_artwork` | `assignment_id`, `object_key`, `idempotency_key` | `submission_id`, `status` (`Pending`), `attempt_number`, `attempts_remaining`, `points_awarded`, `points_total` | Make step: tells the backend that the file is uploaded. |
| `POST /submission/list` | none | `submissions[]`: `submission_id`, `assignment_id_link`, `status`, `result_status`, `view_url`, `score`, `overall_feedback_translated`, `overall_feedback_audio_url`, `attempt_number`, `attempts_remaining` | My projects. Also the way to see a **pending** work after a reload. |
| `POST /submission/get` | `submission_id` | The same fields for one row. | Results step, and the "feedback is ready" link. |
| `POST /progress/sync` | `last_updated` (the last `updated_at`) | `changed: false`, or `changed: true` with `points`, `points_tier`, `gems`, `current_learning_unit`, `last_activity_type`, and `last_submission` when a graded one is new. | Catch up after a reopen, and the home points. `last_submission` is absent while the work is `Pending` or `Processing`. |
| `GET /app/config` | none | `point_tiers` (id and minimum points), upload limits, `point_tiers_version`. | The level name and its limits. The tier table is not hardcoded. |
| `GET /gallery` | optional `assignment_id`, `grade`, `cursor` | `images[]`: `display_name`, `url`, `media_type`, `score`. `cursor`. | Gallery (R-88). |

Calls we do **not** make in v1:
- `/submission/do_later`: it writes nothing. Postponing Make is only on the phone (R-66).
- `/progress/last_submission`: `sync` is enough.
- `/profile/get_profile`: the login answer has what we need. Edit profile is later (R-74).
- `/events/*`: not in v1.
- `/tapbuddy/chat`: R-70 says v1 has prepopulated questions only.
- `/telemetry/flush` and `_t`: the backend developer designs the backend side. The app still collects the events of R-84, and sends them to the Worker route of tasks C9 and C10 (section 6).

## 3. The activity as calls (R-61)

| Step | What the app does | Call |
|---|---|---|
| Open | Show the unit named in `current_learning_unit`. | none (it comes from login or `sync`) |
| Watch | The student taps "I watched it". The app marks the video. | `submit_video_watched` (+10) |
| Make | The student takes a photo. | `request_upload`, then the upload to `upload_url`, then `submit_artwork` (+25 for attempt 1) |
| Quiz | The student answers on the phone. At the end the app sends the answers once. | `submit_quiz` (+1 for each correct answer) |
| Results | The app waits for the feedback, then shows it. | `submission.list` or `get` until `result_status` is not `Pending` |

If the student postpones Make, the app goes to the Quiz and asks again later. No call is made for the postponing.

## 4. Valid or not valid (R-76, R-83, R-92)

`result_status` is one of four values. The app treats a work as **valid only when it is `Success - Original` and `score` is not 0**. Any other value, also a new one the app does not know, is **not valid**.

| `result_status` | Meaning | The app shows |
|---|---|---|
| `Pending` | No feedback yet. | "I'm looking at your work, please wait" (R-68). |
| `Success - Original` | Valid. | Feedback and Results. The next unit can open. |
| `Success - Flagged` | Not valid (decided on 2026-11-11). | Feedback and "Send again". The next unit stays closed. |
| `Failed` | Not valid. | Feedback and "Send again". The next unit stays closed. |

The score 0 rule keeps R-92 case 1: when the AI evaluation fails, the pipeline publishes the result as original with grade 0 and the text "technical issue". That is not valid.

"Send again" is a new `request_upload` and a new `submit_artwork` with a new key. The cap is 2 attempts for each assignment. After two not-valid results the child cannot go on (decided: the cap stays).

## 5. Points and caps (R-75, R-91)

The backend gives every point. The app shows `points_awarded` and `points_total` from the answers.

| What | Points | Where it shows up |
|---|---|---|
| Video watched | +10 | `submit_video_watched` answer |
| Work sent, attempt 1 | +25 | `submit_artwork` answer. Attempt 2 gives 0, so the +25 is given once for each unit (R-75). |
| Quiz | +1 for each correct answer | `submit_quiz` answer |
| Valid feedback | +10 (and +1 gem) | Later, as a higher `points_total` in `sync`. Not in `submit_artwork`. Not given for `Success - Flagged`. |

Until the +10 arrives, the project shows "Points will be provided after feedback" (R-75). The app does not guess the number.

`CONFLICT` means:

| Call | The app does |
|---|---|
| `submit_quiz` | The quiz was already scored. **The app sends only the first scored attempt** (decided on 2026-11-13). A retake is graded on the phone only and is never sent. If the server answers `CONFLICT`, the app treats the quiz as scored. |
| `submit_video_watched` | The video was already marked (too many events). The app goes on. |
| `request_upload`, `submit_artwork` | The cap of 2 attempts is reached. The app shows that the child cannot send again (R-76). |

Gems are not in the v1 design. The app does not show them and does not ask for them. If the backend makes "send again" cost a gem, a child with no gem is stuck. The backend developer is asked to remove the gem cost.

## 6. Interaction events (R-84): not a call to the backend

The app collects events (screens, taps, step changes, quiz answers, typed text). It sends them to a Worker route, and the Worker puts them in a Cloudflare Queue for BigQuery (tasks C9 and C10). `frappe_tap` is not involved (R-78). The `_t` batch of her API and her `/telemetry/flush` are her own design, and are not what R-84 needs (they have no step events, no quiz answers, no typed text and no event id). We keep our own events pipeline until we agree on one.

The event shape (R-84):
`event_id` (made by the app), `type`, `at`, `screen` (optional), `data` (a small object). The phone keeps each event until the Worker confirms it is in the queue. No phone number and no name field. Text typed by the student is allowed (privacy rule A20 is open).

## 7. Reload and resume

`sync` and the login answer give only `current_learning_unit` and `last_activity_type` (`video`, `quiz`, `submission` or `null`). They do not list the state of each step. After a reload the app works out the state of the unit like this:

| What the app sees | The state |
|---|---|
| `last_activity_type` is `null` | Nothing done in this unit. |
| `video` | Video done. Show Make. |
| `submission` or `quiz` | The video is done. Call `submission.list`: a row for this unit's assignment means the work was sent (look at its `result_status`). No row (and `quiz`): Make was postponed. |
| `current_learning_unit` is `null` | Nothing is assigned, or every unit is done. Show the "all done" state. |

`current_learning_unit` moves on when the backend counts the unit as complete. R-83 says only after valid feedback. This is a question for the backend developer (section 9).

## 8. The ids and the quiz

The bundled content carries the ids (`content-spec.md`, section 10). Until the real ids are known, they are dummy ids (task B19).

| File key | API field |
|---|---|
| `uid` | `unit_id` |
| `vid` | `video_id` (v1: one video for each unit) |
| `zid` | `quiz_id` (the unit quiz) |
| `qid` | `question_id` |
| `aid` | `assignment_id` |

- The answer key in the file is "1", "2" or "3". The app sends it as `a`, `b` or `c` (`selected_key`).
- The app has the correct answers in the bundled content, so it gives right or wrong at once, also without a network. The server grades again, and its result is the one that counts (R-91). The backend must hold the same key. A test in B19 checks this.
- The practice quizzes inside a video are not sent to the server.

## 9. Open questions for the backend developer

| # | Question | Status |
|---|---|---|
| 1 | Is `Success - Flagged` valid for the next unit? Her table says it counts toward unit completion. We say it is not valid. | Asked on 2026-11-13 |
| 2 | Remove the gem cost for "send again" (attempt 2). | Asked |
| 3 | Confirm how `current_learning_unit` moves on. We read it so: a unit is `Completed` when the video is marked, the quiz is scored and the work has a graded result, and the next unit is the first one that is not `Completed` (Reference v6, lines 31, 100 to 105, 112 and 113). Only `Success - Original` should count (R-83), see question 1. | To confirm |
| 4 | Add `points_awarded` to each `submission.list` row, so Results can show the activity points. | To ask |
| 5 | JPEG: `request_upload` has no field to ask for a file type. How does the app say "JPEG"? (Her text now says other image formats are accepted.) | To ask |
| 6 | ~~Does `status` stay `Pending` until the feedback windows?~~ Not a front-end issue (decided on 2026-11-13). The app shows the waiting screen while the result is `Pending`. | Closed |
| 7 | The quiz: confirm that a second `submit_quiz` returns `CONFLICT` and that a repeat with the same key returns `repeat: true`. | To ask |
| 8 | Which folder holds your new methods: `tapapp` (the new folder for this app, R-46) or the existing `tap_app`? Your reference names `tap_lms/tap_app/api` (v6, line 5). And who builds the production Worker? | To ask |
| 9 | `/app/config` is only a line in the route table of the Reference (v6, line 846). The Dummy API document shows its shape (tiers bronze, silver, gold, platinum). Please add a section to the Reference, and confirm that production returns the same. | To ask |

## 10. What changed from our first draft (v0)

- The names are hers: `/auth/redeem`, `submit_video_watched`, `submit_quiz`, `request_upload`, `submit_artwork`, `submission.list` and `get`, `sync`. Our `link_login`, `select_student`, `get_progress`, `save_step`, `quiz_start`, `quiz_submit`, `create_submission`, `get_feedback` and `get_projects` are gone.
- The quiz has no start call. The questions and the key come from the bundled content, and the app sends one batch at the end.
- The valid flag comes from `result_status`. There is no separate `valid` field.
- Our Worker to Frappe calls (`mark_app_student`, `make_feedback_link`, `update_profile`) are not in her API. `mark_app_student` and `make_feedback_link` are still needed for O-28 (task B14). Ask her where they go.
- Login is one call, `/auth/redeem`. It replaces our two-step `link_login` and `select_student`. `whatsapp-link-login.md` describes the Frappe side and still holds.

## 11. How we keep this file true

- The Test/Dummy Worker is already deployed. It has seed phones for a clean start, one flagged result, a capped student, siblings, and a reset call. The app is built and tested against it. Its points and caps are test values: do not copy them.
- If her answers differ from her reference, her reference or her code is wrong. Fix one of them the same day. If it differs from this file, change this file.
- When a call changes, change her reference first, then this file, then the code.
