# TapApp v1: requirements for review

**Purpose.** This page lists what we plan to build for version 1 (v1) of the TapApp student web app. We want to agree on it with the product team before we build.

**Status of this page.** Draft for review. Nothing here is final until the product team confirms it.

**The backend branch (confirmed 2026-11-04).** The deployed branch of `frappe_tap` is `journey_2026`. Flows and code on other branches do not count. The rows that follow the backend are R-27, R-38 to R-40, R-48, R-75, R-76, R-80, R-82, R-87, R-89, R-91, R-92 and O-28. See [system-understanding.md](system-understanding.md).

**Codes used in these documents**

| Code | Meaning | Defined in |
|---|---|---|
| R-n | A requirement | `v1-requirements.md` |
| O-n | An open decision for the product/tech team | `v1-requirements.md`, section 11 |
| F-n | A Figma frame to correct | `v1-requirements.md` |
| A1 to A17 | Approved login decisions | `whatsapp-link-login.md` |
| Q1 to Q11 | Open questions about the login | `whatsapp-link-login.md` |
| LS1 to LS6 | Login settings, with proposed values | `whatsapp-link-login.md` |
| AP1 to AP9 | App fixes | `production-readiness.md` |
| B1 to B8 | Backend fixes | `production-readiness.md` |
| PL-1 to PL-13 | Findings in the existing pipeline | `production-readiness.md`, section 8 |
| S1 to S13 | Security issues | `known-gaps.md` |
| GP1 to GP12 | Product and design gaps | `known-gaps.md` |
| P1 to P3 | Priorities, high to low (not the product gaps) | `todo.md`, `production-readiness.md` |

## How to read this page

Each item has a status:

