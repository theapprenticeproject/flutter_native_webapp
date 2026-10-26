# TapApp v1: requirements for review

**Purpose.** This page lists what we plan to build for version 1 (v1) of the TapApp student web app. We want to agree on it with the product team before we build.

**Status of this page.** Draft for review. Nothing here is final until the product team confirms it.

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
- New backend work lives in `tapapp`. It may **read** `frappe_tap` data (for example `Student`, `ProgramEnrollment` and `Submission`). It changes production data only through existing `frappe_tap` calls that stay as they are, such as `save_submission`.
- We do not change existing `frappe_tap` calls, jobs or rules.

These items touch `frappe_tap` or the Glific flows it uses, so they need the product team's approval before we do them:

| Item | Why it touches `frappe_tap` |
|---|---|
| Making `save_submission` refuse calls that have no API key (R-47, O-17) | Today the call works with or without a key. Anyone who knows a student's id can send work for that student. Refusing calls without a key could break any Glific flow that does not send the key, so the client must approve it, and the flows must be checked first. |
| The WhatsApp message that tells the student to open the feedback page (R-16, O-21, O-28) | Reading and showing the feedback needs no change. The message is sent today by the existing feedback step, through one Glific flow (label "feedback") that all students share, including WhatsApp-only students. Adding a link means changing that flow, and maybe the data `frappe_tap` sends to it. That changes what those students get. |
| Letting a student send corrected work in the same week (R-76, O-22) | The one-submission-a-week rule is existing logic. |
| Any new write to `Student` or `ProgramEnrollment`, for example edit profile (R-74) | It changes production data. |
| Putting `tapapp` into the `frappe_tap` branch (R-46) | New code goes into the production app. |
| Changing how points follow the feedback, so that invalid work earns 0 (R-75) | Today points follow the plagiarism and AI-generated flags, not the valid verdict. |
| New indexes on `Submission`, `StudentContentLog` or `Student` (for the Gallery and "My projects") | They change production tables. Today these tables have no index on `student_id`, `assign_id` or `week`. |
| Creating signed links to submitted files (O-4) | The storage credentials are held only by `frappe_tap`. |
| New WhatsApp messages and links. This covers: the login link, the "submission pending" nudge (R-66), the "feedback is ready" link (R-16), and links added to the existing reminder, escalation and content messages | Each kind needs its own new WhatsApp template (see the table in `whatsapp-link-login.md`, "Glific"). The login message also needs a new Glific flow. They run on the same Glific account as the live WhatsApp program, and `pe_dispatcher` and `feedback_consumer` in `frappe_tap` must send the links. WhatsApp must approve each template, and every template message costs money. |
| A "could not review" result for failed AI runs, and opening or converting HEIC photos in the checking service (O-25) | They change how the existing pipeline reports failures. |

Locking or removing the password and OTP calls (`check_phone`, `login_with_password`, `forgot_password_*`, `reset_password`) does **not** need approval. We checked: they are in the `tapapp` module (`tapapp_auth.py`), and no branch of `frappe_tap` has them. A similar file, `tap_lms/ca/api/auth/citizenship_auth.py`, is a different module and we do not change it.

Reading is fine without approval. For example, `tapapp` can read the feedback and the valid or not valid result from `Submission` itself, so we do not have to change `get_submission_feedback`.

### Recommendations to the product team (not needed for the app)

These are our suggestions. The app does not depend on them. They would reduce risk in the existing system, and each one is a change in production, so it needs approval.

- **Limit `update_batch_week` and `admin_drop_student` to an admin role.** Today any caller with a login or key can advance a batch's week or drop a student. Our Worker's key could call them too, so a leaked key would be more dangerous.
- **Require an API key on `get_submission_feedback` and `ready_to_receive_feedback`.** Today they answer anyone who knows a submission id.
- **Turn on the watching of dead letter queues** that the system document describes (sections 16 and 17). We did not see it wired in `hooks.py`.

## How v1 relates to the TAP App roadmap

The TAP App's roadmap (`TAP_App_Roadmap_v3.xlsx`) is the **long-term vision**: three releases between January and July 2027, a web app **and** an Android app, and 500,000 children by July 2027 (1 million by March 2028). v1 is smaller. This table is our reading of how the roadmap maps to v1. Please correct it.

| Roadmap area | In v1? | Notes |
|---|---|---|
| Student web screens from the Figma | In v1 | Sections 3 and 4 |
| Photo and video submissions | In v1 | Section 4. Voice recording: open (O-27). |
| Points, level and projects from the server | In v1 | Section 9 |
| Saving each step to the server at once | In v1 | R-40 |
| Keeping steps when the connection drops | Proposed: not in v1 | Our proposal: when the device is offline, the app stops (R-71, O-16). The product team has to agree. |
| Full offline use (content on the phone) | Later | Roadmap Release 3, in the installed Android app |
| Voice both ways (read steps aloud, answer by voice) | In v1, in part | Fixed messages use pre-generated audio files (R-17). Feedback audio is generated as today (R-56). Answering by voice: see O-27. Read-aloud for text beyond the fixed template is open (O-1). |
| Showcase (the Gallery tab): finished work from the class and school | In v1 | Students' finished work (their photos of drawings and projects) can be shown, together with example images from the curriculum team. Needs a legal answer and a check before other students see it (O-3). |
| Login: teacher-created PIN accounts | Not in v1 | No teacher role in v1 |
| Child account with password and PIN, set up with parent consent (roadmap 1.1b) | Not in v1 | This is the installed-app and Play Store route. It is not a parent login. |
| Several profiles on one phone (like Netflix) | Open | See O-6 |
| Teacher role and screens (class setup, who has not finished, leaderboard) | Not in v1 | Decided: v1 uses the same student-only flow as WhatsApp |
| Android app (installed) | Later | v1 runs in the WhatsApp in-app browser (R-42). See O-15. |
| Adaptive levels, SwiftChat, parent scorecards | Later | |
| Help when stuck (AI chat) and the Ask TAP panel | Open | The Figma shows Ask TAP on every screen. The roadmap calls AI help an experiment for a limited group. See O-19. |
| Parent consent that can be withdrawn (roadmap, row 2.9: "required from 13 May 2027") | Open | This is a consent record, not a parent login. See O-12. |
| Reports sent to BigQuery | Open | See O-18 |
| Glific web channel | Later | R-26, no date |
| iPhone | Not planned | The roadmap says not in year one |

