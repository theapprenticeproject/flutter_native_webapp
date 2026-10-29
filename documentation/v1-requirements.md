# TapApp v1: requirements for review

**Purpose.** This page lists what we plan to build for version 1 (v1) of the TapApp student web app. We want to agree on it with the product team before we build.

**Status of this page.** Draft for review. Nothing here is final until the product team confirms it.

**Assumption about the backend.** The team deploys one branch of `frappe_tap` and only the lead developer knows which. We assume it is `journey_2026`. Flows and code on other branches do not count. If this is wrong, the rows that follow the backend need a second pass. They are R-27, R-38 to R-40, R-48, R-75, R-76, R-80, R-82, R-87, R-89, R-91, R-92 and O-28. See [system-understanding.md](system-understanding.md).

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

## Principles from the product team

The product team gave us two rules. Every requirement below must fit them.

1. **Progress lives in TAP's own records, not on the surface.** A child can move from WhatsApp to the web app to an installed app and pick up exactly where they were.
2. **WhatsApp does not switch off.** It stays the way TAP reaches a child who has not moved, and the way TAP tells a child that something is waiting.

What this means for us:

- Progress cannot live only on the phone, and not only in a chat history. The prototype keeps some progress on the device. That must change (R-37, R-40, R-48).
- Glific may delete old messages after about two months, so Glific's messages cannot be the record (R-30).
- The same child must be recognized on every channel (R-34, R-48).
- The app does not need its own push notifications in v1. WhatsApp tells the child that something is waiting, with a link into the app (R-49, R-50).
- The backend and the login must not be built only for the web app. An installed app will use them later.

## Rules for our changes

`frappe_tap` is in production. **We do not change its existing logic or behavior without the product team's approval.** Our freedom is limited to the `tapapp` module and the app (the prototype).

What this means:
- New backend work lives in `tapapp`. It may **read** `frappe_tap` data (for example `Student`, `ProgramEnrollment` and `Submission`). It changes production data only through existing `frappe_tap` calls that stay as they are, such as `submit_artwork`.
- We do not change existing `frappe_tap` calls, jobs or rules.

These items touch `frappe_tap` or the Glific flows it uses, so they need the product team's approval before we do them:

| Item | Why it touches `frappe_tap` |
|---|---|
| Making `submit_artwork` refuse calls that have no API key (R-47, R-89) | The code does not check a key (`allow_guest`, `ignore_permissions`). The nginx setup we found has no key rule. A test on a **local** server (`save_submission` family) gave: a valid token works, a wrong token is rejected (401), and **no token works** with the same result as a valid one. So the code accepts calls without a key. We have not tested production or `submit_artwork`. Production may have a layer in front that we cannot see. Refusing calls without a key could break any Glific flow that does not send the key, so the client must approve it, and the flows must be checked first. |
| The WhatsApp message that tells the student to open the feedback page (R-16, R-50, O-28) | Reading and showing the feedback needs no change. The message is sent today by the existing feedback step, through one Glific flow (label "feedback") that all students share, including WhatsApp-only students. Adding a link means changing that flow, and maybe the data `frappe_tap` sends to it. That changes what those students get. |
| Any new write to `Student` (for example edit profile, R-74) or to `ProgramEnrollment` (our progress record, R-48) | `Student` is in use by the live flows, so a write changes production data that WhatsApp also reads. `ProgramEnrollment` is no longer used by the live flow on `journey_2026`: the Summer Program engine that wrote it is switched off, so the table is empty and nothing else reads it. It is still a production table, and TapApp would be the only writer. |
| Putting `tapapp` into the `frappe_tap` branch (R-46) | New code goes into the production app. |
| New indexes on `Submission`, `StudentContentLog` or `Student` (for the Gallery and "My projects") | They change production tables. Today these tables have no index on `student_id`, `assign_id` or `week`. |
| The new event (campaign) table and the new `EventEnrollment` table in `frappe_tap` (R-86) | They add new tables to the production app. They change none of the existing logic. We list them so you know. |
| New WhatsApp messages and links. This covers: the login link, the "submission pending" nudge (R-66), the "feedback is ready" link (R-16), and links added to the existing reminder, escalation and content messages | Each kind needs its own new WhatsApp template (see the table in `whatsapp-link-login.md`, "Glific"). The login message also needs a new Glific flow. They run on the same Glific account as the live WhatsApp program, and the feedback delivery job (`feedback_delivery`) in `frappe_tap` must send the links. WhatsApp must approve each template, and every template message costs money. |