- **Decided**: already agreed. Tell us if it is wrong.
- **Proposed**: our suggestion. Please confirm or change it.
- **Open**: we need a decision from the product team. These are collected in [section 11](#11-open-decisions).

A row that starts with **Tech:** is a technical item for the tech team. It needs no business input or sign-off. The product team can skip it. (R-47 also mentions changes that need approval. Those are in "Rules for our changes".)

## 1. What we are building

TapApp is a web app for students. It opens inside the WhatsApp browser on Android phones. Students use it to:

- choose their profile,
- see their current activity,
- do the activity (watch, make, quiz, results),
- send a photo or a video of their work,
- see their points and progress, and
- see other students' work in a gallery.

The app today is a prototype. Version 1 must be ready for real students.

### The first release (decided on 2026-10-30)

Version 1 is a **test release in mid-November** for a very small group of kids (30 to 100: the number is not decided). The team works with them personally.

- The kids are **already registered in TAP** and know it. If a child is not registered, the tech team registers them before the test. There is **no onboarding in the app**.
- Each child gets a **magic link** (R-32). The kids keep their work in the WhatsApp flow. The app has its own curriculum and **does not sync** with Glific.
- The flow is **hardcoded and linear** (R-61), and it follows the Glific flow `Tlm26_MainFlow_FirstStep_v1` from the lead developer (see `system-understanding.md`, 5.8). The curriculum team provides the content.
- Feedback keeps going out in the three daily windows (R-68). We do not change that for v1.
- The test runs on the **dev server**, not on production (decided on 2026-11-04). The test kids, their Glific contacts and the content must exist on the dev server (see A18 in `v1-task-breakdown.md`).
- **Every interaction of the student with the app is saved** (R-84), so that we can study how the kids use the app.
- Later versions add the banner and events (v1.1, R-94), a stronger login, tiered rewards, deadlines and more (section 2).

## Principles from the product team

The product team gave us two rules. Every requirement below must fit them.

1. **Progress lives in TAP's own records, not on the surface.** A child can move from WhatsApp to the web app to an installed app and pick up exactly where they were.
2. **WhatsApp does not switch off.** It stays the way TAP reaches a child who has not moved, and the way TAP tells a child that something is waiting.

What this means for us:

- Progress cannot live only on the phone, and not only in a chat history. The prototype keeps some progress on the device. That must change (R-37, R-40, R-48).
- Glific may delete old messages after about two months (Glific's own wording, in its web channel proposal, section 7.1), so Glific's messages cannot be the record (R-30).
- The same child must be recognized on every channel (R-34, R-48).
- The app does not need its own push notifications in v1. WhatsApp tells the child that something is waiting, with a link into the app (R-49, R-50).
- The backend and the login must not be built only for the web app. An installed app will use them later.

## Rules for our changes

`frappe_tap` is in production. **We do not change its existing logic or behavior without the product team's approval.** Our freedom is limited to the `tapapp` module and the app (the prototype). The v1 test runs on the dev server, so these approvals are needed **before we deploy to production**, not before the test. The `tapapp` module lives only in `frappe_tap` (decided on 2026-11-04).

What this means:
- New backend work lives in `tapapp`. It may **read** `frappe_tap` data (for example `Student`, `ProgramEnrollment` and `Submission`). It changes production data only through existing `frappe_tap` calls that stay as they are, such as `submit_artwork`.
- We do not change existing `frappe_tap` calls, jobs or rules.

**Decided on 2026-11-05, after a review with the lead: all items in the table below are approved, except one.** The one that is **not** approved yet is making `submit_artwork` refuse calls that have no API key. New DocTypes in the `tapapp` module are fine too: the step table (or child table), the settings DocType (points, levels and the link secret), the "app student" flag table and, later, the event tables. The table lists what is approved and why each item touches `frappe_tap`:

| Item | Why it touches `frappe_tap` |
|---|---|
| Making `submit_artwork` refuse calls that have no API key (R-47, R-89) | **Not approved yet (2026-11-05).** The code does not check a key (`allow_guest`, `ignore_permissions`). The nginx setup we found has no key rule. A test on a **local** server (`save_submission` family) gave: a valid token works, a wrong token is rejected (401), and **no token works** with the same result as a valid one. So the code accepts calls without a key. We have not tested production or `submit_artwork`. Production may have a layer in front that we cannot see. Refusing calls without a key could break any Glific flow that does not send the key, so the product team must approve it, and the flows must be checked first. |
| The WhatsApp message that tells the student to open the feedback page (R-16, R-50, O-28) | **Approved (2026-11-05).** Reading and showing the feedback needs no change. The message is sent today by the existing feedback step, through one Glific flow (label "feedback") that all students share, including WhatsApp-only students. We recommend a **new Glific flow for app students** (Option B in O-28). `tapapp` sets the `feedback_flow_id` field of the `Submission` to that flow. This is a write to one existing field of a production table, and the shared flow for WhatsApp-only students is not changed. The new flow is built by the Glific team. |
| Any new write to `Student` (for example edit profile, R-74, which is later) or to `ProgramEnrollment` (our progress record, R-48) | **Approved (2026-11-05).** `Student` is in use by the live flows, so a write changes production data that WhatsApp also reads. `ProgramEnrollment` is no longer used by the live flow on `journey_2026`: the Summer Program engine that wrote it is switched off, so the table is empty and nothing else reads it. It is still a production table, and TapApp would be the only writer. |
| Putting `tapapp` into the `frappe_tap` branch (R-46) | **Approved (2026-11-05).** New code goes into the production app. |
| New indexes on `Submission`, `StudentContentLog` or `Student` (for the Gallery and "My projects") | **Approved (2026-11-05).** They change production tables. Today these tables have no index on `student_id`, `assign_id` or `week`. |
| **Two new fields on the `Submission` table:** `submission_context` (program, event or challenge) and `sources` (whatsapp or tapapp) | **Status: decided by the tech team on 2026-11-06. The lead's approval is still to be confirmed. Write the approval here when it comes: this is the only place that records it.** The fields are only labels. `submit_artwork` and the RabbitMQ message do not use them (the message is built from a fixed list of fields). `tapapp` sets them after `submit_artwork` returns. The default is `whatsapp`, and an empty value counts as `whatsapp`. `sources = tapapp` tells us to copy the work to R2 for the Gallery. They are added by a `tapapp` patch as Custom Fields, not by editing the `Submission` DocType file in `tap_lms`. "My projects" is read through the Unit Progress rows, which link to the `Submission`, so a failed label update never hides the student's own work. **A simpler option:** `Submission` already has a field `program_enrollment`, and the live WhatsApp path does not set it on `journey_2026`. If `tapapp` sets it, app work is known without any new field, and event and challenge context can come in v1.1. The tech lead decides. No other new field on `Submission` is planned. |
| The new **Unit Progress** table in `frappe_tap` (R-40, R-48) | **Approved (2026-11-05).** It is a child table of `ProgramEnrollment`, with one row for each unit, as the tech lead decided on 2026-11-05. The writes to the point fields that `ProgramEnrollment` already has are approved too. |
| The new event (campaign) table and the new `EventEnrollment` table in `frappe_tap` (R-86, v1.1) | **Approved (2026-11-05)**, as new DocTypes. They change none of the existing logic. |
| New WhatsApp messages and links. This covers: the login link, the "submission pending" nudge (R-66), the "feedback is ready" link (R-16), and links added to the existing reminder, escalation and content messages | **Approved (2026-11-05).** Each kind needs its own new WhatsApp template (see the table in `whatsapp-link-login.md`, "Glific"). The login message also needs a new Glific flow. They run on the same Glific account as the live WhatsApp program, and the feedback delivery job (`feedback_delivery`) in `frappe_tap` must send the links. WhatsApp must approve each template, and every template message costs money. |

The password and OTP calls (`check_phone`, `login_with_password`, `forgot_password_*`, `reset_password`) exist only in the `tapapp` prototype (`tapapp_auth.py`). They are not in production `frappe_tap`: no branch of `frappe_tap` has them. So we can remove them **without** the product team's approval. A similar file, `tap_lms/ca/api/auth/citizenship_auth.py`, is a different module and we do not change it.

Reading is fine without approval. For example, `tapapp` can read the feedback and the valid or not valid result from `Submission` itself, so we do not have to change `get_submission_feedback`.

### Recommendations to the product team (not needed for the app)

These are our suggestions. The app does not depend on them. They would reduce risk in the existing system, and each one is a change in production, so it needs approval.

- **Limit `update_batch_week` and `admin_drop_student` to an admin role, if they are still reachable.** They belong to the switched-off Summer Program code. Today any caller with a login or key can advance a batch's week or drop a student. Our Worker's key could call them too, so a leaked key would be more dangerous.
- **Require an API key on `submit_artwork`, `submission_feedback` and `get_assignment_context`.** The code does not check a key for them. Production may require one: see "Rules for our changes".
- **Turn on the watching of dead letter queues** that the system document describes (sections 16 and 17). We did not see it wired in `hooks.py`.

## How v1 relates to the TAP App roadmap

The TAP App's roadmap (`TAP_App_Roadmap_v3.xlsx`) is the **long-term vision**: three releases between January and July 2027, a web app **and** an Android app, and 500,000 children by July 2027 (1 million by March 2028). v1 is smaller. This table is our reading of how the roadmap maps to v1. Please correct it.

**Labels:** **In v1**: we build it now. **Later**: the roadmap plans it for a later release. **Not planned**: it is not on the roadmap, or it is outside this project.

| Roadmap area | In v1? | Notes |
|---|---|---|
| Student web screens from the Figma | In v1 | Sections 3 and 4 |
| Events and campaigns (the banner, "Join" and the number of students taking part) | Later | v1.1 (R-86). The v1 app leaves room for it (R-94). |
| Photo and video submissions | In v1 | Section 4. Voice recording is later (R-10). |
| Points, level and projects from the server | In v1 | Section 9 |
| Saving each step to the server at once | In v1 | R-40 |
| Keeping steps when the connection drops | Later | In v1, when the device is offline, the app stops (decided in the review, R-71). **One exception:** a quiz that has started can be finished offline, and the answers are sent later (R-91). Keeping other steps for later is part of offline use. |
| Full offline use (content on the phone) | Later | Roadmap Release 3, in the installed Android app |
| Voice both ways (read steps aloud, answer by voice) | In v1, in part | Fixed messages use pre-generated audio files, played when the student taps the speaker icon (R-17). Feedback audio is generated as today (R-56). Answering by voice is later. |
| Showcase (the Gallery tab): finished work from the class and school | In v1 | Any valid work (pictures and videos), in random order, with initials only (R-59, R-85). The curriculum team's examples fill it at first. |
| Login: teacher-created PIN accounts | Later | No teacher role in v1 |
| Child account with password and PIN, set up with parent consent (roadmap 1.1b) | Later | This is the installed-app and Play Store route. It is not a parent login. |
| Several profiles on one phone (like Netflix) | In v1 | The student picks a name and can switch profile. There is no PIN in v1, so children who share a phone can open each other's profile and see each other's work (R-34). The PIN comes in a later version. |
| Teacher role and screens (class setup, who has not finished, leaderboard) | Later | Decided: v1 uses the same student-only flow as WhatsApp |
| Android app (installed) | Later | v1 runs in the WhatsApp in-app browser (R-42). See R-42. |
| Adaptive levels, SwiftChat, parent scorecards | Later | |
| Help when stuck (AI chat) and the Ask TAP panel | In v1, in part | v1 has Ask TAP with prepopulated questions only. The AI agent is later (R-70). |
| Parent consent that can be withdrawn (roadmap, row 2.9: "required from 13 May 2027") | Later | This is a consent record, not a parent login. See R-96 and R-36. |
| Reports sent to BigQuery | In v1 | Every interaction of the student with the app goes to a new BigQuery table, in the same format as the WhatsApp events if possible (R-84). It does not need to be real time (O-18). |
| Glific web channel | Later | R-26, no date |
| iPhone | Not planned | The roadmap says not in year one |

Even though v1 is smaller, we should not block the roadmap. The login, the backend and the content must not be built only for the web app (see the principles above), and the numbers in the roadmap decide how much load testing we need (O-18).

## 2. What is not in v1

| Item | Status |
|---|---|
| Dark theme. The design shows a theme switch only as a hint. | Decided: not in v1 |
| Making the WhatsApp flow read and write the same progress record as the app (the product team's rule 1, R-48). Today the WhatsApp flow keeps points, streak and gems in Glific contact fields (`total_points`, `activity_points`, `streak`, `special_gems`), not in `frappe_tap` (lead's flow export, `system-understanding.md` 5.8). | Later |
| Onboarding in the app. The kids are pre-registered. | Not in v1 |
| A stronger login than the magic link (for example a username and PIN, or login through the class teacher). It also fixes the case where a student changes phones. | Later: decided later. It does not affect v1. |
| A generic app link shared in a WhatsApp group, where the student types a phone number. We cannot check the number yet, so v1 sends a magic link to each child. | Not in v1: decided later |
| Voice made by a central server for custom messages (for example the student's name). v1 plays only pre-recorded audio (R-17, R-57). | Not in v1 |
| Streaks. Kids do not understand them. | Paused |
| A pause scheduler that stops activity access for a group (by state, school or cohort), for example if a government rule limits activities per week. | Later |
| Tiered rewards (2x points for finishing early, an extra gem) and a schedule that adapts to the student. | Later (a north star, not needed now) |
| Creating the second child's `Student` record and Glific contact (R-34). We assume they exist. The lead developer handles the Glific contacts before the app is released. | Outside this project |
| Deactivate account and Delete account (R-36). | Later (decided in the review) |
| Voice recording and voice submissions (R-10, R-65). | Later (decided in the review) |
| Photo scanning with cropping or edge detection. A plain photo of the drawing is enough. | Decided: not in v1 |
| Photos of the students themselves, for example profile pictures. The app uses the TAP Buddy picture (the girl cartoon) instead. | Decided: not in v1 |
| Staff screens, WhatsApp template management and flow authoring in Glific. | Not changed by this project |

## 3. Screens and navigation

The Figma design ("Student App Direction") has 6 groups of screens.

| # | Requirement | Status |
|---|---|---|
| R-1 | The bottom bar has **3 items: Home, Gallery, Me**. There is no "Class" tab. The designer confirmed this after the meeting. The old mockups still show 4 tabs. | Decided |
| R-2 | The activity flow (Watch, Make, Quiz, Results) opens from Home. It is not a tab. | Decided |
| R-3 | **Who is learning**: choose a student profile, confirm, then a "Welcome back" screen. | Decided (in the Figma design) |
| R-4 | **Home**: greeting, points, "Ask TAP", the announcement banner (R-5) and the activity card. The card shows the activity name, the points and a "Start activity" button. The card changes with the state: start, submission pending, send submission. | Decided (in the Figma design and in the review). Home shows **one** activity card. |
| R-5 | **Later (v1.1). Announcement banner and events:** TAP switches a banner on or off for an event (for example a summer program). It shows the event name, a countdown to the start or the end, what the student has to do, and a **Join** button. Join opens an overview and an "I want to take part" button. Everyone starts at the same day and time. For now the banner stays at the top of Home. A pop-up was suggested, because the banner takes space in the WhatsApp browser. | Later (v1.1), decided 2026-10-30. The v1 app must leave room for it: see R-94. Decided earlier: banner at the top for now. |
| R-86 | **Tech. Later (v1.1):** Events are a new feature that we build in `frappe_tap` for v1.1. **Events are standalone: they are not linked to a Course.** An event has a start and an end date, a video and a quiz. It can be a learning unit with the unit type `event`. Only **one event is active for a batch at a time**. A student's registration is kept in a new `EventEnrollment` record, similar to `ProgramEnrollment`, and it links the student to the event. It is separate from `ProgramEnrollment`, because events are not tied to a course or a batch's curriculum. The number on the banner ("12,480 students are taking part") is the count of `EventEnrollment` records for the event. Everyone starts at the same day and time. | Later (v1.1). The v1 app must not block it (R-94) |
| R-94 | **Tech:** The v1 app must **not block the banner and events of v1.1.** Home keeps a place above the activity card for a banner. The app reads banners from one place in the Worker, which returns an empty list in v1. A banner can target a batch, a school, a state or a random group of students (like an A/B test), and can also carry an information message (for example "please give your consent"). The product team decides when a banner shows. The tech team decides how it is switched on and off (their own tool or a console for other teams). Event details are written from the team's input. The targeting is described in the banner document. | Decided (review, 2026-10-30) |
| R-6 | **Gallery**: the student's current activity with its points, the student's own work (or an empty box with a "Share your work" button), a grid of other students' finished work ("From TAP students like you"; which students: R-85), "Load more", and a full-screen viewer that you swipe through. | Decided (in the Figma design). Which work is shown, and the check before it is shown: see R-85 and R-59. The designer says the Gallery design is still being shaped. |
| R-7 | **Me**: profile, level, points, "My projects this year", project feedback screens, settings (the Edit profile screen is later, R-74) and switch profile. This replaces today's Passport and Profile screens. | Decided (in the Figma design). The data for "My projects" and feedback: see R-87. The skill chips are placeholders: see R-95. |
| R-8 | The look follows the Figma design: colors, fonts, spacing and shared parts such as buttons, chips and the header. | Decided (in the Figma design). The accent color (purple now) may change to green: not decided. |
| R-58 | The curriculum team's **exemplar works** for each assignment (what a good submission looks like) are part of the central content (R-18), stored in the CRM. They are not other students' work. They are shown in the Make step, and they can seed the Gallery at first. | Decided (product team meeting) |
| R-59 | A student's finished work is shown to other students only if its feedback says it is **valid**. Only pictures and videos are shown. Text and voice work is not in v1. In v1 the order is random. Points for work that is shown come later. | Decided (review) |
| R-85 | The Gallery shows any valid work, in random order, and only a small subset at a time (5 to 10, to be decided). Each work shows the student's **initials only**, not the full name. Choosing which students' work is shown (same grade, school, district, cluster or all of India) is a **setting** for later. If there is no work yet, the curriculum team's examples fill it. | Decided (review). The parental consent was taken at onboarding. |
| R-60 | The app shows no photos of the students themselves. The TAP Buddy picture is used where a profile picture would go. | Decided |

We have only exported images of the Figma file. We do not have edit access yet, so exact colors, fonts and sizes are read from images. We will check them in Figma once we have access.

### The activity flow in the Figma

The Figma "Class" frames show the activity flow in detail. These requirements come from reading those frames.

| # | Requirement | Status |
|---|---|---|
| R-61 | The activity has **four steps: Watch, Make, Quiz, Results**, shown in a step bar. Watch starts with a greeting, then the video. Make is where the student sends the work. The header has a back button, the points and "Ask TAP". | Decided (in the Figma design and in the review, 2026-11-02): the order is Watch, Make, Quiz, Results, as in the lead's Glific flow (`system-understanding.md` 5.8). The step names are placeholders and may change. |
| R-62 | **Watch:** an intro screen with the TAP Buddy picture, "Hear again" and a "Watch" button, then a video card (play button and length), then a message about the points earned. The videos are on YouTube and about 10 minutes long. A video needs a connection and uses mobile data, and this is acceptable. | Decided (in the Figma design) |
| R-90 | **The app does not check that the student really watched the video.** The student says it is watched (for example with an "I watched it" button after the video), and the app saves that step. This is the same as the WhatsApp system today, which trusts the call from Glific with no player check. The +10 points for the video come when the student taps the button (R-75). **The button turns on after a short minimum time, 5 minutes,** as in the WhatsApp flow, which gives the points 5 minutes after it sends the link. The minimum time is a server setting (R-41). | Decided (review, 2026-11-03). The Figma has no such button: see F-7. |
| R-63 | **Make:** the student sends work. In v1 this is mainly a **photo or a video**. The design also has a text version and a voice version for later. The course decides which. Each shows what is needed ("1 photo needed") and the curriculum team's exemplars. | Decided (product team meeting). Voice is later (R-10). |
| R-64 | **Photo:** "Add my work" offers Camera, Photos or Files. The student sees a preview ("Check your work before sending") and a check that it is a photo, then "Send" or "Change file". A sending bar shows the progress. A file that is not a photo gives a friendly message and the student can try again. The WhatsApp flow can only check the media type **after** the student sends (image or video) and gives two chances. The app checks **before** sending. | Decided (in the Figma design) |
| R-65 | **Voice:** "Record my voice" shows a timer with Cancel and Stop, then a play-back with "Record again" and Send. The sent voice note is shown in the chat. | In the Figma design. Not in v1: voice is later (R-10). |
| R-66 | **"I'll do it later" (postponing Make):** when the student comes to the Make step, there is an option to **do it later**. The app then goes on to the Quiz. After the quiz the app asks again ("ready to share your work?"). "Not today" skips again. The Results step opens only after the work is sent and the feedback has come (R-83). If the student leaves the app, Home shows "submission pending" (R-4). A WhatsApp nudge that says the submission is pending, with a link to a "Welcome back" screen, needs a new Glific message, which needs the product team's approval (see "Rules for our changes"). | Decided (product team meeting, and again in the review on 2026-11-02) |
| R-67 | **Quiz** (after Make): a question (text only in v1; a picture can come later if the curriculum team wants one), answer choices, right or wrong feedback with points, and a summary such as "4/5 correct". | Decided (in the Figma design) |
| R-91 | **Tech:** In `frappe_tap` the live quiz calls only **read** the questions. Nothing stores a quiz attempt, an answer or a score, and nothing limits time or retakes. `tapapp` therefore runs the quiz for the app. When the quiz starts, the server sends **all questions together with the correct answers** (not in the CDN files). The app gives right or wrong feedback at once, also without a network, and keeps the answers on the phone. The app sends the answers to the server when the quiz ends (and again after a lost connection). The server **checks every answer again with its own key**, stores the attempt and every answer, and gives the +1 points. The server's result is the one that counts (R-75). The phone can see the correct answers, for example with the browser's developer tools. The product team accepts this risk, because a leak is worth only +1 point per answer (decided on 2026-11-04, tech lead review). **If the student leaves the app in the middle of the quiz,** the app keeps the answers on the phone and continues from them when the student comes back. Each answer is also sent as an event to the interaction log (R-84), so we can see the progress. If the phone's copy is lost, the quiz starts again. **The points, the picture badge (R-69) and the Results step wait for the server's result, not the local one.** There is no time limit and retakes are not limited, as today. **Only the first scored attempt gives points** (+1 for each correct answer). A retake gives none (decided on 2026-11-05). | Decided (review). Changed on 2026-11-04: the whole quiz goes to the phone and is synced at the end. |
| R-92 | **Tech:** We make **no changes to the existing evaluation pipeline** (the plagiarism check and the AI feedback) in v1. Known behavior that stays as it is: (1) if the AI evaluation fails, the result is published as "Valid" with grade 0 ("technical issue, please resubmit"); (2) if the checking service cannot download a photo, it passes it on as "original" and drops the failure flag; (3) if it cannot open the file, it retries 3 times, then sends it to the dead letter queue, and nothing goes to the student or to `frappe_tap`; (4) nothing looks for submissions that never get feedback; (5) the checking service treats flat-colour or low-noise images (many drawings and screenshots) as possibly AI-generated and rejects them at 0.70 confidence, and it compares a photo's small fingerprint with all other students' submissions, across assignments, so original work could get 0 points and an "invalid" message. We judged this from the code and ran no images. **The app handles the first case itself:** it treats a result with **grade 0 or the "technical issue" text as not valid**, so the student gets 0 points and is asked to send corrected work (R-76). **No points are given in `frappe_tap` on this path, so `tapapp` can apply this rule without a conflict.** The app shows a "taking longer than expected" state when the feedback does not arrive (R-68). | Decided (review) |
| R-68 | **Results:** a short chat with TAP Buddy. First come the feedback messages, each with a speaker icon. Then TAP Buddy asks "Do you want to know your total points collected so far?", and the student taps the **"Yes" button**. Then a "YOU WON" card shows the activity points. The card **waits for the tap**: there is no timer. The tap only shows the points. The points are already given when the valid feedback arrives (R-75), so a student who never taps still gets them. The points in the header update **after the tap**, when the card shows them, so the reveal is not spoiled. (The product team can change this later.) The picture badge goes from 3/4 to 4/4 (R-69). Feedback is released later, on purpose, so children cannot race through the projects. A scheduled job starts the Glific feedback flow at 15:00, 16:30 and 21:00 IST for every submission whose feedback is ready. While waiting, the student sees "I'm looking at your work, please wait" and leaves the app. A friendly message with "Send again" shows when the work is not valid. | Decided (product team meeting). The trigger is a scheduled job: see O-28 |
| R-69 | **Today's picture:** a picture is revealed in 4 pieces, one for each step. A small badge on every screen shows 0/4 up to 4/4. The student sees the full picture after the Results step. | Decided (review): one piece unlocks for each step the student finishes, in the order the student does them (the usual order is video 1/4, work 2/4, quiz 3/4; if Make is postponed, the quiz gives 2/4 and the work 3/4), and the **4th piece only after valid feedback**. |
| R-70 | **Ask TAP:** a help panel opens from "Ask TAP". In v1 it shows **prepopulated questions** that fit the step the student is on (for example "How do I take a photo of my work?"), answered from the knowledge bank. It has no text box and no microphone. An AI agent with a daily limit is for later (a small agent that calls an LLM API such as Gemini or OpenAI, which can change). | Decided (review) |
| R-71 | **No connection:** the app shows "I am not able to talk to you. Looks like you're offline" and a Retry button. The student cannot go on until the connection is back, and then continues from the same step. **Exception:** a quiz that has already started can be finished without a network (R-91). The app asks for the network again at the end, to send the answers. | Decided (review). The Figma design has the screen. Quiz exception added on 2026-11-04. |
| R-72 | **There is no deadline in v1.** The app shows no deadline timer. Later, the activity schedule must stay **flexible for each school** (content rules), so it must not be hard-coded as one week. How deadlines are stored for each school is decided later. | Decided (review, 2026-10-30). The designer removes the countdown (F-8). |
| R-93 | **Tech. Later (v1.1), not needed for the test release:** The app learns which activity is current for its batch from a tiny file on the CDN, `current/<batch-id>.json` (see [content-spec.md](content-spec.md)). A **sync script** writes the file, and rewrites it only when it changes. The WhatsApp flow reads the activity (video link, assignment id, activity name, allowed media types) from a **Google Sheet** for each batch group, and not from `Weekly Student Flow`. The sync script reads the same sheet row, so the app and WhatsApp always show the same activity. The app reads it when Home opens, when the student returns to the app, and about every 5 minutes while Home is on screen. Each page adds a random delay to its timer and stops checking while it is hidden. When the file changes, the app shows the new activity and its timer without a reload. A closed app learns nothing until it is opened again, so the WhatsApp message (R-49) tells the student. Neither the Worker nor `frappe_tap` is called for this check. **To check with the lead developer:** that the team updates that sheet each week, and who can give the script read access to it. | Later (decided 2026-10-30). The v1 flow is linear and hardcoded (R-61) |
| R-73 | **Settings:** app language and account options. Messages are not read aloud automatically (R-17). **There is no theme switch in v1.** | Decided. The Settings items are placeholders and may change. There is no theme switch in v1. |
| R-74 | **Edit profile:** first name, last name, language, "Is a brother or sister also using TAP?", and the phone number (hidden in part, marked verified). | **Later** (decided on 2026-11-05). It is in the Figma design, but v1 does not build the Edit profile screen or the save call. |
| R-75 | **Points:** video +10, sharing the work +25, each correct quiz answer +1, correct submission +10. The first three come at once. **The +10 for a correct submission comes after the feedback, and only if the work is valid.** The +25 and the +10 are each given once for each unit, also after "send again" (R-76). The quiz points are given only for the first scored attempt: a retake gives none (R-91). `tapapp` gives the points: nothing in `frappe_tap` does today (R-87). Until the feedback arrives, the project shows "Points will be provided after feedback". | Decided (review) |
| R-76 | If the work is **not valid** (wrong format, wrong work or unclear), the student gets 0 points, is told why, and is asked to **send corrected work**. The feedback has a flag, `submission_validity`, that says whether the work is valid. Sending again is another call to `submit_artwork`. The call has no one-submission-a-week rule, so no change is needed in `frappe_tap`. **Sending again after an invalid result is an app-only feature.** The WhatsApp flow does not have it. (The WhatsApp flow only checks the media type after sending, with two chances.) | Decided (product team meeting) |
| R-83 | The **next project opens only after the feedback for the previous one is valid.** If it is not valid, the student sees the feedback and must send corrected work first. After valid feedback, the student can go straight to the next project. | Decided (product team meeting) |

### Figma frames that need correcting

We found these when we compared the Figma design with the decisions above. Please ask the designer to correct them.

| # | Frame | Problem |
|---|---|---|
| F-1 | Make or Quiz step, after the work is sent: "Congratulations Aarav! +25 points" | The +25 for sharing the work comes at once, so this frame is right. The +10 for a correct submission comes after the feedback (R-75). |
| F-2 | Results step: "Hi Champ, I looked at the work you sent me!" and the other feedback messages | Feedback arrives later, with the Glific message at 15:00, 16:30 or 21:00 IST (R-68). The live flow should show "still checking" and leave. The feedback messages belong on the feedback page that the WhatsApp link opens (R-16). The Results step starts when the student opens that link. |
| F-3 | Bottom bar in the Home, Gallery and Event frames | They show a "Class" tab. The bar has only Home, Gallery and Me (R-1). |
| F-4 | Settings: Theme (Default, Light, Dark) | There is no theme switch in v1 (R-73). |
| F-5 | Quiz and results frames: points such as "+15 points" for a correct answer and "earned 5 points in total" | Ignore the numbers in the design. The point rules are in R-75. The Results frames also show 40 points in the header and "Activity Points 50" on the card, which do not agree. |
| F-6 | The waiting screen "C29 · Wait for Another activity" (frame F4 Class_v2.1) | It shows TAP Buddy saying "I am still checking your submission and will share my thoughts with you real soon!" It does not show "Points will be provided after feedback" (R-75). The designer has to add it. |
| F-7 | Watch step, after the video | No frame shows how the student says the video is watched (for example an "I watched it" button). The designer has to add it, with a state for the first minutes when the button is off (R-90). |
| F-8 | Home and Gallery frames: the deadline countdown ("Ends in 2 days 15 hrs") | There is no deadline in v1 (R-72). The designer removes the countdown. |

## 4. Photos and voice recordings

| # | Requirement | Status |
|---|---|---|
| R-9 | A student can take a **photo or a video** of their work with the phone camera, or choose one from the phone, and submit it. | Decided (product team meeting). The video camera is not tested yet. Videos are **30 to 90 seconds** (screen recordings or videos of artwork), about 50 to 100 MB. The app limits the length to 90 seconds and tries to reduce the size before upload. **To check:** what the WhatsApp browser allows. |
| R-10 | A student can **record their voice** inside the app for voice-based projects, listen to it, record again, and submit it. | Later. Voice is not in v1 (decided in the review). |
| R-11 | **Tech:** If the student does not allow the camera or microphone, the app shows a clear message and says what to do next. The browser may not ask again after a refusal, so the message explains how to allow the camera or microphone in the phone settings, and the student comes back to the app. | Decided (review). |
| R-12 | **Tech:** Photos are made smaller on the phone and saved as **WebP** before upload. WebP files are usually smaller than JPEG, which helps slow connections. If the phone cannot make WebP, the app uses JPEG. HEIC is never sent. The checking service has no size limit and no resize, and it cannot open HEIC photos. The lead developer says `submit_artwork` accepts any image format. | Decided (review). Changed from JPEG to WebP on 2026-11-05 (team discussion). **To check on the dev server:** the whole pipeline (plagiarism check, AI feedback) opens a WebP file, and the WhatsApp browser can make WebP on the test phones. |
| R-13 | **Tech:** A failed upload does not lose the work. The student can try again. | Decided (review) |
| R-14 | **Tech:** (For later, when voice comes.) The voice note must be in a format the whole pipeline accepts. Android phones record `webm/opus`. No service names `webm`, and the AI model receives the raw file, so we cannot be sure it accepts `webm`. We propose that the app converts the voice note to WAV or MP3 before sending. iPhone is not planned for year one in the roadmap. | Later |
| R-15 | The submitted photo or recording enters the **same evaluation process that WhatsApp uses today** (plagiarism check, AI feedback). | Decided (review) |
| R-16 | The evaluation feedback (text and audio) is **shown in the app**, in the Results step (R-68) and in "My projects". The student gets a **WhatsApp message with a link** that opens the feedback page directly, where the student can read it and listen to it. | Decided (product team). The WhatsApp message with the link needs the product team's approval: see R-50 and O-28 |
| R-88 | **Tech:** **A student's own work** stays in GCS. The Worker checks that the student is the one in the student token (R-81), then gives the app a short-lived link to the file, made with the service account for the app (R-89). `frappe_tap` is not changed. **The Gallery** uses a copy in R2, made only after the feedback says the work is valid (R-59), and only for work from the app (`sources` = `tapapp`). WhatsApp work is not touched. The copies are kept in a separate place so we know which ones the Gallery can pick, and they are refreshed on a schedule so new work appears. We chose this (our own copy in R2 for the Gallery) and not a signed link made by `frappe_tap`. To check: the Worker can read the private GCS bucket securely (for example with S3-compatible HMAC keys of the service account, kept as Worker secrets) and can serve photos and videos. The deletion rule for the copies is in R-96. | Decided (review) |

Today, the prototype does not upload photos or videos. It marks them as passed. It records no voice, only a typed answer. Both must be fixed for v1.

### How a submission travels

**Today (WhatsApp):**

WhatsApp, then Glific, then `frappe_tap` (`submit_artwork`: it creates the `Submission` and uploads the file in a background job), then RabbitMQ, then `tap_plg` (plagiarism check), then RabbitMQ, then `rag_service` (AI feedback), then RabbitMQ, then `frappe_tap` (saves the feedback and makes the audio). At 15:00, 16:30 or 21:00 IST a scheduled job starts the Glific feedback flow, then Glific sends a WhatsApp message to the student.

**With the app in v1:**

1. The student sends the work in the app. The file goes to our storage, and our server (the Worker) checks the student.
2. Our server calls `submit_artwork` in `frappe_tap`, unchanged, with the assignment id, the student id and a link to the file.
3. From here the pipeline is the same as for WhatsApp: `frappe_tap` downloads the file into its own storage, then `tap_plg`, then `rag_service`, then back to `frappe_tap`.
4. When the feedback is ready, the next scheduled delivery (15:00, 16:30 or 21:00 IST) starts the Glific feedback flow. Glific sends a WhatsApp message. For an app student, the message has a link to the app and not the feedback text. WhatsApp-only students get the message as today (needs the product team's approval, R-16, R-50, O-28).
5. The student opens the link. The app reads the student's feedback from `frappe_tap` through our server.

Steps 1, 2 and 5 are new code in the app, the Worker and `tapapp`. Steps 3 and 4 are existing production code.

**Storage (decided):** submitted files stay in the current GCS buckets in v1. A move to Cloudflare R2 may come later. It would need changes in `frappe_tap`, `tap_plg` and `rag_service`, which only read GCS links today. The file the app uploads first only has to wait somewhere that `frappe_tap` can download from. `frappe_tap` then copies it into GCS, so `tap_plg` and `rag_service` see no difference. Where that waiting place is, and how the Worker creates the upload link, is covered in R-89.

## 5. Spoken messages

| # | Requirement | Status |
|---|---|---|
| R-17 | The **fixed messages** of the standard flow template (greetings, instructions, button text) have **pre-generated audio files**, one for each message in each language. The student taps the speaker icon to hear the clip. Messages never play by themselves. | Decided |
| R-54 | The audio files are stored centrally with the content (R-18). Each file is linked to its message and its language, and has a version. If the message text changes, the file is marked as out of date. | Decided (review) |
| R-55 | If a message has no approved audio file in the student's language, the speaker icon is hidden. The app never plays a different language. | Decided (review) |
| R-56 | **Evaluation feedback audio** is generated for each student, as it is today. The student plays it in the app, from the feedback page (R-16). | Decided |
| R-57 | Messages that contain a student or course name are not pre-recorded. Their spoken text is written without the name. | Decided (review) |
| R-77 | The **curriculum team provides the audio clips**, one for each message in each language. | Decided (product team) |

**Why audio files.** We tested speech built into the phone's browser. It does **not work** in the WhatsApp browser on the phones we tried, and Indian-language voices are not installed on many phones. Audio files played from the app worked on every phone we tested.

**How big the job is.** v1 uses one standard flow template for all courses, so the number of fixed messages is small. The English template has about 25 spoken messages. For 5 languages that is about 125 clips.

**How the clips are made and kept** (proposal):
- Each clip has a record with the message id, the language, the exact script, a version, the audio file and a status: needs recording, recorded, approved or out of date.
- The curriculum team provides the clips. A list shows what is missing or out of date, and the team attaches the files.
- Only approved clips are shown to students. Machine-made drafts are for internal tests only.
- Files are converted to one safe format, such as MP3, so they play on every phone.

**Still open** (see O-1): who translates the scripts, which languages are in v1, and how the curriculum team hands over the files.

## 6. Content and languages

| # | Requirement | Status |
|---|---|---|
| R-18 | **Tech:** Courses, flows, pictures and audio are **downloaded from one central place**. They are not bundled inside the app. **For the v1 test release:** the tech team turns the curriculum team's content for the hardcoded flow into JSON files (by hand or with a small script) and uploads them to R2 with a manifest. They are served from the CDN. The file layout is in [content-spec.md](content-spec.md). A Publish step from Frappe comes later. | Decided (review, 2026-11-02). The Publish step is open: see O-9. **Changed on 2026-11-09 for v1:** the course files are **bundled in the app** (`assets/data/courses/<language>/`), and the CDN download is for later. The files carry the ids that the API needs (`uid`, `qid`, `aid`), see `scripts/content_ids.py`. |
| R-19 | **Tech:** Each piece of content has a **version**. The app checks the version and downloads what changed. | Decided (review) |
| R-20 | **Tech:** A small first-run copy stays in the app, so the first visit still works with a weak connection. | Decided (review) |
| R-21 | **Tech:** If the content changes while a student is in the middle of a unit, the student finishes that unit on the old copy. | Decided (review) |
| R-22 | **Tech:** If a download fails, the student sees a clear message and can try again. | Decided (review) |
| R-23 | **v1: Hindi and English only.** Later: Marathi, Kannada and Punjabi. The learner's language comes from their profile. | Decided (review) |
| R-24 | **Tech:** The app text is translated. Today almost all text is written in English in the code. | Decided (review) |
| R-25 | **Tech:** Names such as "Champ" (used when a name is missing) become one translated fallback text. | Decided (review) |
| R-79 | **Tech:** When a unit opens, the app loads all of that unit's small files first (text, quiz, pictures, example images, audio clips), so the steps start quickly. Videos always need a connection. | Decided (review) |

Today the app has 17 MB of bundled files. Four of the five course languages are bundled but never used.

## 7. Conversations: v1 and the later Glific web channel

**v1 uses the app's own flow, with one standard template for all courses.** The chat steps (greeting, video, submission, quiz, results) are the same template for every course. The course supplies the details, such as unit names, videos and questions.

Later, the plan is to move the chat to Glific. The app would talk to Glific over a web connection, and Glific flows would drive the messages. Glific's web channel is not ready, and Glific has given no date. So **v1 does not depend on it**.

| # | Requirement | Status |
|---|---|---|
| R-26 | **v1:** the activity chat runs in the app (onboarding is not in v1: the kids are pre-registered), from **one standard flow template for all courses**. The Glific integration comes in v2 or later. | Decided |
| R-52 | The flow template and its text come from the central content (R-18), in each language. A new course does not need new code. In v1 we use **one standard flow for all content**. | Decided (review) |
| R-53 | **Tech:** The app keeps the chat logic behind a clear boundary, so the source of messages can later be swapped for Glific without rewriting the screens. | Decided (review) |
| R-27 | **v1:** a submission from the app follows the **same process as WhatsApp**. TAP's backend receives the assignment, the student and the submission through the existing `submit_artwork` call, which creates the submission record and starts the evaluation. The app never holds the server key. Our own server checks the student and makes the call. | Decided (product team: same process as WhatsApp). The file upload: see R-89 |
| R-89 | **Tech:** For a photo or a video, `submit_artwork` takes a **link** that the server can download, together with the assignment id and the student id. Our server gives the app a **temporary upload link**, the app uploads the file, and our server calls `submit_artwork` with that link. For text, the submission is the text. The server downloads the whole file from the link (30 to 60 seconds, no size limit, no sign-in), so the link must work without a login. The student id (the `ST…` id) comes from our own records, never from a phone number typed by the student. The call has **no duplicate check and no idempotency key**, and every call makes a new primary submission, so our server must not send the same work twice. TAP will create a service account with read and write access to the submission bucket on GCS for the app, and the Worker uses it to upload and read the student's files. Voice is later (R-10). | Decided (review) |
| R-28 | **Tech:** **Later (Glific web channel):** our server creates a short login token for Glific for each student. It lives about 15 minutes and is renewed while the student uses the app. | Later |
| R-29 | **Tech:** **Later (Glific web channel):** when a student signs out, or a different student uses the same phone, the app ends the Glific session. | Later |
| R-30 | **Tech:** Points, progress and anything we show later (projects, feedback) are stored by us. This matters most with Glific, which says old messages may be deleted after about two months (Glific's web channel proposal, section 7.1). | Decided (review) |
| R-84 | The app **saves every interaction of the student with the app** (taps and where the student taps, screens opened and how long each stays open, steps done, each quiz answer, the chat messages shown, errors) for later analysis of how the kids use the app. This includes the chat conversation. The student cannot see it. The events may hold **text the student types** and the text of the chat messages, as they are. They never hold the phone number, and they identify the child only by `student_id`, never by name. Typed text can contain a name that the child writes, and we cannot filter that, so the data stays only in BigQuery with limited access, and the product team approves this privacy rule before the test (A20). The events go to a **new table in BigQuery** (the Worker puts them in a Cloudflare Queue and a consumer writes them to BigQuery. `frappe_tap` is not involved, so it carries no extra load, R-78), in the same format as the WhatsApp events if possible (see O-18 and A15). It is **needed in v1** (tech lead review, 2026-11-04). Later, Glific will keep its own chat history. | Decided (product team meeting; moved to v1 on 2026-11-04). Retention: see R-96. |

Glific describes the web channel as a **proposal**. The message format may change. Rich parts of our design, such as the video player, quiz cards and step bar, do not have a message type yet. We would need to agree with Glific how each one is carried. This does not block v1.

## 8. Students, phones and login

| # | Requirement | Status |
|---|---|---|
| R-31 | A student can only see and change the profiles of the children **on the signed-in phone**. | Decided. On a shared phone the children can open each other's profile: see R-34. |
| R-32 | **v1 has no teacher role and no parent access.** The student uses the same student-only flow as WhatsApp. The student signs in through a WhatsApp link that carries the **phone**. The app then shows the children of that phone, and the student picks their name (the Figma "Who is learning"). The roadmap's account with a password and PIN is a later route for the installed app. The sign-in must not let a student reach another student's data. | Decided: no teacher, no parent access, WhatsApp link with a name picker. The PIN comes in a later version (R-34). |
| R-33 | **Tech:** The app never signs a student in because of a phone number that the student types. The phone for a login comes only from the WhatsApp link or from the `Student` record. (A typed number may only ask for a new link. The link goes to that number's WhatsApp, so it proves nothing about the person who typed it.) The link itself proves that the person has that WhatsApp number, so v1 needs no other check, such as an OTP. | Decided (review) |
| R-34 | One phone can have **several children** (for example brothers and sisters who share one phone). The student can switch profile without signing in again. | Decided (review). **Assumption:** brothers and sisters on one phone are separate `Student` records, each with their own Glific ID. How they are created (the `Student` record and the Glific contact) is outside this project. Today only one child of a family is saved, so the picker shows one child for most phones until the siblings exist. |
| R-35 | The app has a visible **Sign out**. It clears the child's data from the phone. | Not in v1 (review). See risk 7 in `whatsapp-link-login.md`. |
| R-36 | The design shows "Deactivate account" and "Delete account". They must really work, or be removed from v1. | Later (decided in the review) |

## 9. Progress, points and rules

| # | Requirement | Status |
|---|---|---|
| R-37 | The server is the source of truth for points, level and the weekly limit. The app does not decide them. | Decided |
| R-38 | **Tech:** Sending the same completion twice, for example after a bad connection, gives points only once. Nothing in `frappe_tap` does this today, because the live path stores no completions. `tapapp` does it: the time field of each step in Unit Progress says it is done, and a key identifies each upload and each quiz attempt. | Decided |
| R-39 | **The server sets no weekly limit today, and v1 adds none.** In v1 the only pace rule is R-83: the next activity opens only after the work is submitted and the feedback is valid. The prototype's "2 units a week" goes away. A weekly release and a pause scheduler come later (section 2). | Decided (review, 2026-10-30) |
| R-40 | **Every step is saved to the server as soon as it happens** (video watched, quiz answered, work submitted). Nothing in `frappe_tap` stores these steps today, so `tapapp` stores them in a new child table, **Unit Progress**, of `ProgramEnrollment`. It has **one row for each unit** of the course (about 10). The row holds the video step, the postponed Make, the quiz (all answers and the score as JSON), the work sent and the valid feedback, each with its time and its points. A step is written once, so a repeat saves nothing new and gives no extra points. The exception is "send again" (R-76): a new `Submission` updates the link to the latest one. The phone is not the main copy of progress. If the connection drops, the app stops at the offline screen (R-71), and the student continues from the same step after Retry. **One exception: the quiz.** Once the quiz has started, the student can answer all questions without a network. The answers are saved on the phone and sent when the quiz ends or when the connection is back (R-91). | Decided (review). Quiz exception added on 2026-11-04. Storage changed on 2026-11-05 (tech lead): Unit Progress child table instead of a separate step table. |
| R-41 | The rules (points, limits, level names and thresholds) are settings on the server that can be changed. They are not fixed in the code. Points belong to the assignment or course. Limits and levels are server settings. | Decided. Who can change them, and for whom, is decided later. |
| R-48 | **One progress record for each child, shared by all channels** (WhatsApp, web app, later an installed app). A child who moves from one channel to another continues at the **same step**, not only with the same points. | Decided (the product team's rule 1, and in the review): the record is `ProgramEnrollment` (with its submissions), with no second copy in the TapApp learner record. On `journey_2026` the Summer Program engine that filled it is switched off, so we treat it as an **empty table**. It keeps only the summary numbers the app needs (the point fields it already has). The steps are stored in its child table, Unit Progress, with one row for each unit (R-40). The prototype has no real users, so no data is moved. Writing to it is a change to production data: see "Rules for our changes". |
| R-49 | WhatsApp stays on. It reaches children who have not moved to the app, and it tells a child that something is waiting (for example a new activity or feedback). The app does not depend on push messages. | Decided (the product team's rule 2) |
| R-50 | A link in a WhatsApp message (for example the feedback link, R-16) opens the app on the right screen for the right child. The feedback link is a **signed magic link** that carries the student and the place to go. It logs the student in, so no earlier sign-in is needed (see A11 and A15 in `whatsapp-link-login.md`). Anyone who holds the link can open it, as with the login link. The link opens the **Results step** (Figma frames M-C24 to M-C27). | Decided (review) |
| R-51 | The weekly limit and the points count work done on **all channels** together. | Decided (review) |
| R-87 | **Tech:** The data for "My projects" and the feedback screens comes from `Submission` (the work, the feedback, valid or not, the date), the points and steps that `tapapp` stores (R-40, R-75), and the course's assignments (project names and order). There are 6 projects a year. The level (for example "Bronze Buddy, 120 / 400") is worked out in `tapapp` from the points, with the thresholds as settings (R-41). Today the levels are hard-coded in the prototype. | Decided (review) |
| R-95 | **Skill chips ("I'm getting better at") are placeholders in v1:** a fixed set of tags, the same for every student. The curriculum team (Manu Agarwal) provides the default tags. Later, each activity or milestone (at the video and quiz level) has its own tags, shown when the child finishes it. Many kids read little, so the chips can be voice based or character based. | Decided (review, 2026-10-30) |
| R-96 | **Tech:** Photos, videos and the copies in R2 are deleted when the student moves to a new batch (once a year). **To check:** who deletes the original files in GCS, because they belong to the `frappe_tap` pipeline. | Decided (review, 2026-10-30) |

The WhatsApp system and the prototype app today keep progress in two different records. The product team's rule 1 says there must be one. We keep a child's progress in one table, `ProgramEnrollment` in `frappe_tap` (R-48). The prototype's own table, `Tapapp Learner`, is dropped, so there are never two different point totals for one child. `frappe_tap` only stores the submissions and the feedback. It does not store the steps, quiz answers or points of the live WhatsApp flow (see `system-understanding.md`). So `tapapp` has to store the steps, quiz answers and points for the app itself.

### Where does the progress come from? (`journey_2026` branch of `frappe_tap`)

We read the code on `journey_2026` branch of `frappe_tap`. The Summer Program engine that used to fill `ProgramEnrollment` is switched off, so the table is empty for the live flow. Streak and gems are not shown in the design, so the app does not need them.

| What the app needs | What exists today | Result |
|---|---|---|
| Points for video, quiz and submission | Nothing gives or stores points. `ProgramEnrollment` has point fields, but nothing fills them. | **New.** `tapapp` works out and stores the points (R-75). |
| Where the student is in the activity (video, quiz, work sent, feedback) | Nothing stores "video watched" or the quiz steps. `Submission` shows the work sent and the feedback state. | **New.** `tapapp` stores each step (R-40). |
| Quiz answers and score | Not stored. The live quiz calls only read. | **New.** `tapapp` stores the attempt and each answer, and re-checks them on the server (R-91). |
| The weekly limit | None on the server. Glific decides what comes next. | R-39. |
| The current week | Not needed in v1. The flow is linear, and the next activity opens after valid feedback (R-83). | Later: see R-93. |
| Level ("Bronze Buddy", 120 / 400) | No level. `Student.level` is a difficulty (L1 to L3), not this level. The levels are hard-coded in the prototype app today. | **New.** Work it out in `tapapp` from the points, with thresholds in settings (R-41). |
| Skill chips ("I'm getting better at") | Only rubric rows on each `Submission` ("Content Knowledge", "Creativity"). | Placeholder tags in v1 (R-95). |
| "My projects this year" (3 of 6) and the path | The course's assignments (through `Course Level` and `Learning Unit`, by week) and the student's `Submission` records. | `tapapp` builds it by reading those records. |
| Deadline timer ("Ends in 2 days 15 hrs") | None. | No deadline in v1 (R-72). |
| Feedback, whether the work was valid, and the feedback audio | On `Submission`. | Read from `Submission`. |

Result: nothing on the live path tracks progress, so `tapapp` creates every progress record. The existing records give us the student, the content and the submissions.

## 10. Quality, devices and delivery

| # | Requirement | Status |
|---|---|---|
| R-42 | The app works in the **WhatsApp browser** on Android phones (**Android 10 and above**), with the mobile design. Desktop designs exist (1440 px), but v1 uses the mobile ones (375 px). There is no installed app in v1: the installed Android app comes later and will use the same login and backend, so they stay general. The designer makes both sizes and will add others if we ask. | Decided (product team meeting) |
| R-43 | **Tech:** The first screen appears quickly on a slow connection. The 7.6 MB loading animation (`tap-buddy-loader.gif`, used on the splash screen) is replaced by a small file. Smaller versions already exist in the project (MP4 1.5 MB, WebM 0.7 MB), but the app does not use them yet. The fonts are bundled in the app. Today the app downloads the Inter font from Google when it starts (package `google_fonts`), and no font file is included. | Decided (review) |
| R-44 | **Tech:** Errors show a clear message and a Retry button, not technical text. Prototype review: some screens show technical text (for example "Failed to load dashboard: AuthException") and some Retry buttons cannot fix the cause. The app already has a shared error screen with a Retry button. Every failing call must use it. | Decided (review) |
| R-45 | **Tech:** The app includes basic accessibility: labels for icons, big enough touch targets, and text that can scale. Prototype review: the code has no labels for screen readers, and about 18 tap areas (`GestureDetector` or `InkWell`) have sizes that nobody checked. In the Figma some tap targets look small (the speaker icons and the step circles). The tap area can be larger than the picture, so this needs no design change. | Not required for v1 (review). We do it in v1 if there is time. |
| R-46 | **Tech:** The `tapapp` functionality is deployed **as part of `frappe_tap`**, as a module in the same app (not as its own Frappe app). Its code is added to branch `journey_2026` before delivery: only the `tapapp` module, not the rest of the fork. The other branches are not needed. | Decided (review, 2026-11-02) |
| R-47 | **Tech:** Before real students use the app, the known security problems that touch the app are fixed in the parts we own (the Worker, `tapapp` and the app). Problems in the existing `frappe_tap` need the product team's approval: see "Rules for our changes". The problems themselves are listed in `production-readiness.md` (section 8) and `known-gaps.md` (S3, S13). They are for the tech team. The product team does not need to read them. | Decided |
| R-78 | **Tech:** The app must **not slow down the `frappe_tap` server**. Content comes from a CDN. Progress reads are cached for a short time and cleared when a step finishes. Writes are few (only meaningful steps) and safe to repeat. We load-test to the numbers in O-18 before launch. The cache is never a second source of truth. `frappe_tap` was designed for a 100,000-student target, and the roadmap expects 500,000 by July 2027, so the load test must cover that. The checking service (`tap_plg`) runs one process, and its photo comparison grows with the number of stored submissions. The AI feedback service (`rag_service`) handles one message at a time. Neither states a throughput target. | Decided (review) |
| R-80 | **Tech:** `tapapp` reads the content tables (`Course Level`, `Learning Unit`, the videos, quizzes and assignments). `Weekly Student Flow` is not used in v1. It does not use the Summer Program calls (`get_next_content`, `get_weekly_content`): they are switched off. Neither the app nor the Worker calls `ready_to_receive_feedback`. The feedback is requested when the work is submitted, and a scheduled job in `frappe_tap` starts the Glific feedback flow at 15:00, 16:30 and 21:00 IST (see O-28). | Decided (review) |
| R-81 | **Tech:** Our own server (the Worker) checks that the student belongs to the signed-in phone once, when the student picks a name (`select_student`). After that, every call to `frappe_tap` carries the **`student_id`** from the student token, not the phone number. This avoids mix-ups between brothers and sisters who share a phone, and it still works if siblings sign in from different devices in later phases. The Worker never takes a `student_id` from the request body. The app keeps the phone token as well, so the student can switch profile: the Worker route `select_student` takes the phone token and gives a new student token. | Decided (tech lead review, 2026-11-04) |
| R-82 | **Tech:** **The key for `frappe_tap` lives only in the Worker**, as a secret. The app and the browser never see it, and the app never calls `frappe_tap` directly. Every call to `submit_artwork` and the read methods is made by the Worker. The feedback is started by a scheduled job in `frappe_tap` (R-80). The app talks only to the Worker, with the student's own login. Files go to our storage through a short-lived upload link that the Worker creates. | Decided (TAP team) |

### What we tested in the WhatsApp browser

We built small test pages and ran them on two Samsung phones inside WhatsApp.

| Test | Galaxy S20 FE | Galaxy A31 |
|---|---|---|
| Phone speech (text to speech) | Not available | Not available |
| Playing an audio file | Works | Works |
| Taking a photo | Works | Works |
| Live camera | Works | Works |
| Recording voice and playing it back | Works | Works |
| Permission question for camera and microphone | Asked | Asked |

Not tested yet: the video camera, Redmi Note 13 and any iPhone. We want a few more phones before we call this settled.

## 11. Open decisions

The below items need a decision:

| # | Question | Why we ask |
|---|---|---|
| O-1 | Fixed messages use pre-generated audio files in v1. The curriculum team provides the clips (decided). Only the standard text has audio (decided in the review): the assignment text and the feedback messages do not. Messages never play by themselves: the student taps the speaker icon. How does the team hand over the files (format, file names and where to put them)? Manu Agarwal is the contact for the translations and the hand-over. | Recording is the largest effort in this area. |
| O-9 | **Central content: the Publish step (for later).** For the v1 test release the content comes from the CDN, from files the tech team builds (R-18). Later, the curriculum team writes content in Frappe (the master copy) and a Publish step builds the versioned JSON files with a manifest and puts them in R2 behind the CDN. The proposal is in [content-spec.md](content-spec.md). Translations are owned by the curriculum team (Manu Agarwal is the contact). Two points are open: (1) Does the curriculum team author in Frappe and the existing Google Sheets import, or in another tool? (2) Does the standard flow template live in git (our proposal) or in Frappe, so the team can edit messages without a developer? | The app needs one source, and the files need a fixed shape so that publish can check them. |
| O-13 | Which outside services may receive children's data? Today the AI feedback service sends each child's photo, voice recording and text, as raw files, to Google Vertex AI (Gemini). It filters no personal information, and it prints the prompts and results in its logs. Is this acceptable, and in which region does it run? TAP engineering (review): this is acceptable, because the models run in TAP's own private cloud accounts. Which models and which region: to be confirmed. | Data protection. The app adds no new service, but the volume will grow. |
| O-18 | **When does the next phase start, and how big is it?** v1 is a test release in mid-November for 30 to 100 pre-registered kids (the number is not decided), handled personally (decided). We plan the load tests from the answer. | The size decides how much load testing and reporting work we need. `frappe_tap` documents a 100,000-student design target. The long-term target is 500,000 children by July 2027. |
| O-28 | **App students and WhatsApp-only students: which Glific flow sends the feedback message?** Today one Glific "feedback" flow (id `41954`) serves every student. `submit_artwork` stores that id in the field `feedback_flow_id` of the `Submission`. The delivery job (15:00, 16:30, 21:00 IST) starts the flow whose id is in that field (checked in the code on `journey_2026`). The product team thinks at the **student** level: a student is either an app student or a WhatsApp-only student. An app student must get "Your feedback is ready" with a signed link. A WhatsApp-only student must get the feedback text as today. **We recommend Option B** (the lead developer will check it). **Option B:** right after the app sends the work, `tapapp` sets the submission's `feedback_flow_id` to a **new Glific flow for app students**. The delivery job then starts the right flow, with **no change to `frappe_tap` code**, and the shared flow for WhatsApp-only students is not touched. **Option A (not recommended):** the shared flow asks `tapapp` through a webhook whether the student is an app student. If the webhook fails, WhatsApp-only students are affected too. **What Option B needs:** (1) a write to one existing field of `Submission`, a production table, which needs the product team's approval; (2) the change must happen before the job runs, which is safe because it is done right after the submission and the feedback takes longer; (3) the Glific team builds the app-student flow, which gets the same variables as today (`submission_id`, `feedback`, `overall_feedback`, `overall_feedback_translated`); (4) the flow gets the signed link through a webhook call to `tapapp`, but only this new flow has the webhook, so a failure cannot hurt WhatsApp-only students. **How does a student become an app student?** We propose: the first time the student logs in with the WhatsApp link, `tapapp` records it. From then on the student gets the link for every submission. Is this acceptable? The flow also needs the student's Glific ID (the delivery job finds it from `Student.glific_id`, or by phone). | A change to the shared flow must not break feedback for WhatsApp-only students. Option B avoids that. It needs the product team's approval for the `Submission` write and the Glific team's work. **Approved on 2026-11-05 after a review with the lead (Option B).** The Glific team still has to build the app-student flow (A10). |

## 12. Risks and dependencies

- **Figma access.** We have images only. Exact styling needs edit access to the file.
- **Glific web channel.** It is a proposal with no date. v1 does not depend on it. If it arrives later, the message format and the rich widgets still need to be agreed.
- **Backend merge.** The `tapapp` branch and the main development branch have drifted far apart. The merge needs care and a test.
- **A magic link is tied to the registered phone.** If a student changes phones, the link fails. We accept this for the small v1 test. A stronger login comes later (section 2).
- **Real-phone coverage.** Two phones are tested. More are needed.
- **School networks.** Many students share one internet address. Rate limits must allow for this.
- **Pipeline reliability.** The existing pipeline can publish a failed AI run as a good result, can lose some submissions without telling anyone, and can flag original drawings as plagiarism or AI-generated (R-92). Reusing it brings these problems into the app.
- **Server load.** The prototype kept its own copy of progress, partly to keep traffic away from the `frappe_tap` server. Using one record (R-48) puts the app's calls on the same server and the same database rows as the WhatsApp jobs. The answer is a CDN for content, a short cache for reads, few and repeatable writes, and a load test (R-78, O-18). We do not know the server's size or its current load.
- **Curriculum content.** The curriculum team must supply the videos, the exemplar works, the submission messages (for example "Champ, I'm looking forward to your pencil holder") and the evaluation guidelines. It takes about 2 weeks after they finish, to put it into the CRM and test it. Anand coordinates it.
- **Data protection.** Children's names, photos and voices pass through several services.

## 13. QA: How we will check it is done (proposed)

- A student cannot read or change the data of a child on **another phone**, even by trying other ids. Children who share one phone can switch between themselves (R-34) until the PIN is added.
- Sending the same completion twice does not give extra points.
- The weekly limit resets at the start of a new week without clearing the cache.
- If the connection drops, the app stops at the offline screen. After Retry, the student continues from the same step, and no progress is lost. **Exception (R-71, R-91):** a quiz that has started can be finished offline. The answers are sent later.
- The quiz can be finished without a network, and the answers are sent when the connection is back.
- If the student leaves the app in the middle of a quiz and comes back, the quiz continues from the saved answers (R-91).
- The server ignores a score sent by the app. It checks every answer again and gives the points (R-91).
- Every call uses the `student_id` of the token and ignores a `student_id` in the request body (R-81).
- Photos and videos reach the evaluation process. The student gets the Glific message (15:00, 16:30 or 21:00 IST) when the feedback is ready, and sees the feedback in the app.
- A changed course appears in the app without a new app release.
- The app loads and works on the agreed phones inside the WhatsApp browser.
- The first screen appears in an agreed time on a slow connection (R-43). We need to set the time and the connection speed.
- No screen shows technical error text, and every error screen has a working Retry button (R-44).
- (Only if there is time.) Icons have labels, touch targets are at least 48 px, and the layout still works when the phone's text size is large (R-45).
- The load test reaches the numbers agreed in O-18 without slowing the `frappe_tap` server (R-78).
- The 3-tab navigation and all screens in section 3 match the final Figma design.

## 14. Sign-off

| Name | Role | Date | Comments |
|---|---|---|---|
| | | | |
| | | | |