Even though v1 is smaller, we should not block the roadmap. The login, the backend and the content must not be built only for the web app (see the principles above), and the numbers in the roadmap decide how much load testing we need (O-18).

## 2. What is not in v1

| Item | Status |
|---|---|
| Dark theme. The design shows a theme switch only as a hint. | Decided: not in v1 |
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
| R-4 | **Home**: greeting, points, "Ask TAP", the announcement banner (R-5) and the activity cards. Each card shows the activity name, the points and a "Start activity" button. The card changes with the state: start, submission pending, send submission. | Decided (in the Figma design). In the meeting the designer said Home shows **two cards**, but the Figma frame shows one. Which two activities are shown is open: see O-30. |
| R-5 | **Announcement banner and events:** TAP switches a banner on or off for an event (for example a summer program). It shows the event name, a countdown to the start or the end, what the student has to do, and a **Join** button. Join opens an overview, an "I want to take part" button and a choice of when to start. For now the banner stays at the top of Home. A pop-up was suggested, because the banner takes space in the WhatsApp browser. | Decided (product team meeting): banner at the top for now. Open: the switch and the event data, see O-2 |
| R-6 | **Gallery**: this week's activity with its timer and points, the student's own work (or an empty box with a "Share your work" button), a grid of other students' finished work ("From TAP students like you"; which students: R-85), "Load more", and a full-screen viewer that you swipe through. | Decided (in the Figma design). Which work is shown, and the check before it is shown: see R-85, R-59 and O-3. |
| R-7 | **Me**: profile, level, points, "My projects this year", project feedback screens, edit profile, settings and switch profile. This replaces today's Passport and Profile screens. | Decided (in the Figma design). The data for "My projects" and feedback is open: see O-4. |
| R-8 | The look follows the Figma design: colors, fonts, spacing and shared parts such as buttons, chips and the header. | Decided (in the Figma design). The accent color (purple now) may change to green: not decided. |
| R-58 | The curriculum team's **exemplar works** for each assignment (what a good submission looks like) are part of the central content (R-18), stored in the CRM. They are not other students' work. They are shown in the Make step, and they can seed the Gallery at first. | Decided (product team meeting) |
| R-59 | A student's finished work is shown to other students only after it has passed a check. Who checks it, and how, is open. Proposal: Only pictures and videos are shown. Text and voice work stays in the student's own "My projects". | Proposed. Open: see O-3 |
| R-85 | Which students' work the Gallery shows (same grade, school, district, cluster or all of India) is a **setting**, because TAP wants to test different choices through the year. The Gallery shows each work with the student's **first name only** until legal counsel answers O-3 (the first draft showed the full name). If there is no work yet, the curriculum team's examples fill it. | Proposed (from the meeting). See O-3 |
| R-60 | The app shows no photos of the students themselves. The TAP Buddy picture is used where a profile picture would go. | Decided |

We have only exported images of the Figma file. We do not have edit access yet, so exact colors, fonts and sizes are read from images. We will check them in Figma once we have access.

### The activity flow in the Figma

The Figma "Class" frames show the activity flow in detail. These requirements come from reading those frames.

| # | Requirement | Status |
|---|---|---|
| R-61 | The activity has **four steps: Watch, Make, Quiz, Results**, shown in a step bar. The header has a back button, the points and "Ask TAP". | Decided (in the Figma design). The step names are placeholders and may change. |
| R-62 | **Watch:** an intro screen with the TAP Buddy picture, "Hear again" and a "Watch" button, then a video card (play button and length), then a message about the points earned. | Decided (in the Figma design) |
| R-63 | **Make:** the student sends work. In v1 this is mainly a **photo or a video**. The design also has a text version and a voice version for later. The course decides which. Each shows what is needed ("1 photo needed") and the curriculum team's exemplars. | Decided (product team meeting). Voice: see O-27. |
| R-64 | **Photo:** "Add my work" offers Camera, Photos or Files. The student sees a preview ("Check your work before sending") and a check that it is a photo, then "Send" or "Change file". A sending bar shows the progress. A file that is not a photo gives a friendly message and the student can try again. | Decided (in the Figma design) |
| R-65 | **Voice:** "Record my voice" shows a timer with Cancel and Stop, then a play-back with "Record again" and Send. The sent voice note is shown in the chat. | In the Figma design. Open: is voice in v1? See O-27. |
| R-66 | **"I'll do it later":** the student can skip Make and do the Quiz first. After the quiz the app asks again ("ready to share your work?"). "Not today" skips again. If the student leaves the app, a WhatsApp nudge says the submission is pending, and its link opens a "Welcome back" screen for the work. | Decided (product team meeting). Open: the rules, see O-20 |
| R-67 | **Quiz:** a question with an optional picture, answer choices, right or wrong feedback with points, and a summary such as "4/5 correct". | Decided (in the Figma design) |
| R-68 | **Results:** feedback messages from TAP Buddy, each with a speaker icon. Feedback is released about **12 hours** after the work is sent, on purpose, so children cannot race through the projects. While waiting, the student sees "I'm looking at your work, please wait" and leaves the app. A friendly message with "Send again" shows when the work is not valid. | Decided (product team meeting). Who holds the feedback for 12 hours: see O-21 |
| R-69 | **Today's picture:** a picture is revealed in 4 pieces, one for each step. A small badge on every screen shows 0/4 up to 4/4. The student sees the full picture after the Results step. | Open: when the work's piece unlocks. The designer: when the work is shared (video 1/4, work 2/4, quiz 3/4, results after the feedback 4/4). The TAP team: after the feedback. See O-20. |
| R-70 | **Ask TAP:** a help panel opens from "Ask TAP". It shows questions that fit the step the student is on (for example "How do I take a photo of my work?"), answered from the knowledge bank. The student can also ask an AI agent, with a limit on questions each day. Later, Ask TAP may become a call from an AI agent. | Decided (product team meeting). Open: the limit and the cost, see O-19 |
| R-71 | **No connection:** the app shows "I am not able to talk to you. Looks like you're offline" and a Retry button. The student cannot go on until the connection is back, and then continues from the same step. | In the Figma design. That the student cannot go on is our proposal: see O-16. |
| R-72 | An activity has a **deadline**, shown as a timer ("Ends in 2 days 15 hrs", in the Gallery and Home frames, and mentioned by the designer in the meeting). Work shared before the deadline earns points (+25 in the design). | Open: no document says how long an activity lasts or what happens after the deadline. See O-20. |
| R-73 | **Settings:** app language, "Read messages aloud" (off by default), and account options. **There is no theme switch in v1.** | Decided. The Settings items are placeholders and may change. There is no theme switch in v1. |
| R-74 | **Edit profile:** first name, last name, language, "Is a brother or sister also using TAP?", and the phone number (hidden in part, marked verified). | Decided (in the Figma design) |
| R-75 | **Points for the submitted work come after the feedback, and only if the work is valid.** Points for the video and the quiz come at once. Until the feedback arrives, the project shows "Points will be provided after feedback". No Figma frame shows this yet (F-6). | Decided. Today's WhatsApp rules work differently: see "Rules for our changes", O-22 and O-25. |
| R-76 | If the work is **not valid** (wrong format, wrong work or unclear), the student gets 0 points, is told why, and is asked to **send corrected work**. The feedback tells the app whether the work is valid. | Decided (product team meeting). New behavior: the WhatsApp system has no "send again". See O-22. |
| R-83 | The **next project opens only after the feedback for the previous one is valid.** If it is not valid, the student sees the feedback and must send corrected work first. After valid feedback, the student can go straight to the next project. | Decided (product team meeting) |