Locking or removing the password and OTP calls (`check_phone`, `login_with_password`, `forgot_password_*`, `reset_password`) does **not** need approval. We checked: they are in the `tapapp` module (`tapapp_auth.py`), and no branch of `frappe_tap` has them. A similar file, `tap_lms/ca/api/auth/citizenship_auth.py`, is a different module and we do not change it.

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
| Events and campaigns (the banner, "Join" and the number of students taking part) | In v1 | **A new feature that we build as part of v1.** Events are not courses, so the course data cannot track them (R-86). |
| Photo and video submissions | In v1 | Section 4. Voice recording is later (R-10). |
| Points, level and projects from the server | In v1 | Section 9 |
| Saving each step to the server at once | In v1 | R-40 |
| Keeping steps when the connection drops | Later | In v1, when the device is offline, the app stops (decided in the review, R-71). Keeping steps for later is part of offline use. |
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
| Parent consent that can be withdrawn (roadmap, row 2.9: "required from 13 May 2027") | Later | This is a consent record, not a parent login. See O-12. |
| Reports sent to BigQuery | In v1 | App events go to BigQuery in the same format as the WhatsApp events. It does not need to be real time (O-18). |
| Glific web channel | Later | R-26, no date |
| iPhone | Not planned | The roadmap says not in year one |

Even though v1 is smaller, we should not block the roadmap. The login, the backend and the content must not be built only for the web app (see the principles above), and the numbers in the roadmap decide how much load testing we need (O-18).

## 2. What is not in v1

