# Frontend

**Updated 2026-11-05.** The sections "Today" describe the **prototype code** as it is now. The sections "v1 changes" describe what changes for the v1 test release, as in `v1-requirements.md` (it always wins) and the tasks in `v1-task-breakdown.md` (group D). Where the two differ, the v1 section is the target. For the screens, see `figma-ui-gaps.md`.

## Navigation (today)

Routes are defined in `lib/app/router.dart` (route names are constants in `lib/core/router/app_routes.dart`).

| Route             | Screen            | Access rule                    |
| ----------------- | ----------------- | ------------------------------ |
| `/`               | Splash            | Always available               |
| `/login`          | Authentication    | Public                         |
| `/profile-select` | Profile selection | Logged in                      |
| `/onboarding`     | Onboarding        | Selected profile not onboarded |
| `/welcome`        | Welcome           | Logged in and onboarded        |
| `/home`           | Dashboard         | Logged in and onboarded        |
| `/classroom`      | Lesson session    | Logged in and onboarded        |
| `/me`             | Me (profile, level, projects) | Logged in and onboarded        |
| `/profile`        | Settings/profile  | Logged in and onboarded        |
| `/error`          | Error             | Available for recovery         |

The redirect checks the cached authentication session, active profile, and onboarding state. Avoid network calls inside route redirects.

## Important providers (today)

| Provider                        | Purpose                                              |
| ------------------------------- | ---------------------------------------------------- |
| `authProvider`                  | Login, logout, reset-password session state          |
| `activeProfileProvider`         | Current learner selected on the device               |
| `learnerStateDataProvider`      | Cached-first learner state                           |
| `learningDashboardProvider`     | Home stage, unit card, completion marker             |
| `classSessionBootstrapProvider` | First incomplete unit                                |
| `classChatControllerProvider`   | Video, submission, quiz, and completion state        |
| `programContentProvider`        | Bundled course indexes and course JSON               |

## Cache policy (today)

- Login stores the token securely and caches profiles and embedded learner state.
- Profile selection writes full learner state before opening Home.
- Normal Home/Class reads use cache first.
- Unit video, submission, and quiz progress are written locally.
- One `/learner/submit-progress` request persists the completed unit and returns selected state sections.
- Logout clears secure credentials and all local cache boxes.

Use `forceRefresh: true` only for conflict recovery or a user-requested refresh. It should not be the default navigation behavior.

## The bottom bar and the Me page (new)

The bar has 3 items: **Home, Gallery, Me** (R-1). There is no Class tab: the activity opens from Home (R-2), and Home stays the active tab while it runs. **Gallery** (`/gallery`) is described in the next section. Settings (`/profile`) is opened from Me and counts as Me. The code is in `lib/shared/widgets/app_nav.dart`, with a test in `test/shared/app_nav_test.dart`.

**Me** (`/me`, `MeScreen` and `MeView` in `lib/features/me/`) replaces the old Passport and Profile screens (R-7). From top to bottom:
- **Switch profile** strip: "Not Asha? Switch to your profile". It lists the students saved at login and swaps the token, with no phone number and no request (R-34).
- **Profile card:** the TAP Buddy picture (never a photo of the child, R-60), name, class and school.
- **Level:** for example "Bronze Buddy 120 / 1000", with a bar. It comes from the points and the tiers in `/app/config`, so the names and limits are not hardcoded (R-41, R-87). If the Worker cannot be reached, the level is left out and the page still opens.
- **Total points** with a "What are points?" hint.
- **"I'm getting better at"** chips: a fixed list, the same for every student (R-95, `skill_tags.dart`). The words are placeholders until the curriculum team gives its list.
- **My projects this year** ("3 / 6 done"): one project for each unit with an assignment, at most 6 (R-87). Each shows "Not started", "Feedback pending", "Feedback given", "Wrong format" or "Not accepted". Tapping one shows the Worker's feedback. The state comes from `submission/list`, with the saved state as a fallback when offline.
- **Settings** row: language and the other settings.