### Figma frames that need correcting

We found these when we compared the Figma design with the decisions above. Please ask the designer to correct them.

| # | Frame | Problem |
|---|---|---|
| F-1 | Make or Quiz step, after the work is sent: "Congratulations Aarav! +25 points" | Points for the work come after feedback (R-75). The frame shows them at once. |
| F-2 | Results step: "Hi Champ, I looked at the work you sent me!" and the other feedback messages | Feedback arrives up to 12 hours later (R-68). The live flow should show "still checking" and leave. The feedback messages belong on the feedback page that the WhatsApp link opens (R-16). The Results step starts when the student opens that link. |
| F-3 | Bottom bar in the Home, Gallery and Event frames | They show a "Class" tab. The bar has only Home, Gallery and Me (R-1). |
| F-4 | Settings: Theme (Default, Light, Dark) | There is no theme switch in v1 (R-73). |
| F-5 | Quiz and results frames: points such as "+15 points" for a correct answer and "earned 5 points in total" | The numbers do not agree with each other. Please confirm the point rules (O-20). |
| F-6 | The project card and "My projects", while the student waits for feedback | No frame shows the waiting state. The app shows "Points will be provided after feedback" (R-75). The designer has to add it. |

## 4. Photos and voice recordings

| # | Requirement | Status |
|---|---|---|
| R-9 | A student can take a **photo or a video** of their work with the phone camera, or choose one from the phone, and submit it. | Decided (product team meeting). The video camera is not tested yet. |
| R-10 | A student can **record their voice** inside the app for voice-based projects, listen to it, record again, and submit it. | Open: the designer said voice comes in a future version. See O-27. |
| R-11 | **Tech:** If the student does not allow the camera or microphone, the app shows a clear message and says what to do next. | Proposed |
| R-12 | **Tech:** Photos are made smaller on the phone and saved as JPEG before upload. This helps slow connections. The checking service has no size limit and no resize, and it cannot open HEIC photos. | Proposed |
| R-13 | **Tech:** A failed upload does not lose the work. The student can try again. | Proposed |
| R-14 | **Tech:** If voice is in v1 (O-27), the voice note must be in a format the whole pipeline accepts. Android phones record `webm/opus`. No service names `webm`, and the AI model receives the raw file, so we cannot be sure it accepts `webm`. We propose that the app converts the voice note to WAV or MP3 before sending. iPhone is not planned for year one in the roadmap. | Proposed. Open: see O-17 |
| R-15 | The submitted photo or recording enters the **same evaluation process that WhatsApp uses today** (plagiarism check, AI feedback). | Proposed |
| R-16 | The evaluation feedback (text and audio) is **shown in the app**, in the Results step (R-68) and in "My projects". The student gets a **WhatsApp message with a link** that opens the feedback page directly, where the student can read it and listen to it. | Decided (client). The WhatsApp message with the link needs the product team's approval: see O-21 and O-28 |

Today, the prototype does not upload photos or videos. It marks them as passed. It records no voice, only a typed answer. Both must be fixed for v1.

### How a submission travels

**Today (WhatsApp):**

WhatsApp, then Glific, then `frappe_tap` (`save_submission`), then RabbitMQ, then `tap_plg` (plagiarism check), then RabbitMQ, then `rag_service` (AI feedback), then RabbitMQ, then `frappe_tap` (saves the feedback, makes the audio, gives the points), then Glific, then a WhatsApp message to the student.

**With the app in v1:**