| Item | Status |
|---|---|
| Dark theme. The design shows a theme switch only as a hint. | Decided: not in v1 |
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
| R-5 | **Announcement banner and events:** TAP switches a banner on or off for an event (for example a summer program). It shows the event name, a countdown to the start or the end, what the student has to do, and a **Join** button. Join opens an overview and an "I want to take part" button. Everyone starts at the same day and time. For now the banner stays at the top of Home. A pop-up was suggested, because the banner takes space in the WhatsApp browser. | Decided (product team meeting): banner at the top for now. It can become a pop-up later, with some rework. The event feature is new and is built as part of v1: see R-86. Open: the event details, see O-2 |
| R-86 | **Tech:** Events are a new feature that we build **as part of v1**, in `frappe_tap`. **Events are standalone: they are not linked to a Course.** An event has a start and an end date, a video and a quiz. It can be a learning unit with the unit type `event`. Only **one event is active for a batch at a time**. A student's registration is kept in a new `EventEnrollment` record, similar to `ProgramEnrollment`, and it links the student to the event. It is separate from `ProgramEnrollment`, because events are not tied to a course or a batch's curriculum. The number on the banner ("12,480 students are taking part") is the count of `EventEnrollment` records for the event. Everyone starts at the same day and time. | Decided (review) |
| R-6 | **Gallery**: this week's activity with its timer and points, the student's own work (or an empty box with a "Share your work" button), a grid of other students' finished work ("From TAP students like you"; which students: R-85), "Load more", and a full-screen viewer that you swipe through. | Decided (in the Figma design). Which work is shown, and the check before it is shown: see R-85 and R-59. The designer says the Gallery design is still being shaped. |
| R-7 | **Me**: profile, level, points, "My projects this year", project feedback screens, edit profile, settings and switch profile. This replaces today's Passport and Profile screens. | Decided (in the Figma design). The data for "My projects" and feedback: see R-87. The skill chips are open: see O-4. |
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
| R-61 | The activity has **four steps: Watch, Make, Quiz, Results**, shown in a step bar. The header has a back button, the points and "Ask TAP". | Decided (in the Figma design). The step names are placeholders and may change. |
| R-62 | **Watch:** an intro screen with the TAP Buddy picture, "Hear again" and a "Watch" button, then a video card (play button and length), then a message about the points earned. The videos are on YouTube and about 10 minutes long. A video needs a connection and uses mobile data, and this is acceptable. | Decided (in the Figma design) |
| R-90 | **The app does not check that the student really watched the video.** The student says it is watched (for example with an "I watched it" button after the video), and the app saves that step. This is the same as the WhatsApp system today, which trusts the call from Glific with no player check. The +10 points for the video come at once (R-75). | Decided (review). The Figma has no such button: see F-7. |
| R-63 | **Make:** the student sends work. In v1 this is mainly a **photo or a video**. The design also has a text version and a voice version for later. The course decides which. Each shows what is needed ("1 photo needed") and the curriculum team's exemplars. | Decided (product team meeting). Voice is later (R-10). |
| R-64 | **Photo:** "Add my work" offers Camera, Photos or Files. The student sees a preview ("Check your work before sending") and a check that it is a photo, then "Send" or "Change file". A sending bar shows the progress. A file that is not a photo gives a friendly message and the student can try again. | Decided (in the Figma design) |
| R-65 | **Voice:** "Record my voice" shows a timer with Cancel and Stop, then a play-back with "Record again" and Send. The sent voice note is shown in the chat. | In the Figma design. Not in v1: voice is later (R-10). |
| R-66 | **"I'll do it later":** the student can skip Make and do the Quiz first. After the quiz the app asks again ("ready to share your work?"). "Not today" skips again. If the student leaves the app, a WhatsApp nudge says the submission is pending, and its link opens a "Welcome back" screen for the work. | Decided (product team meeting). Open: the rules, see O-20 |
| R-67 | **Quiz:** a question (text only in v1; a picture can come later if the curriculum team wants one), answer choices, right or wrong feedback with points, and a summary such as "4/5 correct". | Decided (in the Figma design) |
| R-91 | **Tech:** In `frappe_tap` the live quiz calls only **read** the questions. Nothing stores a quiz attempt, an answer or a score, and nothing limits time or retakes. `tapapp` therefore runs the quiz for the app. It sends one question at a time, checks each answer on the server, accepts answer N+1 only after answer N, and stores the attempt and every answer. The correct answer never reaches the browser: `get_quiz_question_details` returns it, so only our server calls it. There is no time limit and retakes are not limited, as today. | Decided (review) |
| R-92 | **Tech:** We make **no changes to the existing evaluation pipeline** (the plagiarism check and the AI feedback) in v1. Known behavior that stays as it is: (1) if the AI evaluation fails, the result is published as "Valid" with grade 0 ("technical issue, please resubmit"); (2) if the checking service cannot download a photo, it passes it on as "original" and drops the failure flag; (3) if it cannot open the file, it retries 3 times, then sends it to the dead letter queue, and nothing goes to the student or to `frappe_tap`; (4) nothing looks for submissions that never get feedback; (5) the checking service treats flat-colour or low-noise images (many drawings and screenshots) as possibly AI-generated and rejects them at 0.70 confidence, and it compares a photo's small fingerprint with all other students' submissions, across assignments, so original work could get 0 points and an "invalid" message. We judged this from the code and ran no images. **The app handles the first case itself:** it treats a result with **grade 0 or the "technical issue" text as not valid**, so the student gets 0 points and is asked to send corrected work (R-76). **No points are given in `frappe_tap` on this path, so `tapapp` can apply this rule without a conflict.** The app shows a "taking longer than expected" state when the feedback does not arrive (R-68). | Decided (review) |
| R-68 | **Results:** a short chat with TAP Buddy. First come the feedback messages, each with a speaker icon. Then TAP Buddy asks "Do you want to know your total points collected so far?", and the student taps the **"Yes" button**. Then a "YOU WON" card shows the activity points. The card **waits for the tap**: there is no timer. The tap only shows the points. The points are already given when the valid feedback arrives (R-75), so a student who never taps still gets them. The points in the header update **after the tap**, when the card shows them, so the reveal is not spoiled. (The product team can change this later.) The picture badge goes from 3/4 to 4/4 (R-69). Feedback is released later, on purpose, so children cannot race through the projects. A scheduled job starts the Glific feedback flow at 15:00, 16:30 and 21:00 IST for every submission whose feedback is ready. While waiting, the student sees "I'm looking at your work, please wait" and leaves the app. A friendly message with "Send again" shows when the work is not valid. | Decided (product team meeting). The trigger is a scheduled job: see O-28 |
| R-69 | **Today's picture:** a picture is revealed in 4 pieces, one for each step. A small badge on every screen shows 0/4 up to 4/4. The student sees the full picture after the Results step. | Decided (review): the pieces unlock as the designer described (video 1/4, work 2/4, quiz 3/4), and the **4th piece only after valid feedback**. |
| R-70 | **Ask TAP:** a help panel opens from "Ask TAP". In v1 it shows **prepopulated questions** that fit the step the student is on (for example "How do I take a photo of my work?"), answered from the knowledge bank. It has no text box and no microphone. An AI agent with a daily limit is for later (a small agent that calls an LLM API such as Gemini or OpenAI, which can change). | Decided (review) |
| R-71 | **No connection:** the app shows "I am not able to talk to you. Looks like you're offline" and a Retry button. The student cannot go on until the connection is back, and then continues from the same step. | Decided (review). The Figma design has the screen. The student cannot go on until the connection is back. |
| R-72 | An activity has a **deadline**, shown as a timer ("Ends in 2 days 15 hrs", in the Gallery and Home frames). A new activity is released **every Tuesday at 4 pm**. The team triggers it **by hand in Glific**, and the activity is the same for every student in a batch, and the deadline is **the next Tuesday at 4 pm**, so an activity lasts one week. The timer counts down to that time. The app also uses it to work out how long a submission can stay pending. Sharing the work earns +25 (R-75). | Decided (review). The weekly release is manual: see R-93. What happens after the deadline is open (O-20). |
| R-93 | **Tech:** The app learns which activity is current for its batch from a tiny file on the CDN, `current/<batch-id>.json` (see [content-spec.md](content-spec.md)). A **sync script** writes the file, and rewrites it only when it changes. It uses **the same logic as the WhatsApp content calls**: the current week from `Weekly Student Flow` (`get_student_current_week`), then the batch's `Learning Unit` for that week (`get_learning_units_by_week`). So the app and WhatsApp always show the same activity. The app reads it when Home opens, when the student returns to the app, and about every 5 minutes while Home is on screen. Each page adds a random delay to its timer and stops checking while it is hidden. When the file changes, the app shows the new activity and its timer without a reload. A closed app learns nothing until it is opened again, so the WhatsApp message (R-49) tells the student. Neither the Worker nor `frappe_tap` is called for this check. **To check with the lead developer:** that the team's manual weekly update is made in `Weekly Student Flow`. If it is made somewhere else, the sync script reads that place instead. | Decided (review) |
| R-73 | **Settings:** app language and account options. Messages are not read aloud automatically (R-17). **There is no theme switch in v1.** | Decided. The Settings items are placeholders and may change. There is no theme switch in v1. |
| R-74 | **Edit profile:** first name, last name, language, "Is a brother or sister also using TAP?", and the phone number (hidden in part, marked verified). | Decided (in the Figma design) |
| R-75 | **Points:** video +10, sharing the work +25, each correct quiz answer +1, correct submission +10. The first three come at once. **The +10 for a correct submission comes after the feedback, and only if the work is valid.** `tapapp` gives the points: nothing in `frappe_tap` does today (R-87). Until the feedback arrives, the project shows "Points will be provided after feedback". | Decided (review) |
| R-76 | If the work is **not valid** (wrong format, wrong work or unclear), the student gets 0 points, is told why, and is asked to **send corrected work**. The feedback tells the app whether the work is valid. Sending again is another call to `submit_artwork`. The call has no one-submission-a-week rule, so no change is needed in `frappe_tap`. | Decided (product team meeting) |
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
| F-7 | Watch step, after the video | No frame shows how the student says the video is watched (for example an "I watched it" button). The designer has to add it (R-90). |

