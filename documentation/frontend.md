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
| `/passport`       | Skill passport    | Logged in and onboarded        |
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

## The bottom bar (new)

The bar has 3 items: **Home, Gallery, Me** (R-1). There is no Class tab: the activity opens from Home (R-2), and Home stays the active tab while it runs. **Gallery** (`/gallery`) is an empty state for now (task D9 builds it). **Me** opens today's Passport page, with a button to Settings, where the student switches profile (R-7, R-34). Settings counts as Me. **Switch profile** lists the students saved at login and swaps the saved token. It needs no phone number and makes no request (R-34). The full Me page (My projects and the rest) is task D8, and it replaces Passport and Profile. The code is in `lib/shared/widgets/app_nav.dart`, with a test in `test/shared/app_nav_test.dart`.

## Signing in with the magic link (new)

The WhatsApp link carries a code. The route `/l/<code>` (`LinkSignInScreen`) calls `/auth/redeem` and gets one token per student on the phone. One student goes to Home. Several students go to the name picker (`/profile-select`). Picking a name only swaps the saved token, with no call. If a student token is lost, `/auth/select_profile` with the phone token gets a new one. The Worker has no token refresh, so a token that ends (30 days) means the student opens a new link. The code is in `lib/domain/auth/magic_link_repository.dart`, and the tokens are kept in `SecureTokenStore`.

## Progress in v1 (new)

The app follows the bundled course order. The unit and the step the student is on are kept on the phone (`LearnerStateRepository`). The Worker records each step and owns the points. The first state is built from the login answer (name, points, course). If the Worker's `course_id` is not a bundled course, the first bundled course is used (test only, until the Worker returns real ids). Points refresh from `/progress/sync` when Home opens (3 seconds at most, then the saved points are used).

When the student taps "I watched it", `StepRecorder` calls `/progress/submit_video_watched` with the unit and video ids and an idempotency key. The key is kept until the call works, so the Retry button sends the same key and cannot give the points twice. `CONFLICT` means the video was marked before, and the app goes on. The points on screen are the ones the Worker returned. A unit now finishes on the phone, with no call. The old `/learner/*` calls are gone.

The Quiz works the same way. Each answer shows right or wrong at once, from the key in the bundled content, and shows **no points**. The app keeps the answers in order. At the end it sends them once with `/progress/submit_quiz` (`unit_id`, `quiz_id`, and the answers as `a`, `b`, `c`: the content key "1" is `a`, "2" is `b`). The points on the summary and the totals are the ones the Worker returns (+1 for each right answer), not a number worked out on the phone. Only the first scored attempt is sent. `CONFLICT` means the quiz was already scored, so the app goes on with 0 new points. A test checks that every bundled question has an id and a valid answer key. Make (the work submission) is still local and moves to the Worker in the next commits.

The old phone and password login screens still exist. They are removed in a later commit. The web app uses hash URLs today (`/#/l/<code>`). Where the Worker's `/l/<code>` link sends the student is decided later.

## Errors and responsiveness (today)

`HttpClient` converts HTTP `401` into `AuthException` and `429` into `RateLimitedException`. Other Dio failures remain transport errors. Initial-load failures should always offer recovery without discarding pending progress.

Home, Passport and Class show a failed load with `LoadErrorView` (`lib/shared/widgets/`). It takes its text from `describeError()` (`lib/shared/errors/friendly_error.dart`). Offline, busy and server problems get a **Try again** button. An ended session gets a **Sign in** button that logs out and opens the login screen, because trying again cannot fix it. No screen shows the raw error (R-44). Auth, Settings and Onboarding already had plain messages.

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
