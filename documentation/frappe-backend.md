# Frappe Backend

The Frappe backend is not stored in this repository. This page summarizes the attached backend specification and records the contract required by the current Worker.

## Main modules

| Module            | Responsibility                                                      |
| ----------------- | ------------------------------------------------------------------- |
| `tapapp_auth.py`  | Phone/password auth, OTP/reset tokens, profile listing              |
| `profile.py`      | Profile ownership, selection, avatar and editable fields            |
| `learner.py`      | Full learner state, enrollment, XP, streak, weekly window, progress |
| `achievements.py` | Read and award learner achievements                                 |
| `jobs/`           | XP bucket rotation, weekly rollover, analytics reporting            |

## Learner state sections

`learner_full_state(learner_id, fields)` can return selected sections to reduce response size.

| Section        | Important fields                                         |
| -------------- | -------------------------------------------------------- |
| `profile`      | Name, language, district, state, school, birthdate       |
| `xp`           | Total XP, weekly XP, seven daily buckets                 |
| `level`        | Current level                                            |
| `streak`       | Current/longest streak and last activity date            |
| `window`       | Weekly completed count, cap, remaining count, reset date |
| `archetype`    | Dormant, fence sitter, irregular submitter, submitter    |
| `submission`   | Lifetime submission gems and index                       |
| `enrollment`   | Active course and course progress indexes                |
| `achievements` | Achievement name and level rows                          |

## Core DocTypes

| DocType                     | Purpose                                          |
| --------------------------- | ------------------------------------------------ |
| Tapapp Auth                 | Account keyed by phone                           |
| Tapapp Auth Profile         | Child profile linked to a learner                |
| Tapapp Learner              | Profile, XP, streak, submissions, weekly limit   |
| Tapapp Enroll               | Active course and video/quiz/submission progress |
| Tapapp Learner Achievements | Achievement rows                                 |
| Tapapp Content              | Event/project/knowledge-centre content           |
| Tapapp Tasks                | Background job status and retry control          |
| Secrets                     | JWT and analytics integration secrets            |

## Backend rules

- Weekly windows last seven days and default to two activities.
- Progress recording must reject a third activity in the active window.
- Archetype is recomputed from last activity date, lifetime submissions, and streak.
- Verified submissions must be sequential and idempotent.
- Course progress indexes must be monotonic and never decrease.
- Profile writes must verify learner ownership and reject school changes.
- Access tokens last 90 days and may be refreshed during protected requests.

## Scheduled jobs

| Job                    | Expected behavior                                     |
| ---------------------- | ----------------------------------------------------- |
| XP Window Rotate       | Shift `xp_d0..xp_d6` and recompute weekly XP          |
| Weekly Window Rollover | Reset weekly count and preserve/break streak          |
| Analytics Report       | Send daily learner/archetype/level/submission metrics |

Jobs use Redis locks, dynamic batch sizes, status tracking, and a `finally` lock release. Keep those properties when changing job code.

## Contract gaps to verify

The current Worker maps methods that are not described in the attached backend snapshot:

| Worker path                | Required Frappe method                                                                          |
| -------------------------- | ----------------------------------------------------------------------------------------------- |
| `/learner/submit-progress` | `tap_lms.tapapp.api.progress.learner.submit_progress`                                           |
| `/onboarding/complete`     | `tap_lms.tapapp.api.profile.onboarding.complete_onboarding`                                     |
| `/students/*`              | `search_student`, `get_bulk_students`, `update_student`, `bulk_update_students` in `profile.py` |

The attached learner document instead lists `record_activity`, `update_content_progress`, and `submission_verified_webhook`. Before release, confirm deployed Frappe contains `submit_progress` with the combined unit payload and response expected by Flutter.

The Worker and Frappe must use the same JWT signing secret; otherwise login may succeed at one layer while protected requests fail at the other.