## 4. Photos and voice recordings

| # | Requirement | Status |
|---|---|---|
| R-9 | A student can take a **photo or a video** of their work with the phone camera, or choose one from the phone, and submit it. | Decided (product team meeting). The video camera is not tested yet. |
| R-10 | A student can **record their voice** inside the app for voice-based projects, listen to it, record again, and submit it. | Later. Voice is not in v1 (decided in the review). |
| R-11 | **Tech:** If the student does not allow the camera or microphone, the app shows a clear message and says what to do next. The browser may not ask again after a refusal, so the message explains how to allow the camera or microphone in the phone settings, and the student comes back to the app. | Decided (review). |
| R-12 | **Tech:** Photos are made smaller on the phone and saved as JPEG before upload. This helps slow connections. The checking service has no size limit and no resize, and it cannot open HEIC photos. | Decided (review) |
| R-13 | **Tech:** A failed upload does not lose the work. The student can try again. | Decided (review) |
| R-14 | **Tech:** (For later, when voice comes.) The voice note must be in a format the whole pipeline accepts. Android phones record `webm/opus`. No service names `webm`, and the AI model receives the raw file, so we cannot be sure it accepts `webm`. We propose that the app converts the voice note to WAV or MP3 before sending. iPhone is not planned for year one in the roadmap. | Later |
| R-15 | The submitted photo or recording enters the **same evaluation process that WhatsApp uses today** (plagiarism check, AI feedback). | Decided (review) |
| R-16 | The evaluation feedback (text and audio) is **shown in the app**, in the Results step (R-68) and in "My projects". The student gets a **WhatsApp message with a link** that opens the feedback page directly, where the student can read it and listen to it. | Decided (client). The WhatsApp message with the link needs the product team's approval: see R-50 and O-28 |
| R-88 | **Tech:** **A student's own work** stays in GCS. The Worker checks that the student belongs to the signed-in phone, then gives the app a short-lived link to the file, made with the service account for the app (O-17). `frappe_tap` is not changed. **The Gallery** uses a copy in R2, made only after the feedback says the work is valid (R-59). The copies are kept in a separate place so we know which ones the Gallery can pick, and they are refreshed on a schedule so new work appears. We chose this (our own copy in R2 for the Gallery) and not a signed link made by `frappe_tap`. To check: the Worker can read the private GCS bucket securely (for example with S3-compatible HMAC keys of the service account, kept as Worker secrets) and can serve photos and videos. The retention and deletion rule for the copies is in O-12. | Decided (review) |

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

