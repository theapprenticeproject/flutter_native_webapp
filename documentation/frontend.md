# Frontend

## Navigation

Routes are defined in `lib/core/router/router.dart`.

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

## Important providers

| Provider                        | Purpose                                              |
| ------------------------------- | ---------------------------------------------------- |
| `authProvider`                  | Login, logout, reset-password session state          |
| `activeProfileProvider`         | Current learner selected on the device               |
| `learnerStateDataProvider`      | Cached-first learner state                           |
| `learningDashboardProvider`     | Home stage, unit card, weekly cap, completion marker |
| `classSessionBootstrapProvider` | First incomplete unit and weekly limit check         |
| `classChatControllerProvider`   | Video, submission, quiz, and completion state        |
| `tapBuddyContextProvider`       | Learner/course context for Tapbuddy                  |
| `programContentProvider`        | Bundled course indexes and course JSON               |

## Cache policy

- Login stores the token securely and caches profiles and embedded learner state.
- Profile selection writes full learner state before opening Home.
- Normal Home/Class reads use cache first.
- Unit video, submission, and quiz progress are written locally.
- One `/learner/submit-progress` request persists the completed unit and returns selected state sections.
- Logout clears secure credentials and all local cache boxes.

Use `forceRefresh: true` only for conflict recovery or a user-requested refresh. It should not be the default navigation behavior.

## Errors and responsiveness

`HttpClient` converts HTTP `401` into `AuthException` and `429` into `RateLimitedException`. Other Dio failures remain transport errors. Initial-load failures should always offer recovery without discarding pending progress.

The app uses shared `AppHeader` and `AppNav` shells. Classroom and Home switch layouts through `LayoutBuilder` breakpoints. New fixed-size media or controls need bounded dimensions and a mobile fallback.
