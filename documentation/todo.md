# Engineering TODO

Engineering follow-ups for the Flutter app. Security and product gaps live in [Known Gaps](known-gaps.md), so they are not repeated here.

Keep this list short. Delete an item when it is done, and add the reason for anything you decide not to do.

Priority: **P1** do before the next release or merge, **P2** soon, **P3** when convenient.

## Before merging the restructure

- [ ] **P1** Repeat the click-through on a build made with `scripts/build_web.sh`, then read the commit from the build line (long-press the logos) so it is clear exactly what was tested. A first click-through on another account worked: login, home and the other screens loaded with no errors. That build's commit is not known, because it was deployed before the script existed. Use an account whose course id is bundled, or home shows the `CAATA3` error described under Data and content.
- [ ] **P1** Test the login screen on real phones inside the WhatsApp browser (Redmi Note 13, Samsung A31, and a Samsung that works) before the restructure goes live.
- [ ] **P1** Push `refactor/feature-structure` and open a pull request.
- [ ] **P2** The SDE's pull request #2 (`feature/restructure-frontend`) is not being used. The team uses the restructure on `refactor/feature-structure` instead. The SDE will close the pull request. When talking to them, share the reasons and the way forward: the PR rewrote code while moving it (five of six test files stopped compiling, and `applyLocalProgress`, the weekly-limit and "binge" checks and `OnboardingFlowStep` parsing disappeared), whereas the restructure here only moves files and keeps analyze, tests and the architecture check green after every commit. Point them to [Architecture Tenets](architecture-tenets.md) and `dart run scripts/check_architecture.dart`, and to the Flutter version pin. Once it is closed, delete the local reference with `git branch -D pr-2-restructure`.

## Build and release

- [ ] **P1** Ask whoever built the live site with Flutter 3.41 which machine and process they use, so everyone builds with 3.47.1. The pin in `pubspec.yaml` blocks other versions, but it only helps people who run `flutter pub get`.
- [ ] **P2** Add a CI workflow (`.github/` is no longer ignored). First version, on each pull request: `flutter pub get`, `flutter analyze`, `flutter test`, `dart run scripts/check_architecture.dart`, using Flutter 3.47.1.
- [ ] **P2** Make `scripts/build_web.sh` hard to skip. A deploy made with plain `flutter build web` shows `unknown` in the login screen's build line (long-press the logos), which was seen once already. Option: a `predeploy` hook in `firebase.json` that runs the script before every `firebase deploy`. Also check the long-press on real phones inside WhatsApp's browser, including that it does not clash with text selection.
- [ ] **P3** Consider FVM so each project pins the SDK itself, if more people build releases.
- [ ] **P2** Flutter's service worker is marked deprecated in the build output ("will be removed in a future Flutter release"). Decide the offline and caching approach before an upgrade removes it.
- [ ] **P3** Delete the `webview-rendering-test` branch, or keep it for diagnosing future WebView problems. Its `web/flutter_bootstrap.js` (the `?cpu=1` switch) must not go to production.

## Data and content

- [ ] **P1** Align course ids between the backend and the bundled content. Known so far: an SDE ran a one-off script on the **dev** site that set every `Tapapp Learner` to one enrollment in `CAATA3`, which is neither a record of the course doctype (`Tapapp Enroll Course Level`) nor a bundled course, so those learners fail on home with `courseNotFound`. More importantly, the 18 course names on the server (for example `Basic Electronics-Science Lab-Level 3-Science Lab-Level 3`) do not match the 14 bundled ids (for example `Basic-Electronics-science-lab-C2258`), not even after replacing spaces with dashes. The bundled courses come from a single export (first commit, 2026-08-21), and the app uses `enrollment.course` unchanged as the file name. One test profile does load its course, so its enrollment value shows the format the app accepts: read it in the bench console and compare. Then decide which side is canonical, and re-export the content with `scripts/export_content.py` if the server names are. Do not add a `CAATA3.json` to the assets, because the export deletes and rewrites `assets/data/courses/` on every run.
- [ ] **P2** Check that every course id the backend can return exists in the bundled index, for example with a small script that CI can run against the Frappe course list.
- [ ] **P2** Cached enrollment can hide server changes. The live test site kept showing a working home screen because it used old cached data, while a clean browser got the new data and failed. Decide how and when cached learner state and enrollments are refreshed from the server, since the plan treats the server as the source of truth.
- [ ] **P2** A learner whose course id is unknown sees only "Failed to load dashboard" and a Retry button, which cannot help. Decide on a clearer message or a fallback, which is a product decision.
- [ ] **P3** `CourseDetailModel.fromJson` is lenient: JSON with the wrong keys becomes an empty course (`id: ''`, no units) instead of an error. Consider failing loudly when `id` or `units` is missing.

## Structure and code

- [ ] **P2** Split the large files, one commit each, with no logic changes in the same commit. `classroom/providers/class_chat_controller.dart` (1,151 lines), `class_submission_card.dart` (1,016), `onboarding_flow_widgets.dart` (911), `class_reveal_widgets.dart` (728), `passport_screen.dart` (710), `auth_screen.dart` (679), `profile_details_view.dart` (613), `shared/widgets/tap_buddy_panel.dart` (541).
- [ ] **P3** `features/classroom/` holds the chat controller, flows and submission review. If a second feature needs flows or submission review, move them to `domain/` (tenet 4).
- [ ] **P3** `login` builds `AuthCheckScreen`, which lives in `auth_screen.dart`. Rename one to match the other (tenet 9).
- [ ] **P3** `lib/l10n/` only has `.arb` files. Check whether localization is wired up, and delete the folder if not.
- [ ] **P3** The phone field uses `autofocus: true`, so the keyboard opens on arrival on phones. It was not the cause of the rendering bug. Decide on UX grounds whether to keep it.

## Tests

- [ ] **P2** Coverage is thin: 12 tests, none for features, the router redirects, or the repositories other than learner state. Start with the router redirect rules and the offline progress path (`LearnerStateRepository`).
- [ ] **P3** Add a small test for `scripts/check_architecture.dart` (a scratch tree with one violation per rule), so the rules cannot silently stop working. Two bugs in it were only found by hand.
- [ ] **P3** The check script does not enforce tenet 7 (only repositories touch the HTTP client and cache). Consider a rule that limits `core/network` and `core/cache` imports to `domain/` and `features/*/data/`.

## Documentation

- [ ] **P2** Add the WhatsApp-browser storage finding to known gap P3: on a Samsung A31 (Android 12) local storage, IndexedDB and the Cache API were still present after about 20 hours and four launches. The Redmi Note 13 and iPhones are not tested.
- [ ] **P3** The "Important providers" table in `documentation/frontend.md` lists `authProvider` and `programContentProvider`, which do not exist in the code (this was already so on `main`). The real names are `authRepositoryProvider` and `authSessionDataProvider` (`lib/domain/auth/`), and `programContentRepositoryProvider` and `courseDetailDataProvider` (`lib/domain/program_content/`). The other six names are correct.