**Storage (decided):** submitted files stay in the current GCS buckets in v1. A move to Cloudflare R2 may come later. It would need changes in `frappe_tap`, `tap_plg` and `rag_service`, which only read GCS links today. The file the app uploads first only has to wait somewhere that `frappe_tap` can download from. `frappe_tap` then copies it into GCS, so `tap_plg` and `rag_service` see no difference. Where that waiting place is, and how the Worker creates the upload link, is open (O-17).

## 5. Spoken messages

| # | Requirement | Status |
|---|---|---|
| R-17 | The **fixed messages** of the standard flow template (greetings, instructions, button text) have **pre-generated audio files**, one for each message in each language. The student taps the speaker icon to hear the clip. Messages never play by themselves. | Decided |
| R-54 | The audio files are stored centrally with the content (R-18). Each file is linked to its message and its language, and has a version. If the message text changes, the file is marked as out of date. | Decided (review) |
| R-55 | If a message has no approved audio file in the student's language, the speaker icon is hidden. The app never plays a different language. | Decided (review) |
| R-56 | **Evaluation feedback audio** is generated for each student, as it is today. The student plays it in the app, from the feedback page (R-16). | Decided |
| R-57 | Messages that contain a student or course name are not pre-recorded. Their spoken text is written without the name. | Decided (review) |
| R-77 | The **curriculum team provides the audio clips**, one for each message in each language. | Decided (client) |

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
| R-18 | **Tech:** Courses, flows, pictures and audio are **downloaded from one central place**. They are not bundled inside the app. The file layout is proposed in [content-spec.md](content-spec.md). | Decided. The layout is open: see O-9. |
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

**v1 uses the app's own flow, with one standard template for all courses.** The chat steps (greeting, video, quiz, submission, results) are the same template for every course. The course supplies the details, such as unit names, videos and questions.

Later, the plan is to move the chat to Glific. The app would talk to Glific over a web connection, and Glific flows would drive the messages. Glific's web channel is not ready, and Glific has given no date. So **v1 does not depend on it**.