v1 leaves out three later items: the Edit profile form (R-74, so the Edit button on the Settings page is hidden too), signing out (R-35) and the theme switch (R-73). The level and projects logic is in `lib/domain/me/`.

## The work submission, data layer (new)

`SubmissionRepository` (`lib/domain/submission/`) has the calls for the Make step: `requestUpload` (`/submission/request_upload`, an `image` or a `video`), `upload` (a PUT of the bytes to the signed URL with the Worker's headers and **no** bearer token, 3 tries, a file over `max_size_bytes` is refused before any request), `submitArtwork` (`/submission/submit_artwork`, with an idempotency key) and `list` and `get`. A third attempt for one assignment answers `CONFLICT`. `SubmissionInfo.isValid` is the rule of the API contract, section 4: `Success - Original` and a score above 0. The Make step uses it through `WorkSubmitter` (`work_submitter.dart`). A photo is first made smaller in the browser (`lib/shared/media/webp_encoder_web.dart`: WebP, at most 1600 pixels on the long side). A video is sent as it is. `WorkSubmitter` remembers how far each assignment got, so the Retry button starts at the step that failed, with the same slot and the same idempotency key: it never asks for a second slot and cannot send the work twice. The points on screen are the Worker's (+25 for attempt 1). `CONFLICT` (both attempts used) shows "You already sent this work" and goes on to the Quiz. A file that is too big asks the student to choose a smaller one. **"I'll do it later" (R-66):** the Make card has an "I'll do it later" button. It goes on to the Quiz and writes nothing to the Worker (the app never calls `/submission/do_later`). After the quiz the app asks "Are you ready to share your work?" with "Yes, let's go" (the Make card again) and "Not today" (back to Home, where the "send project" card waits, because the video and the quiz are done and there is no submission). If the quiz is already done when the student postpones, the app leaves at once. The feedback screens are separate tasks (D6, D17).

The Worker now checks the order: `request_upload` answers `INVALID_INPUT` until the unit's video is recorded.

## Where the work stands: feedback state (new)

`feedbackStage()` (`lib/domain/submission/feedback_state.dart`) says where the student's newest submission for an assignment stands: **not sent**, **waiting** ("I'm looking at your work, please wait"), **slow** ("taking longer than expected"), **valid**, **not valid** (can send again) or **not valid with no attempt left** (the student cannot go on, R-76). Valid means `Success - Original` with a score above 0 (API contract, section 4). Only valid feedback opens the next unit (R-83). `slowFeedbackAfter` is 24 hours for now: feedback is released at 15:00, 16:30 and 21:00 IST, so the longest normal wait is about 17 hours (the product team decides, A13). `SubmissionRepository.latest(assignmentId)` reads `submission/list` and picks the newest attempt, because `submit_artwork` may not return the id. **Waiting for feedback (R-68, R-83).** After the work is sent and the quiz is done, the unit does **not** close and the next unit does **not** open. Sending the work only records the points (`submissionSentOnly`). The submission step counts as done on the phone only when the Worker says the feedback is valid. `loadUnitFeedback` and `currentUnitWithFeedback` (`lib/domain/learning_progress/unit_feedback.dart`) ask the Worker (`submission/list`) when Home or the class opens, and keep the last answer in `FeedbackTracker` for when the phone is offline. The resolver has a new stage, `awaitingFeedback`, and Home shows a **"submission pending"** card (with a "Check again" button, and the "taking longer than expected" text after 24 hours). In the class, a waiting screen says "I'm looking at your work", checks again every 30 seconds, and has "Back to Home" and "Check again". When the feedback turns valid, the unit closes as before. **Valid feedback goes through the Results chat (R-68).** The unit stays open until the student has seen it, so a student who comes back later still sees it. Home shows a **"feedback ready"** card with "See feedback". In the class: TAP Buddy shows the Worker's feedback text, then asks "Do you want to know your total points collected so far?". The **Yes** tap takes the points from the Worker (`sync`) and shows a **YOU WON** card with what the valid work earned (the rise since the last answer) and the total. The points in the header change only after that tap. Then the submission step is marked done on the phone (`applyValidFeedback`) and the unit closes. The speaker icons on the feedback come with the audio player (D15), and the picture badge with D16.

**Not valid: Send again (R-76).** The student sees the Worker's feedback as the reason and "Send again" (a new slot, a new upload and a new idempotency key, through `WorkSubmitter.startNewAttempt`). After the second not-valid result the student sees that no tries are left and cannot go on. A score of 0 counts as not valid (R-92).

## Today's picture badge (new)

Every screen of the activity has a small badge, **0/4 to 4/4**, in the header (R-69, `PictureBadge`). Today's picture has 4 pieces. One unlocks for each step the student finishes: the video, the work sent, and the quiz. The **4th piece unlocks only with valid feedback**, so a not-valid result stays at 3/4. The count does not depend on the order, so a postponed Make (R-66) gives 2/4 after the quiz and 3/4 when the work is sent. The rule is `unlockedPieces()` (`lib/domain/learning_progress/picture_pieces.dart`). The picture on the side rail is revealed in quarters from the same count. The badge counts only what the Worker has confirmed (R-91).

## The Gallery (new)

The Gallery tab (`GalleryScreen`, `GalleryView` and `GalleryViewer` in `lib/features/gallery/`) shows:
- **This activity** (the unit the student is on) and **Your submission**: the student's own work with a "You've shared" tag, or a box with a **Share your work** button that goes to Home (R-6).
- **From TAP students like you:** a two-column grid of other students' work from `GET /gallery`. The Worker returns only valid work from the R2 copies, in random order (R-59, R-85, R-88). Each tile shows the student's **initials only**, never the name (`initialsOf`: "Durva Sibling" is "DS"). The app asks for 8 works at a time and sends back the Worker's `scope_cache_token` each time. **Load more** adds the next page and never shows the same work twice.
- **A full-screen viewer:** "1 of 9", previous and next arrows, swipe, close. A student who has not shared sees "Want to share your work too?". A video shows a play icon and an **Open video** button that opens it in a new tab, because the app has no video player yet.
- **Empty and error states:** with no work yet, a friendly message. When the Worker fails, a plain message and **Try again**. A failed **Load more** keeps what is on screen.

There is no time-left pill (R-72). The curriculum team's example works for the empty state (R-58) are not bundled yet, so the empty state is only a message. The data logic is in `lib/domain/gallery/`.

## Signing in with the magic link (new)

The WhatsApp link carries a code. The route `/l/<code>` (`LinkSignInScreen`) calls `/auth/redeem` and gets one token per student on the phone. One student goes to Home. Several students go to the name picker (`/profile-select`). Picking a name only swaps the saved token, with no call. If a student token is lost, `/auth/select_profile` with the phone token gets a new one. The Worker has no token refresh, so a token that ends (30 days) means the student opens a new link. The code is in `lib/domain/auth/magic_link_repository.dart`, and the tokens are kept in `SecureTokenStore`.

## Progress in v1 (new)

The app follows the bundled course order. The unit and the step the student is on are kept on the phone (`LearnerStateRepository`). The Worker records each step and owns the points. The first state is built from the login answer (name, points, course). If the Worker's `course_id` is not a bundled course, the first bundled course is used (test only, until the Worker returns real ids). Points refresh from `/progress/sync` when Home opens (3 seconds at most, then the saved points are used).

When the student taps "I watched it", `StepRecorder` calls `/progress/submit_video_watched` with the unit and video ids and an idempotency key. The key is kept until the call works, so the Retry button sends the same key and cannot give the points twice. `CONFLICT` means the video was marked before, and the app goes on. The points on screen are the ones the Worker returned. A unit now finishes on the phone, with no call. The old `/learner/*` calls are gone.

The Quiz works the same way. Each answer shows right or wrong at once, from the key in the bundled content, and shows **no points**. The app keeps the answers in order. At the end it sends them once with `/progress/submit_quiz` (`unit_id`, `quiz_id`, and the answers as `a`, `b`, `c`: the content key "1" is `a`, "2" is `b`). The points on the summary and the totals are the ones the Worker returns (+1 for each right answer), not a number worked out on the phone. Only the first scored attempt is sent. `CONFLICT` means the quiz was already scored, so the app goes on with 0 new points. A test checks that every bundled question has an id and a valid answer key. Make (the work submission) is still local and moves to the Worker in the next commits.

The old phone and password login screens still exist. They are removed in a later commit. The web app uses hash URLs today (`/#/l/<code>`). Where the Worker's `/l/<code>` link sends the student is decided later.

## Errors and responsiveness (today)

`HttpClient` converts HTTP `401` into `AuthException` and `429` into `RateLimitedException`. Other Dio failures remain transport errors. Initial-load failures should always offer recovery without discarding pending progress.

Home, Me and Class show a failed load with `LoadErrorView` (`lib/shared/widgets/`). It takes its text from `describeError()` (`lib/shared/errors/friendly_error.dart`). Offline, busy and server problems get a **Try again** button. An ended session gets a **Sign in** button that logs out and opens the login screen, because trying again cannot fix it. No screen shows the raw error (R-44). Auth, Settings and Onboarding already had plain messages.

The app uses shared `AppHeader` and `AppNav` shells. Classroom and Home switch layouts through `LayoutBuilder` breakpoints. New fixed-size media or controls need bounded dimensions and a mobile fallback.

# v1 changes

## Navigation (v1)

| Route (v1) | Screen | Access rule | Task |
| --- | --- | --- | --- |
| `/` | Splash | Always available | D1 |
| `/l/:token` | Opens the WhatsApp magic link. It runs **before** the login check. The token is in the part of the link after `#`, and the app removes it from the address bar after login. | Public | D2 |
| `/profile-select` | "Who is learning" (name picker), only when the phone has several children | Phone token | D2 |
| `/welcome` | Welcome back | Student token | D1 |
| `/home` | Home: one activity card, an empty banner place | Student token | D7 |
| `/classroom` | The activity flow (Watch, Make, Quiz, Results). A **pushed route** from Home, not a tab. | Student token | D3 to D6 |
| `/gallery` | Gallery tab (an empty state with example works until the Gallery content is built) | Student token | D1, D9 |
| `/me` | Me: profile, level, points, My projects, settings and the **switch profile** sheet (the name picker above is only for the first pick) | Student token | D8 |
| A feedback-link route | Opens the **Results step** of one submission, also when nobody is signed in on the phone | Signed feedback link | D13 |
| `/error` | Error, with a Retry button | Available for recovery | D0 |

Changes from today:
- **3 tabs: Home, Gallery, Me** (R-1). `/passport` and `/profile` are replaced by `/gallery` and `/me`. Class is not a tab (R-2).
- **No `/login` with a password** and **no `/onboarding`.** The kids are already registered, and the app has no onboarding. The password and OTP login is removed (R-32, R-33).
- **No Sign out** in v1 (R-35). The Edit profile screen is later (R-74).
- Events are v1.1 (R-86). Home keeps a place above the activity card for a banner, which is empty in v1 (R-94).
- The redirect still avoids network calls. It checks the saved tokens.

## Providers (v1)

| Provider (idea) | Purpose |
| --- | --- |
| Auth | The phone token, the student token and the switch of profile. A student token has the `student_id` and no phone (R-81). The app also keeps the phone token, so it can ask the Worker for a token of another child. |
| Progress | The student's points, completed activities and steps, from the Worker. It asks for "not changed" first, to keep the load low (R-78). |
| Activity flow | The state of the four steps. The order is Watch, Make, Quiz, Results (R-61). A postponed Make comes back after the Quiz (R-66). |
| Quiz | Downloads the whole quiz, gives right or wrong at once, keeps the answers on the phone and sends them at the end. The server's result counts (R-91). |
| Content | Downloads the manifest and the content files from the CDN, with a small first-run copy in the app (D11). |
| Audio | Plays a clip when the student taps a speaker icon. Messages never play by themselves (R-17, D15). |
| Interaction events | Collects every interaction (taps, screens, steps, quiz answers, chat messages, typed text, errors) and sends them in batches (R-84, D18). |

Changes from today:
- **Removed in M0 (2026-11-09):** the weekly-cap logic (R-39), the streaks, the gems and the archetype calculation (D0). The old "cap reached" screen is now a plain "no activity right now" screen. The activity flow uses one fixed archetype (`submitter`), so the Make step is a photo or a video (R-63), until M3 to M5 rebuild the flow.
- **Removed in M0 (2026-11-06):** `tapBuddyContextProvider`, the TapBuddy chat code (`lib/domain/tapbuddy/`), the Ask TAP panel (`tap_buddy_panel.dart`) and the "Ask TAP Buddy" button in the header. The app has **no Ask TAP** until the prepared-question panel is built (R-70, D10, P2). The animated TAP Buddy character in the classroom stays.
- **Removed in M0 (2026-11-06):** the Groq and AI review code, in the Worker (C1) and in the app (D0). Submissions are no longer reviewed by an AI. See `known-gaps.md`, GP10.
- The learner state no longer comes from the old `/learner/submit-progress`. The calls are the ones in `api-contract.md`, through the Worker. The app never calls Frappe directly.

## Saving and the cache (v1)

- **Every step is saved to the server at once** (R-40): the video is marked as watched, the work is sent, the quiz is finished. Each write has an idempotency key, so a repeat is saved once.
- **The exception is the quiz.** Once it has started, the student can finish it without a network. The answers stay on the phone and are sent when the quiz ends, or when the connection is back. If the student leaves the app, the quiz continues from the saved answers. The points, the picture badge (R-69) and the Results step use the **server's result**, not the local one.
- **The phone is the only waiting place for the interaction events.** The app keeps each event until the Worker confirms that it is in the queue, and sends it again after a "not saved" answer (D18). The events do not go to Frappe.
- **A failed upload does not lose the work.** The student can try again (R-13). The photo is made smaller and saved as WebP before upload, with JPEG as the fallback (R-12). The video is limited to 90 seconds (R-9).
- **Offline:** the app shows "I am not able to talk to you. Looks like you're offline" and a Retry button. The student cannot go on until the connection is back, and then continues from the same step (R-71). The quiz exception is above.
- **Content** comes from the CDN (R-18, `build-bootstrap.md`). Bundling the content in the app for the first test is only a way to cut work. It needs the tech lead's agreement (`v1-task-breakdown.md`, "How to cut", item 2). Quiz answers are **not** in the content files. They come with the quiz start call.
- **Switching profile** asks the Worker for a new student token (R-34).

## Errors and responsiveness (v1)

- The Worker maps the backend error codes to friendly texts. The app shows a clear message and a Retry button, and never shows the technical message (task D0, `api-contract.md` section 1).
- `401` means the token is wrong or has expired. The app shows a clear message and asks the student to open the link again. `429` means too many requests. The app waits and offers Retry.
- Initial-load failures always offer recovery without discarding pending progress.
- The app is tested in the **WhatsApp in-app browser** on Android 10 and later, on real phones (task E2). Audio, the camera, the microphone and storage work there. Speech does not. The video camera is not tested yet (R-9).
- The first screen must appear in an agreed time on a slow connection (R-43). Fonts are bundled, and the big loader GIF is replaced (D0).
- Text is in Hindi and English, in translation files, with one translated fallback for "Champ" (D14, R-23, R-25).
