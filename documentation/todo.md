# Engineering TODO

This page lists work we still need to do on the Flutter app. Security and product problems are in [Known Gaps](known-gaps.md). We do not repeat them here.

Keep the list short. When an item is done, delete it. If we decide not to do an item, write the reason.

Priority: **P1** do before the next release or merge. **P2** do soon. **P3** do when you have time.

## Before we merge the restructure

- [ ] **P1** Test the login screen on real phones inside the WhatsApp browser. Use the Redmi Note 13, the Samsung A31, and one Samsung phone that works.
- [ ] **P1** Click through the app again on a build made with `scripts/build_web.sh`. Then long-press the logos on the login screen and read the commit. This shows exactly which code you tested.
  - Already done on earlier builds: login, home and the other screens on one account. Onboarding with course registration on another account.
  - We do not know the commit of those builds. They were deployed before the script existed.
- [ ] **P2** The SDE will close pull request #2 (`feature/restructure-frontend`). We use the restructure on `refactor/feature-structure` instead.
  - Tell the SDE why: that PR changed code while it moved files. Five of the six test files stopped compiling. Some behavior was lost: `applyLocalProgress`, the weekly limit and "binge" checks, and `OnboardingFlowStep` parsing. Our restructure only moves files, and the checks stay green after every commit.
  - Show the SDE the [Architecture Tenets](architecture-tenets.md), the command `dart run scripts/check_architecture.dart`, and the Flutter version pin.
  - After the PR is closed, delete the local copy: `git branch -D pr-2-restructure`.

## Build and release

- [ ] **P1** Ask who built the live site with Flutter 3.41. Ask which computer and steps they use. Everyone must build with Flutter 3.47.1. The pin in `pubspec.yaml` only helps people who run `flutter pub get`.
- [ ] **P2** Add a CI workflow. The `.github/` folder is no longer ignored. First version, for every pull request: `flutter pub get`, `flutter analyze`, `flutter test`, `dart run scripts/check_architecture.dart`. Use Flutter 3.47.1.
- [ ] **P2** Make it hard to skip `scripts/build_web.sh`. A build made with plain `flutter build web` shows `unknown` in the build line. This already happened once. One idea: add a `predeploy` step in `firebase.json` that runs the script before every `firebase deploy`. Also test the long-press on real phones inside WhatsApp. Check that it does not clash with text selection.
- [ ] **P2** The build output says Flutter's service worker is deprecated. It will be removed in a future Flutter version. Decide how the app should cache files offline before that happens.
- [ ] **P3** Think about using FVM. It lets each project pin its own Flutter version. This helps if more people build releases.
- [ ] **P3** Delete the branch `webview-rendering-test`, or keep it to debug future WebView problems. Do not put its `web/flutter_bootstrap.js` (the `?cpu=1` switch) into production.

## Data and content

- [ ] **P1** Decide what a course id is, and repair the dev learners.
  - **What happened:** an SDE ran a one-time script on the **dev** Frappe site. It set every `Tapapp Learner` to one enrollment in course `CAATA3`. It also removed other enrollments and reset progress to 0. The app opens a bundled course file with the name in `enrollment.course`. No bundled file is called `CAATA3`. So those learners see `courseNotFound` on the home screen.
  - **What we found on dev:** a learner that works has a course like `Basic-Electronics-science-lab-C2258`. This is the same style as the bundled files. But the course list in Frappe (`Tapapp Enroll Course Level`) has 18 names in a different style, for example `Basic Electronics-Science Lab-Level 3-Science Lab-Level 3`. The saved ids and this list do not match. Saving a bundled-style id may need `ignore_links`.
  - **What we did:** we reset one test learner with `scripts/frappe/dev_learner_tools.py`. Then course registration in onboarding worked on the restructured code.
  - **Still to do:**
    1. Repair the other dev learners that the script changed.
    2. Ask the backend owners what the list of 18 courses is for. Ask if the app and the backend should use the same names.
    3. Only if the backend names should win: export the content again with `scripts/export_content.py`. This rewrites `assets/data/courses/`.
  - **Do not** add a `CAATA3.json` file to the assets. The export script deletes that folder on every run.
- [ ] **P2** Check that every course id the backend can return exists in the bundled index. A small script could do this. CI could run it against the Frappe course list.
- [ ] **P2** Cached data can hide server changes. The live test site kept showing a working home screen because it used old cached data. A clean browser got the new data and failed. Decide when and how the app refreshes cached learner data from the server. Our plan says the server is the source of truth.
- [ ] **P2** A learner with an unknown course id sees only "Failed to load dashboard" and a Retry button. Retry cannot fix this. Decide on a clearer message or another way to continue. This is a product decision.
- [ ] **P3** `CourseDetailModel.fromJson` accepts wrong data. JSON with the wrong keys becomes an empty course (`id: ''`, no units) and gives no error. Make it fail with an error when `id` or `units` is missing.

## Structure and code

- [ ] **P2** Split the large files. Do one file per commit, and do not change logic in the same commit.
  - `classroom/providers/class_chat_controller.dart` (1,151 lines)
  - `class_submission_card.dart` (1,016)
  - `onboarding_flow_widgets.dart` (911)
  - `class_reveal_widgets.dart` (728)
  - `passport_screen.dart` (710)
  - `auth_screen.dart` (679)
  - `profile_details_view.dart` (613)
  - `shared/widgets/tap_buddy_panel.dart` (541)
- [ ] **P3** `features/classroom/` holds the chat controller, the flows and the submission review. If a second feature needs flows or submission review, move them to `domain/` (tenet 4).
- [ ] **P3** The login route builds `AuthCheckScreen`, but the file is called `auth_screen.dart`. Make the names match (tenet 9).
- [ ] **P3** `lib/l10n/` has only `.arb` files. Check if localization is used. If not, delete the folder.
- [ ] **P3** The phone field uses `autofocus: true`. On phones the keyboard opens when the page loads. This was not the cause of the rendering bug. Decide if you want to keep it, based on how it feels to users.

## Tests

- [ ] **P2** We have few tests: 16 in total. There are none for features, none for the router redirect rules, and none for most repositories. Start with the router redirect rules. Then test the offline progress path in `LearnerStateRepository`.
- [ ] **P3** Add a small test for `scripts/check_architecture.dart`. Use a temporary folder with one broken rule for each rule. Then the rules cannot stop working without anyone seeing it. We found two bugs in the script only by checking by hand.
- [ ] **P3** The check script does not enforce tenet 7 (only repositories use the HTTP client and the cache). Think about a rule that allows `core/network` and `core/cache` imports only in `domain/` and `features/*/data/`.

## Documentation

- [ ] **P2** Add the WhatsApp browser storage result to known gap P3. On a Samsung A31 (Android 12), local storage, IndexedDB and the Cache API were still there after about 20 hours and four launches. We did not test the Redmi Note 13 or iPhones.
- [ ] **P3** The table "Important providers" in `documentation/frontend.md` has two wrong names. `authProvider` and `programContentProvider` do not exist in the code. They were already wrong on `main`. The real names are `authRepositoryProvider` and `authSessionDataProvider` (in `lib/domain/auth/`), and `programContentRepositoryProvider` and `courseDetailDataProvider` (in `lib/domain/program_content/`). The other six names are correct.