| # | Requirement | Status |
|---|---|---|
| R-26 | **v1:** the activity and onboarding chats run in the app, from **one standard flow template for all courses**. The Glific integration comes in v2 or later. | Decided |
| R-52 | The flow template and its text come from the central content (R-18), in each language. A new course does not need new code. In v1 we use **one standard flow for all content**. | Decided (review) |
| R-53 | **Tech:** The app keeps the chat logic behind a clear boundary, so the source of messages can later be swapped for Glific without rewriting the screens. | Decided (review) |
| R-27 | **v1:** a submission from the app follows the **same process as WhatsApp**. TAP's backend receives the assignment, the student and the submission through the existing `submit_artwork` call, which creates the submission record and starts the evaluation. The app never holds the server key. Our own server checks the student and makes the call. | Decided (client: same process as WhatsApp). The file upload: see R-89. Open: see O-17 |
| R-89 | **Tech:** For a photo or a video, `submit_artwork` takes a **link** that the server can download, together with the assignment id and the student id. Our server gives the app a **temporary upload link**, the app uploads the file, and our server calls `submit_artwork` with that link. For text, the submission is the text. The server downloads the whole file from the link (30 to 60 seconds, no size limit, no sign-in), so the link must work without a login. The student id (the `ST…` id) comes from our own records, never from a phone number typed by the student. The call has **no duplicate check and no idempotency key**, and every call makes a new primary submission, so our server must not send the same work twice. TAP will create a service account with read and write access to the submission bucket on GCS for the app, and the Worker uses it to upload and read the student's files. Voice is later (R-10). | Decided (review) |
| R-28 | **Tech:** **Later (Glific web channel):** our server creates a short login token for Glific for each student. It lives about 15 minutes and is renewed while the student uses the app. | Later |
| R-29 | **Tech:** **Later (Glific web channel):** when a student signs out, or a different student uses the same phone, the app ends the Glific session. | Later |
| R-30 | **Tech:** Points, progress and anything we show later (projects, feedback) are stored by us. This matters most with Glific, which may delete old messages after about two months. | Decided (review) |
| R-84 | The app **saves each student's chat conversation on the server** for later analysis. The student cannot see it. Later, Glific will keep its own history. | Decided (product team meeting). Retention: see O-12. |

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
| R-38 | **Tech:** Sending the same completion twice, for example after a bad connection, gives points only once. Nothing in `frappe_tap` does this today, because the live path stores no completions. `tapapp` does it, with an idempotency key for each step. | Decided |
| R-39 | **The server sets no weekly limit today, and we keep it that way.** Glific decides what comes next, and the team sets the batch's activity for the week by hand (R-93). The app follows the same pace: a new activity every Tuesday at 4 pm (R-72), and the next project opens only after valid feedback (R-83). The prototype's "2 units a week" goes away. | Decided (review) |
| R-40 | **Every step is saved to the server as soon as it happens** (video watched, quiz answered, work submitted). Nothing in `frappe_tap` stores these steps today, so `tapapp` stores them. The phone is not the main copy of progress. If the connection drops, the app stops at the offline screen (R-71), and the student continues from the same step after Retry. | Decided (review) |
| R-41 | The rules (points, limits, level names and thresholds) are settings on the server that can be changed. They are not fixed in the code. Points belong to the assignment or course. Limits and levels are server settings. | Decided. Open: who can change them, and for whom (see O-20). |
| R-48 | **One progress record for each child, shared by all channels** (WhatsApp, web app, later an installed app). A child who moves from one channel to another continues at the **same step**, not only with the same points. | Decided (client rule 1, and in the review): the record is `ProgramEnrollment` (with its submissions), with no second copy in the TapApp learner record. On `journey_2026` the Summer Program engine that filled it is switched off, so we treat it as an **empty table** and fill only the fields the app needs. The prototype has no real users, so no data is moved. Writing to it is a change to production data: see "Rules for our changes". |
| R-49 | WhatsApp stays on. It reaches children who have not moved to the app, and it tells a child that something is waiting (for example a new activity or feedback). The app does not depend on push messages. | Decided (client rule 2) |
| R-50 | A link in a WhatsApp message (for example the feedback link, R-16) opens the app on the right screen for the right child. The feedback link is a **signed magic link** that carries the student and the place to go. It logs the student in, so no earlier sign-in is needed (see A11 and A15 in `whatsapp-link-login.md`). Anyone who holds the link can open it, as with the login link. The link opens the **Results step** (Figma frames M-C24 to M-C27). | Decided (review) |
| R-51 | The weekly limit and the points count work done on **all channels** together. | Decided (review) |
| R-87 | **Tech:** The data for "My projects" and the feedback screens comes from `Submission` (the work, the feedback, valid or not, the date), the batch's current week (R-93), the points and steps that `tapapp` stores (R-40, R-75), and the course's assignments (project names and order). There are 6 projects a year. A new activity is assigned every Tuesday at 4 pm (R-72). The level (for example "Bronze Buddy, 120 / 400") is worked out in `tapapp` from the points, with the thresholds as settings (R-41). Today the levels are hard-coded in the prototype. | Decided (review) |

The WhatsApp system and the prototype app today keep progress in two different records. The product team's rule 1 says there must be one. We use `ProgramEnrollment`, and no second copy (R-48). The live WhatsApp flow stores almost no progress in `frappe_tap` (see `system-understanding.md`), so `tapapp` has to create it.

### Where does the progress come from? (`journey_2026` branch of `frappe_tap`)

We read the code on `journey_2026` branch of `frappe_tap`. The Summer Program engine that used to fill `ProgramEnrollment` is switched off, so the table is empty for the live flow. Streak and gems are not shown in the design, so the app does not need them.

| What the app needs | What exists today | Result |
|---|---|---|
| Points for video, quiz and submission | Nothing gives or stores points. `ProgramEnrollment` has point fields, but nothing fills them. | **New.** `tapapp` works out and stores the points (R-75). |
| Where the student is in the activity (video, quiz, work sent, feedback) | Nothing stores "video watched" or the quiz steps. `Submission` shows the work sent and the feedback state. | **New.** `tapapp` stores each step (R-40). |
| Quiz answers and score | Not stored. The live quiz calls only read. | **New.** `tapapp` stores the attempt and each answer (R-91). |
| The weekly limit | None on the server. Glific decides what comes next. | R-39. |
| The current week | The team sets one activity for a whole batch by hand each week (the Tuesday 4 pm release in Glific). `Weekly Student Flow` has a week for each student, but nothing in `frappe_tap` fills it. | The WhatsApp content calls read the week from this record, so the app reads it too, through the sync script (R-93). To check with the lead developer: the manual weekly update is made here. |
| Level ("Bronze Buddy", 120 / 400) | No level. `Student.level` is a difficulty (L1 to L3), not this level. The levels are hard-coded in the prototype app today. | **New.** Work it out in `tapapp` from the points, with thresholds in settings (R-41). |
| Skill chips ("I'm getting better at") | Only rubric rows on each `Submission` ("Content Knowledge", "Creativity"). | New or derived. Open (O-4). |
| "My projects this year" (3 of 6) and the path | The course's assignments (through `Course Level` and `Learning Unit`, by week) and the student's `Submission` records. | `tapapp` builds it by reading those records. |
| Deadline timer ("Ends in 2 days 15 hrs") | The release is manual. | Decided (review): the Tuesday 4 pm rule (R-72). What happens after the deadline is open (O-20). |
| Feedback, whether the work was valid, and the feedback audio | On `Submission`. | Read from `Submission`. |