1. The student sends the work in the app. The file goes to our storage, and our server (the Worker) checks the student.
2. Our server calls `save_submission` in `frappe_tap`, unchanged, with a link to the file.
3. From here the pipeline is the same as for WhatsApp: `frappe_tap` downloads the file into its own storage, then `tap_plg`, then `rag_service`, then back to `frappe_tap`.
4. When the feedback is ready, the existing feedback step tells Glific. Glific sends a WhatsApp message. For a submission from the app, the message has a link to the app and not the feedback text. WhatsApp-only students get the message as today (needs the product team's approval, R-16, O-21, O-28).
5. The student opens the link. The app reads the student's feedback from `frappe_tap` through our server.

Steps 1, 2 and 5 are new code in the app, the Worker and `tapapp`. Steps 3 and 4 are existing production code.

**Storage (decided):** submitted files stay in the current GCS buckets in v1. A move to Cloudflare R2 may come later. It would need changes in `frappe_tap`, `tap_plg` and `rag_service`, which only read GCS links today. The file the app uploads first only has to wait somewhere that `frappe_tap` can download from. `frappe_tap` then copies it into GCS, so `tap_plg` and `rag_service` see no difference. Where that waiting place is, and how the Worker creates the upload link, is open (O-17).

## 5. Spoken messages

| # | Requirement | Status |
|---|---|---|
| R-17 | The **fixed messages** of the standard flow template (greetings, instructions, button text) have **pre-generated audio files**, one for each message in each language. The student taps the speaker icon to hear the clip. | Decided |
| R-54 | The audio files are stored centrally with the content (R-18). Each file is linked to its message and its language, and has a version. If the message text changes, the file is marked as out of date. | Proposed |
| R-55 | If a message has no approved audio file in the student's language, the speaker icon is hidden. The app never plays a different language. | Proposed |
| R-56 | **Evaluation feedback audio** is generated for each student, as it is today. The student plays it in the app, from the feedback page (R-16). | Decided |
| R-57 | Messages that contain a student or course name are not pre-recorded. Their spoken text is written without the name. | Proposed |
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
| R-18 | **Tech:** Courses, flows, pictures and audio are **downloaded from one central place**. They are not bundled inside the app. | Decided |
| R-19 | **Tech:** Each piece of content has a **version**. The app checks the version and downloads what changed. | Proposed |
| R-20 | **Tech:** A small first-run copy stays in the app, so the first visit still works with a weak connection. | Proposed |
| R-21 | **Tech:** If the content changes while a student is in the middle of a unit, the student finishes that unit on the old copy. | Proposed |
| R-22 | **Tech:** If a download fails, the student sees a clear message and can try again. | Proposed |
| R-23 | Languages: English, Hindi, Marathi, Kannada, Punjabi. The learner's language comes from their profile. | Proposed |
| R-24 | **Tech:** The app text is translated. Today almost all text is written in English in the code. | Proposed |
| R-25 | **Tech:** Names such as "Champ" (used when a name is missing) become one translated fallback text. | Proposed |
| R-79 | **Tech:** When a unit opens, the app loads all of that unit's small files first (text, quiz, pictures, example images, audio clips), so the steps start quickly. Videos always need a connection. | Proposed |

Today the app has 17 MB of bundled files. Four of the five course languages are bundled but never used.

## 7. Conversations: v1 and the later Glific web channel

**v1 uses the app's own flow, with one standard template for all courses.** The chat steps (greeting, video, quiz, submission, results) are the same template for every course. The course supplies the details, such as unit names, videos and questions.

Later, the plan is to move the chat to Glific. The app would talk to Glific over a web connection, and Glific flows would drive the messages. Glific's web channel is not ready, and Glific has given no date. So **v1 does not depend on it**.

| # | Requirement | Status |
|---|---|---|
| R-26 | **v1:** the activity and onboarding chats run in the app, from **one standard flow template for all courses**. | Decided |
| R-52 | The flow template and its text come from the central content (R-18), in each language. A new course does not need new code. | Proposed |
| R-53 | **Tech:** The app keeps the chat logic behind a clear boundary, so the source of messages can later be swapped for Glific without rewriting the screens. | Proposed |
| R-27 | **v1:** a submission from the app follows the **same process as WhatsApp**. TAP's backend receives the assignment, the student and the submission through the existing `save_submission` call, which creates the submission record and starts the evaluation. The app never holds the server key. Our own server checks the student and makes the call. | Decided (client: same process as WhatsApp). Open: see O-17 and O-22 |
| R-28 | **Tech:** **Later (Glific web channel):** our server creates a short login token for Glific for each student. It lives about 15 minutes and is renewed while the student uses the app. | Later |
| R-29 | **Tech:** **Later (Glific web channel):** when a student signs out, or a different student uses the same phone, the app ends the Glific session. | Later |
| R-30 | **Tech:** Points, progress and anything we show later (projects, feedback) are stored by us. This matters most with Glific, which may delete old messages after about two months. | Proposed |
| R-84 | The app **saves each student's chat conversation on the server** for later analysis. The student cannot see it. Later, Glific will keep its own history. | Decided (product team meeting). Retention: see O-12. |

Glific describes the web channel as a **proposal**. The message format may change. Rich parts of our design, such as the video player, quiz cards and step bar, do not have a message type yet. We would need to agree with Glific how each one is carried. This does not block v1.

## 8. Students, phones and login

| # | Requirement | Status |
|---|---|---|
| R-31 | A student can only see and change the profiles of the children **on the signed-in phone**. | Decided. Open: which of them can open each other's profile (O-6). |
| R-32 | **v1 has no teacher role and no parent access.** The student uses the same student-only flow as WhatsApp. The student signs in through a WhatsApp link that carries the **phone**. The app then shows the children of that phone, and the student picks their name (the Figma "Who is learning"). The roadmap's account with a password and PIN is a later route for the installed app. The sign-in must not let a student reach another student's data. | Decided: no teacher, no parent access, WhatsApp link with a name picker. Open: PIN, see O-6 |
| R-33 | **Tech:** The app never signs a student in because of a phone number that the student types. The phone for a login comes only from the WhatsApp link or from the `Student` record. (A typed number may only ask for a new link. The link goes to that number's WhatsApp, so it proves nothing about the person who typed it.) The link itself proves that the person has that WhatsApp number, so v1 needs no other check, such as an OTP. | Proposed |
| R-34 | One phone can have **several children** (for example brothers and sisters who share one phone). The student can switch profile without signing in again. | Decided (the Figma has "Who is learning" and "Switch profile"). Open: does switching need a PIN, and how the app finds all the children of one phone (see O-6) |
| R-35 | The app has a visible **Sign out**. It clears the child's data from the phone. | Proposed |
| R-36 | The design shows "Deactivate account" and "Delete account". They must really work, or be removed from v1. | Open |

## 9. Progress, points and rules

| # | Requirement | Status |
|---|---|---|
| R-37 | The server is the source of truth for points, level and the weekly limit. The app does not decide them. | Decided |
| R-38 | **Tech:** Sending the same completion twice, for example after a bad connection, gives points only once. This is how the WhatsApp flow works today. | Decided |
| R-39 | The weekly limit is a **server setting**. The app reads it from the server and never fixes it in the code. An operator can change it for a week. The prototype's "2 units a week" goes away. | Decided. Open: does the app keep the week cap at all? See O-29. |
| R-40 | **Every step is saved to the server as soon as it happens** (video watched, quiz answered, work submitted). The phone is not the main copy of progress. If the connection drops, the app stops at the offline screen (R-71), and the student continues from the same step after Retry. | Decided. The offline rule is a proposal: see O-16. |
| R-41 | The rules (points, limits, level names and thresholds) are settings on the server that can be changed. They are not fixed in the code. Points belong to the assignment or course. Limits and levels are server settings. | Decided. Open: who can change them, and for whom (see O-20). |
| R-48 | **One progress record for each child, shared by all channels** (WhatsApp, web app, later an installed app). A child who moves from one channel to another continues at the **same step**, not only with the same points. | Decided (client rule 1). The record: the TAP team proposes the WhatsApp system's `ProgramEnrollment`, because app students share its flow and logic. See O-8. |
| R-49 | WhatsApp stays on. It reaches children who have not moved to the app, and it tells a child that something is waiting (for example a new activity or feedback). The app does not depend on push messages. | Decided (client rule 2) |
| R-50 | A link in a WhatsApp message (for example the feedback link, R-16) opens the app on the right screen for the right child. The link must not let anyone else open that child's feedback. | Decided for the feedback link (client). The link design is open: see O-21 |
| R-51 | The weekly limit and the points count work done on **all channels** together. | Proposed |

The WhatsApp system and the prototype app today keep progress in two different records. The product team's rule 1 says there must be one. We propose the WhatsApp system's `ProgramEnrollment`, and no second copy, if it can hold what the app needs (see O-8 in section 11).

### Can ProgramEnrollment hold the progress? (first check)

We compared the fields of `ProgramEnrollment` in `frappe_tap` with what the Figma shows. We read the field list and, for points and the weekly limit, the rules in the code (on `pal-v2-health`, not checked live). Streak and gems exist in the WhatsApp system, but the design no longer shows them, so the app does not need them.

| What the app needs | What ProgramEnrollment has today | Result |
|---|---|---|
| Total points, and points for video, quiz and submission, and for this week | `total_points`, `total_activity_points`, `total_quiz_points`, `total_submission_points`, `bonus_quiz_points`, and a weekly field for each | Yes |
| Streak | `current_streak` | Not shown in v1: the design removed streaks. It stays in the WhatsApp system. |
| Gems | `special_gems` | Not shown in v1: the design removed skill gems. It stays in the WhatsApp system. |
| Where the student is in the activity (video, quiz, work sent, feedback) | `journey_label`, `weekly_video_done`, `weekly_submission_done`, `resolved_flow_state`, and `StudentQuizAttempt` for the quiz | Mostly. The code never sets `quiz_completed`, so the quiz state comes from `StudentQuizAttempt`. "Make later" has no field of its own. It is worked out: the video is done, and the work is not sent. |
| The weekly limit | `current_week`, `max_allowed_week`, and the weekly flags | **Different** (confirmed in the code). The prototype's "2 units a week" does not exist here. The WhatsApp system has one video, one quiz and one submission for each week, and a week limit (`max_allowed_week`). R-39 follows this. |
| Level ("Bronze Buddy", 120 / 400) | No level field. `Student.level` exists but is empty and never computed. There is no "Bronze" or "Silver" anywhere in the code. | New: work it out in `tapapp` from `total_points`, with thresholds in settings (R-41). |
| Skill chips ("I'm getting better at") | Not on ProgramEnrollment. `skill_proficiencies` is never written. Only rubric rows on each `Submission` exist ("Content Knowledge", "Creativity"). | New or derived. Open (O-4). |
| "My projects this year" (3 of 6) and the path | Not on ProgramEnrollment. The list of projects comes from the course's assignments (linked through the course level and the week). Their status comes from the student's `Submission` records. There is no ready-made call for it. | `tapapp` builds it by reading those records. |
| Deadline timer ("Ends in 2 days 15 hrs") | `next_action_at`, `grace_window_end_at` and batch dates | Unknown (O-20). |
| Feedback, whether the work was valid, and the feedback audio | On `Submission` (status, result, feedback text, audio link), not on ProgramEnrollment | Read from `Submission`. |

Result: most of what the app needs is already there. The gaps are the level, the skills, the project path, the deadline, and the meaning of the weekly limit. If these are worked out from existing records, no second progress record is needed.

## 10. Quality, devices and delivery

| # | Requirement | Status |
|---|---|---|
| R-42 | The app works in the **WhatsApp browser** on Android phones, with the mobile design. Desktop designs exist (1440 px), but v1 uses the mobile ones. | Decided (product team meeting) |
| R-43 | **Tech:** The first screen appears quickly on a slow connection. The 7.6 MB loading animation (`tap-buddy-loader.gif`, used on the splash screen) is replaced by a small file. Smaller versions already exist in the project (MP4 1.5 MB, WebM 0.7 MB), but the app does not use them yet. The fonts are bundled in the app. Today the app downloads the Inter font from Google when it starts (package `google_fonts`), and no font file is included. | Proposed |
| R-44 | **Tech:** Errors show a clear message and a Retry button, not technical text. Prototype review: some screens show technical text (for example "Failed to load dashboard: AuthException") and some Retry buttons cannot fix the cause. The app already has a shared error screen with a Retry button. Every failing call must use it. | Proposed |
| R-45 | **Tech:** The app includes basic accessibility: labels for icons, big enough touch targets, and text that can scale. Prototype review: the code has no labels for screen readers, and about 18 tap areas (`GestureDetector` or `InkWell`) have sizes that nobody checked. In the Figma some tap targets look small (the speaker icons and the step circles). The tap area can be larger than the picture, so this needs no design change. | Proposed |
| R-46 | **Tech:** The backend code for the app (`tapapp`) is merged into the main development branch before delivery. | Decided |
| R-47 | **Tech:** Before real students use the app, the known security problems that touch the app are fixed in the parts we own (the Worker, `tapapp` and the app). Problems in the existing `frappe_tap` need the product team's approval: see "Rules for our changes". The problems themselves are listed in `production-readiness.md` (section 8) and `known-gaps.md` (S3, S13). They are for the tech team. The product team does not need to read them. | Decided |
| R-78 | **Tech:** The app must **not slow down the `frappe_tap` server**. Content comes from a CDN. Progress reads are cached for a short time and cleared when a step finishes. Writes are few (only meaningful steps) and safe to repeat. We load-test to the numbers in O-18 before launch. The cache is never a second source of truth. `frappe_tap` was designed for a 100,000-student target, and the roadmap expects 500,000 by July 2027, so the load test must cover that. The checking service (`tap_plg`) runs one process, and its photo comparison grows with the number of stored submissions. The AI feedback service (`rag_service`) handles one message at a time. Neither states a throughput target. | Proposed |
| R-80 | **Tech:** The app never calls the `frappe_tap` calls that change state when read (`get_next_content`, `get_weekly_content`). `tapapp` reads the tables instead. The one state-changing call it must make is `ready_to_receive_feedback`, once for each submission, about 12 hours after it is sent (see O-21). | Decided |
| R-81 | **Tech:** Our own server (the Worker) checks that the student belongs to the signed-in phone before every call to `frappe_tap`, because the production calls check nothing per student. | Decided |
| R-82 | **Tech:** **The key for `frappe_tap` lives only in the Worker**, as a secret. The app and the browser never see it, and the app never calls `frappe_tap` directly. Every call to `save_submission`, `ready_to_receive_feedback` and the read methods is made by the Worker. The app talks only to the Worker, with the student's own login. Files go to our storage through a short-lived upload link that the Worker creates. | Decided (TAP team) |

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
| O-1 | Fixed messages use pre-generated audio files in v1. The curriculum team provides the clips (decided). Who translates the scripts, which languages are in v1, and how does the team hand over the files (format, file names and where to put them)? Does any text beyond the fixed template need audio? The Figma puts a speaker icon on the assignment text and on the feedback messages, and they are not fixed messages. The "Read messages aloud" setting would also need audio to start by itself, which phone browsers often block until the student taps. | Recording is the largest effort in this area. |
| O-2 | Announcement banner and events: TAP switches the banner on and off. Where do the switch and the event data live? The strip "12,480 students across India are taking part" is the **number of students enrolled in the event**. It must be counted from the real enrollments, not typed in. "Take part" enrolls the student in that event. What does the day choice (Today, Tomorrow, Saturday, Sunday) do? | `frappe_tap` has no event data and no event enrollment today. |
| O-3 | Gallery: the Figma shows work from students in the same class level and activity, across schools, and a "Share your work" button that earns points. Is that right? The product team wants to test other choices (school, district, cluster, all of India) through the year, and to fill the Gallery with curriculum examples at first. Who checks the work before it is shown? Does the consent that families already gave (for example on WhatsApp) cover showing a student's submitted work, and the student's name, to other students? Please ask your legal counsel. The Gallery makes sense for pictures and videos. We propose that text and voice work is **not** shown in the Gallery. It stays in the student's own "My projects". Is that right? **Until legal counsel answers, we show only the first name, or no name, with each work.** | Child privacy and safety. This matters for v1, because the Gallery shows finished work. |
| O-4 | **Tech****Question 1: where does the data come from?** Data for "My projects" and the feedback screens to come from: `Submission` (the work, the feedback, valid or not, the date), `ProgramEnrollment` (the week and the points) and the course's assignments (project names and order).<br><br>**Question 2: years and batches.** There are 6 projects a year (confirmed). We understand that each year is a new Program, with batches and schools in it, and that a student's year follows from their batch. The dates are on the batch (start date, end date, number of weeks), not on the Program. Is that right? Do the 6 projects match the weeks or the assignments of the batch?<br><br>**Question 3: level and skills.** The backend has no level and no skills for each student (`Student.level` is empty and never computed. The only skill data are rubric rows on each `Submission`). Where should the level ("Bronze Buddy, 120 / 400") and the skill chips ("I'm getting better at") come from? They would be new, worked out in `tapapp`. The designer only said that the Me page shows the skills the student is getting better at, next to the level picture.<br><br>**Tech****Question 4: showing the student's own work again.** Submitted photos and voice notes are in the "Authenticated" bucket under a plain `storage.googleapis.com` link with no signature, so the app probably cannot open them. The feedback audio is in the public bucket, so the app can play it. How should the app show the work again (in "My projects", the feedback screens and the Gallery)?<br>• **Option A:** `frappe_tap` makes a temporary signed link when the app asks.<br>• **Option B:** we keep a copy in our own storage (R2). We propose B. The Worker copies a work into R2 when it is valid and may be shown, for example after the feedback. It refreshes the copies on a schedule, so new work appears. Only work that meets a set rule is copied (the rule is in O-3 and O-12). | We cannot build screens without data. A is cleaner, but a signed link needs the storage credentials that only `frappe_tap` holds (needs approval). B needs the retention and deletion rule (O-12), and it stores children's work twice. |
| O-6 | Several children on one phone: after the student picks a name, can any child on that phone open any brother's or sister's profile with one tap, as the Figma shows, or should a PIN be needed? Anyone who holds the link, or the phone, can see all the children of that phone. Is that acceptable? **Owner: product team. We need the answer before we build the name picker.** | A child's progress must not be reachable by a sibling (R-31). A PIN is planned for a later version. For the later Glific web channel, Glific may treat the second child as a separate person without history. |
| O-9 | Where is central content stored, who owns translations, and who publishes changes? | The app needs one source. |
| O-10 | **Tech:** Merge: the whole development branch, or only the `tapapp` part? Should `tapapp` become its own backend app? | It changes the delivery effort. |
| O-11 | Which Android versions and phone models must work? (The roadmap says no iPhone in year one.) | It sets the list of test phones. |
| O-12 | How long do we keep photos and recordings, and how are they deleted? Is there an account deletion rule? | Child data. |
| O-13 | Which outside services may receive children's data? Today the AI feedback service sends each child's photo, voice recording and text, as raw files, to Google Vertex AI (Gemini). It filters no personal information, and it prints the prompts and results in its logs. Is this acceptable, and in which region does it run? | Data protection. The app adds no new service, but the volume will grow. |
| O-16 | **Proposed (TAP team):** when the phone is offline, the app stops the student's progress and shows the offline screen with a Retry button. No step is kept on the phone to be sent later. Please confirm. | Some steps work offline and some do not, and that would confuse children. Progress must follow the child between WhatsApp and the app (R-48), so the server must always hold the latest step. |
| O-17 | **Tech** **Question 1: how the file reaches `save_submission`.** Submissions follow the same process as WhatsApp (decided): the existing `save_submission` call with the assignment id, the student id and the submission. For text, the submission is the text. For a photo or a voice recording, the call needs a **link** that the server can download (we confirmed this in the code). We propose: our server gives the app a temporary upload link, the app uploads the file, and our server calls `save_submission` with the link. Is that right?<br><br>**What we know about the link.** The server downloads the whole file from the link (30 to 60 seconds, no size limit, no sign-in), so the link must work without a login. It decides the type from the file extension first, so a browser voice note named `.webm` would be typed as video. Use a link with no extension and the content type `audio/webm`, or convert the recording first.<br><br>**Question 2: `webm` audio.** Do the later steps (plagiarism check, AI feedback) accept `webm`? This is not in `frappe_tap`. Please ask.<br><br>**Question 3: valid or not valid.** The student id (the `ST…` id) comes from our own records, never from a phone number typed by the student. The evaluation result must also say clearly whether the work is valid, with a reason the student can read (R-76). The tech team will find out which service decides this (the roadmap names Kaapi) and whether it can return that answer. If it cannot, we will come back to the product team. | Today the call also accepts requests that carry no key. Only our server should be able to call it. The app cannot hold the key. |
| O-18 | How many children will use v1, and when? Do web and app events need to reach BigQuery, next to the WhatsApp events? | The roadmap expects 500,000 children by July 2027. `frappe_tap` documents a 100,000-student design target. The size of v1 decides how much load testing and reporting work we need. |
| O-19 | **Ask TAP:** the product team described it as questions for the step the student is on, answered from the knowledge bank, plus an AI agent with a daily limit (2 questions a day now, to be raised after tests, using ChatGPT or Glific credits for the tests). Please confirm. What limit and which AI service for v1? Does the panel have a text box and a microphone, as the Figma shows? | An AI chat needs safety checks (the roadmap names a guardrails service), limits on use and a cost plan. |
| O-20 | **Deadlines, points and "I'll do it later":** what are the rules? How long does an activity last? How many points for sharing before the deadline (the design shows +25 and +40)? How long can a student leave work waiting, and what happens after the deadline? When a student sends corrected work, does it earn the full points? How many tries are allowed, and does the deadline still apply to the second try? Who can change these settings (points, limits, levels), and does a change apply to everyone or to one batch? Does the student's work unlock its picture piece when it is shared, or after the feedback (R-69)? | The designs show timers and points, but not the rules behind them. |
| O-21 | **Question 1: which screen?** Feedback opens in the app from a link in a WhatsApp message. Does the link open the Results step, or the project page under Me?<br><br>**Question 2: how does the link find the student safely?** Must the student be signed in first, or does the link carry a short-lived key? What happens if another child on the same phone opens the link? (The link arrives in the student's own WhatsApp chat, so we do not expect it on another phone.)<br><br>**Question 3: the 12-hour hold.** The product team wants the feedback released about 12 hours after the work is sent, on purpose. In the WhatsApp system, the feedback step (the points, the week change and the WhatsApp message) runs only after the feedback has been requested. Glific does that when the student answers a prompt. The app has no such prompt, so our server should call `ready_to_receive_feedback` once, about 12 hours after the work is sent. Without that call, the feedback is stored, but the points wait for the weekly delivery job and no WhatsApp message is sent. Nothing in the code holds the feedback for 12 hours today. Who does it: our Worker (it needs a queue or a scheduled job, because a Worker cannot wait 12 hours), `tapapp`, or Glific? | The app needs a safe way to read each student's own feedback, which today only Glific reads. The current call that returns feedback (`get_submission_feedback`) answers anyone who knows the submission id, and it does not say whether the work is valid. |
| O-22 | **What the WhatsApp system does today.** `save_submission` only works for a student who has an **active ProgramEnrollment**. We expect that every app student has one, because the app shares the same flow and logic as WhatsApp. Only the **first** submission of a week counts. A second one is treated as a duplicate and gets stock feedback, with no review. Invalid work is not sent back to the student. It routes to the Remedial path, or nothing happens if validation is off for that week.<br><br>**Question.** How should "Send again" after invalid work work (R-76)?<br>• **Option 1:** accept the existing rule (Remedial path).<br>• **Option 2:** approve a new resubmission path. | The rule needs a change in production logic, which we will not make without approval. The options: accept the existing rule (Remedial path), or approval for a new resubmission path. |
| O-23 | **Videos:** the demo video is on YouTube and about 10 minutes long. Are all course videos on YouTube and about that long? How should the app count a video as watched: the student taps "I watched it" (the prototype does this, and nothing checks it; the WhatsApp system trusts the call from Glific in the same way, with no player check), or the app checks the player (for example, played to the end or to a set point)? A 10-minute video needs a good connection and uses mobile data. Is that acceptable for the students? | Points for the video depend on this. The Figma shows no "I watched it" button. A video cannot play without a connection. |
| O-24 | **Quiz:** in the WhatsApp system the server runs the quiz and sends one question at a time (each answer returns the next question). It does not check the order: it accepts any question number, lets a student answer the same question again, and completes the quiz when the last question number is sent, even if earlier questions were not answered. It enforces no time limit and allows unlimited retakes. It also sends the correct answer inside every question. Our Worker removes that field before a question reaches the app, so a child cannot read it in the browser. The Worker also enforces the order: it accepts answer N+1 only after answer N. Are the other rules acceptable for the app? | The Worker fix needs no change to `frappe_tap`. The other rules are existing production logic, so changing them needs the product team's decision. |
| O-25 | **Failures in the existing pipeline:** (1) If the AI evaluation fails, the result is published as "Valid" with grade 0 ("technical issue, please resubmit"), and the points step looks only at the plagiarism flags. (2) If the checking service cannot download a photo, it passes it on as "original" and drops the failure flag. (3) If it cannot open the file (for example a HEIC photo), it retries 3 times, then sends it to the dead letter queue, and nothing goes to the student or to `frappe_tap`. (4) Nothing enforces the 12 hours, and nothing looks for submissions that never get feedback. The app must show a "taking longer than expected" state. Do we want these fixed in the pipeline (a production change)? | A failed run looks like a good one, and some students would wait for ever. |
| O-26 | **False flags on drawings:** the checking service treats flat-colour or low-noise images (many drawings and screenshots) as possibly AI-generated, and rejects them at 0.70 confidence. It also compares a photo's small fingerprint with all other students' submissions, across assignments. Many children photographing the same worksheet could match. Has this been seen in WhatsApp submissions? | Original work could get 0 points and an "invalid" message. We judged this from the code and ran no images. |
| O-27 | **Voice or video submissions:** the designer said v1 submissions are mainly a photo or a video, and voice is for a future version. We had planned voice recording in v1. Is voice in v1? How large and how long may a video be? | Video files are large and upload slowly on weak connections. We tested photo and voice on the phones, not the video camera. |
| O-28 | **App students and WhatsApp-only students:** the shared Glific "feedback" flow serves every student. To tell them apart, we propose that the flow asks `tapapp` (a webhook) whether the submission came from the app. If yes, the flow sends "Your feedback is ready" with a signed link. If no, or if the webhook fails, it sends the message as today. Is this acceptable? The check is per submission, so a student who uses both channels gets the right message for each submission. Is that what the product team wants? The flow also needs the student's Glific ID (the existing step skips the message without one), and the webhook must answer fast and must fail safe to the old path. | The flow is shared with WhatsApp-only students, so a change to it must not break their feedback. It needs the product team's approval. |
| O-29 | **Weekly limit:** in the WhatsApp system a student gets one video, one quiz and one submission a week, and cannot go past `max_allowed_week` (the batch's calendar week + 1). An operator can move the batch's calendar week forward (`update_batch_week`, one week at a time) or change `max_allowed_week` for one student. The designer said the app has no limit on activities per week. The product team decided that the next project opens only after valid feedback (R-83), which takes about 12 hours. Should app students keep the week cap, or only the feedback gate? Can a student do more than one project in a week? | The shared enrollment record assumes one activity per week, so a student who does two projects in a week would hit the cap. |
| O-30 | **Home cards:** in the meeting the designer said Home shows **two activity cards**. The Figma Home frame shows one. Which two activities does Home show (for example this week's and the next one, or two that can be done now)? The answer must fit the weekly limit and the next-project rule (O-29, R-83). | It decides how many activities Home loads and what the second card shows. |

### To confirm

These are already decided, or proposed by the TAP team. Please confirm them or tell us if they are wrong.

| # | Question | Why we ask |
|---|---|---|
| O-5 | **Decided for v1:** the app uses its own flow with one standard template for all courses. The Glific integration comes in v2 or later. Please confirm. Should we build the chat in two parts, one that decides what to say and one that shows it, so Glific can replace the first part later without rewriting the screens (R-53)? It costs a little more work now. **We recommend the split.** | It decides if we build the chat once or twice. |
| O-7 | **Decided for v1 by the TAP team:** the student signs in through a WhatsApp link that carries the phone, then picks their name from the children of that phone. Please confirm. The roadmap's password and PIN account is for the installed app, later. | The prototype's login can be taken over by anyone who knows a registered phone number, and it shows which numbers are registered. Children also forget passwords. The detailed design is in `whatsapp-link-login.md`. |
| O-8 | **Tech:** Client rule 1 says one progress record for all channels. **The TAP team proposes the WhatsApp system's `ProgramEnrollment` (with its submissions), and no second copy in the TapApp learner record**, if it can hold everything the app needs. See the table "Can ProgramEnrollment hold the progress?" in section 9. This is a tech decision. It needs no sign-off from the product team, but they may comment. The prototype has no real users, so no data needs to be moved. | Today there are two records with different rules. A child's "exact place" must be stored in the one we choose. |
| O-15 | **Decided for v1: no installed app.** v1 is the web app in the WhatsApp in-app browser. The installed Android app comes later. Please confirm, and confirm that the login and backend should stay general enough for it. | The installed app will use the same login and backend. |

## 12. Risks and dependencies

- **Figma access.** We have images only. Exact styling needs edit access to the file.
- **Glific web channel.** It is a proposal with no date. v1 does not depend on it. If it arrives later, the message format and the rich widgets still need to be agreed.
- **Backend merge.** The `tapapp` branch and the main development branch have drifted far apart. The merge needs care and a test.
- **Real-phone coverage.** Two phones are tested. More are needed.
- **School networks.** Many students share one internet address. Rate limits must allow for this.
- **Pipeline reliability.** The existing pipeline can publish a failed AI run as a good result, can lose some submissions without telling anyone, and can flag original drawings as plagiarism or AI-generated (O-25, O-26). Reusing it brings these problems into the app.
- **Server load.** The prototype kept its own copy of progress, partly to keep traffic away from the `frappe_tap` server. Using one record (O-8) puts the app's calls on the same server and the same database rows as the WhatsApp jobs. The answer is a CDN for content, a short cache for reads, few and repeatable writes, and a load test (R-78, O-18). We do not know the server's size or its current load.
- **Curriculum content.** The curriculum team must supply the videos, the exemplar works, the submission messages (for example "Champ, I'm looking forward to your pencil holder") and the evaluation guidelines. It takes about 2 weeks after they finish, to put it into the CRM and test it. Anand coordinates it.
- **Data protection.** Children's names, photos and voices pass through several services.

## 13. QA: How we will check it is done (proposed)

- A student cannot read or change the data of a child on **another phone**, even by trying other ids. Children who share one phone can switch between themselves (O-6) until the PIN is added.
- Sending the same completion twice does not give extra points.
- The weekly limit resets at the start of a new week without clearing the cache.
- If the connection drops, the app stops at the offline screen. After Retry, the student continues from the same step, and no progress is lost.
- Photos and videos reach the evaluation process. The student gets a WhatsApp nudge about 12 hours later and sees the feedback in the app.
- A changed course appears in the app without a new app release.
- The app loads and works on the agreed phones inside the WhatsApp browser.
- The first screen appears in an agreed time on a slow connection (R-43). We need to set the time and the connection speed.
- No screen shows technical error text, and every error screen has a working Retry button (R-44).
- Icons have labels, touch targets are at least 48 px, and the layout still works when the phone's text size is large (R-45).
- The load test reaches the numbers agreed in O-18 without slowing the `frappe_tap` server (R-78).
- The 3-tab navigation and all screens in section 3 match the final Figma design.

## 14. Sign-off

| Name | Role | Date | Comments |
|---|---|---|---|
| | | | |
| | | | |
