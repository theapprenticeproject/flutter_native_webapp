# Engineering TODO

Engineering follow-ups for the Flutter app. Security and product gaps live in [Known Gaps](known-gaps.md), so they are not repeated here.

Keep this list short. Delete an item when it is done, and add the reason for anything you decide not to do.

Priority: **P1** do before the next release or merge, **P2** soon, **P3** when convenient.

## Before merging the restructure

- [ ] **P1** Click through the app on a build made with the pinned Flutter (3.47.1): login, onboarding, home, a classroom unit with video, submission and quiz, passport, settings, TapBuddy. The restructure is checked by the analyzer, tests and a web build, but nobody has used it yet.
- [ ] **P1** Test the login screen on real phones inside the WhatsApp browser (Redmi Note 13, Samsung A31, and a Samsung that works) before the restructure goes live.
- [ ] **P1** Push `refactor/feature-structure` and open a pull request.
- [ ] **P2** Decide what to do with the SDE's pull request #2 (`feature/restructure-frontend`). Reply with the reasons: it rewrote code while moving it, and five of six test files stopped compiling. Behavior that went missing and needs a decision: `applyLocalProgress` (offline progress), the weekly-limit and "binge" check on `LearnerStateModel`, and `OnboardingFlowStep` parsing. Parts worth reading before closing: the `worker/` changes and the `chat/` engine split.

## Build and release

- [ ] **P1** Ask whoever built the live site with Flutter 3.41 which machine and process they use, so everyone builds with 3.47.1. The pin in `pubspec.yaml` blocks other versions, but it only helps people who run `flutter pub get`.
- [ ] **P2** Add a CI workflow (`.github/` is no longer ignored). First version, on each pull request: `flutter pub get`, `flutter analyze`, `flutter test`, `dart run scripts/check_architecture.dart`, using Flutter 3.47.1.
- [ ] **P3** Consider FVM so each project pins the SDK itself, if more people build releases.
- [ ] **P2** Flutter's service worker is marked deprecated in the build output ("will be removed in a future Flutter release"). Decide the offline and caching approach before an upgrade removes it.
- [ ] **P3** Delete the `webview-rendering-test` branch, or keep it for diagnosing future WebView problems. Its `web/flutter_bootstrap.js` (the `?cpu=1` switch) must not go to production.

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