Result: nothing on the live path tracks progress, so `tapapp` creates every progress record. The existing records give us the student, the content and the submissions.

## 10. Quality, devices and delivery

| # | Requirement | Status |
|---|---|---|
| R-42 | The app works in the **WhatsApp browser** on Android phones, with the mobile design. Desktop designs exist (1440 px), but v1 uses the mobile ones (375 px). There is no installed app in v1: the installed Android app comes later and will use the same login and backend, so they stay general. The designer makes both sizes and will add others if we ask. | Decided (product team meeting) |
| R-43 | **Tech:** The first screen appears quickly on a slow connection. The 7.6 MB loading animation (`tap-buddy-loader.gif`, used on the splash screen) is replaced by a small file. Smaller versions already exist in the project (MP4 1.5 MB, WebM 0.7 MB), but the app does not use them yet. The fonts are bundled in the app. Today the app downloads the Inter font from Google when it starts (package `google_fonts`), and no font file is included. | Decided (review) |
| R-44 | **Tech:** Errors show a clear message and a Retry button, not technical text. Prototype review: some screens show technical text (for example "Failed to load dashboard: AuthException") and some Retry buttons cannot fix the cause. The app already has a shared error screen with a Retry button. Every failing call must use it. | Decided (review) |
| R-45 | **Tech:** The app includes basic accessibility: labels for icons, big enough touch targets, and text that can scale. Prototype review: the code has no labels for screen readers, and about 18 tap areas (`GestureDetector` or `InkWell`) have sizes that nobody checked. In the Figma some tap targets look small (the speaker icons and the step circles). The tap area can be larger than the picture, so this needs no design change. | Not required for v1 (review). We do it in v1 if there is time. |
| R-46 | **Tech:** The backend code for the app (`tapapp`) is merged into the main development branch before delivery. | Decided |
| R-47 | **Tech:** Before real students use the app, the known security problems that touch the app are fixed in the parts we own (the Worker, `tapapp` and the app). Problems in the existing `frappe_tap` need the product team's approval: see "Rules for our changes". The problems themselves are listed in `production-readiness.md` (section 8) and `known-gaps.md` (S3, S13). They are for the tech team. The product team does not need to read them. | Decided |
| R-78 | **Tech:** The app must **not slow down the `frappe_tap` server**. Content comes from a CDN. Progress reads are cached for a short time and cleared when a step finishes. Writes are few (only meaningful steps) and safe to repeat. We load-test to the numbers in O-18 before launch. The cache is never a second source of truth. `frappe_tap` was designed for a 100,000-student target, and the roadmap expects 500,000 by July 2027, so the load test must cover that. The checking service (`tap_plg`) runs one process, and its photo comparison grows with the number of stored submissions. The AI feedback service (`rag_service`) handles one message at a time. Neither states a throughput target. | Decided (review) |
| R-80 | **Tech:** `tapapp` reads the content tables (`Course Level`, `Learning Unit`, the videos, quizzes and assignments) and the batch's current week (R-93). It does not use the Summer Program calls (`get_next_content`, `get_weekly_content`): they are switched off. Neither the app nor the Worker calls `ready_to_receive_feedback`. The feedback is requested when the work is submitted, and a scheduled job in `frappe_tap` starts the Glific feedback flow at 15:00, 16:30 and 21:00 IST (see O-28). | Decided (review) |
| R-81 | **Tech:** Our own server (the Worker) checks that the student belongs to the signed-in phone before every call to `frappe_tap`, because the production calls check nothing per student. | Decided |
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
| O-2 | **Event details.** Events are a new feature that we build **as part of v1** (R-86). What is still open: who switches the banner on and off, and where? What does the event overview show? If a student is in several batches, the latest batch (the latest date of joining) is the active batch: is that also the batch that decides which event the student sees? | `frappe_tap` has no event data and no event enrollment today. |
| O-4 | **Skills on the Me page:** the backend has no skills for each student (`Student.level` is empty and never computed. The only skill data are rubric rows on each `Submission`). Where should the skill chips ("I'm getting better at") come from? They would be new, worked out in `tapapp`. The designer only said that the Me page shows the skills the student is getting better at, next to the level picture. The TAP team is finding out (screen M-ME-01). | We cannot build the Me page without this data. |
| O-9 | **Central content:** the proposal is in [content-spec.md](content-spec.md). The curriculum team writes content in Frappe (the master copy). A Publish step builds versioned JSON files with a manifest and puts them in R2 behind a CDN. The app downloads them. Translations are owned by the curriculum team (Manu Agarwal is the contact), and the curriculum team publishes. Two points are open: (1) Does the curriculum team author in Frappe and the existing Google Sheets import, or in another tool? (2) Does the standard flow template live in git (our proposal) or in Frappe, so the team can edit messages without a developer? | The app needs one source, and the files need a fixed shape so that publish can check them. |
| O-10 | **Tech:** Merge: the whole development branch, or only the `tapapp` part? Should `tapapp` become its own backend app? | It changes the delivery effort. |
| O-11 | Which Android versions and phone models must work? (The roadmap says no iPhone in year one.) | It sets the list of test phones. |
| O-12 | How long do we keep photos and recordings, and how are they deleted? Is there an account deletion rule? | Child data. |
| O-13 | Which outside services may receive children's data? Today the AI feedback service sends each child's photo, voice recording and text, as raw files, to Google Vertex AI (Gemini). It filters no personal information, and it prints the prompts and results in its logs. Is this acceptable, and in which region does it run? TAP engineering (review): this is acceptable, because the models run in TAP's own private cloud accounts. Which models and which region: to be confirmed. | Data protection. The app adds no new service, but the volume will grow. |
| O-17 | **Tech:** **Valid or not valid.** The evaluation result must say clearly whether the work is valid, with a reason the student can read (R-76). The tech team will find out which service decides this (the roadmap names Kaapi) and whether it can return that answer. If it cannot, we will come back to the product team. | R-76 and R-83 need the app to know if the work is valid. |
| O-18 | **Size and reporting:** phase 1 is live for about **10,000 students**. The roadmap's 500,000 children by July 2027 is the long-term target. App events are saved in BigQuery in the **same format as the WhatsApp events**, not in real time (decided in the review). When does phase 1 start, and when does it grow? | The size decides how much load testing and reporting work we need. `frappe_tap` documents a 100,000-student design target. |
| O-20 | **Deadlines and "I'll do it later":** decided in the review: a new activity is assigned every Tuesday at 4 pm and the deadline is the next Tuesday at 4 pm (R-72), and the points are in R-75. Still open: what happens after the deadline? How long can a student leave work waiting? When a student sends corrected work, does it earn the full points? How many tries are allowed, and does the deadline still apply to the second try? Who can change these settings (points, limits, levels), and does a change apply to everyone or to one batch? The TAP team suggests that v1 uses the current WhatsApp behaviour for these rules, that is, the server sets no limit and Glific paces the content (R-39). | The designs show timers and points, but not the rules behind them. |
| O-27 | **Video submissions:** voice is for later (decided in the review), so v1 has photos and videos. A video is usually 30 to 90 seconds. How large may a video file be? | Video files are large and upload slowly on weak connections. We tested photo and voice on the phones, not the video camera. |
| O-28 | **App students and WhatsApp-only students:** one Glific "feedback" flow (id `41954`, set by `submit_artwork`) serves every student. The product team thinks at the **student** level: a student is either an app student or a WhatsApp-only student. The delivery job starts that flow. For an app student the flow must send "Your feedback is ready" with a signed link, and for a WhatsApp-only student it must send the feedback text as today. How should the flow tell them apart? **Option A:** the flow asks `tapapp` (a webhook) whether the student is an app student. If no, or if the webhook fails, it sends the message as today. **Option B:** after the app sends the work, `tapapp` sets the submission's `feedback_flow_id` to a new Glific flow for app students (a write to `Submission`, a production table). **How does a student become an app student?** We propose: the first time the student logs in with the WhatsApp link, `tapapp` records it. From then on the student gets the link for every submission. Is this acceptable? The flow also needs the student's Glific ID (the delivery job finds it from `Student.glific_id`, or by phone). | The flow is shared with WhatsApp-only students, so a change to it must not break their feedback. It needs the product team's approval. |

## 12. Risks and dependencies

- **Figma access.** We have images only. Exact styling needs edit access to the file.
- **Glific web channel.** It is a proposal with no date. v1 does not depend on it. If it arrives later, the message format and the rich widgets still need to be agreed.
- **Backend merge.** The `tapapp` branch and the main development branch have drifted far apart. The merge needs care and a test.
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
- If the connection drops, the app stops at the offline screen. After Retry, the student continues from the same step, and no progress is lost.
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
