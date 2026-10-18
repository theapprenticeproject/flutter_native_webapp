# Architecture Tenets

These tenets are rules for how we organize the code in `lib/`. Use them when you are not sure where a file belongs, or when a change feels wrong.

A script checks three of the tenets (2, 3 and 6). People check the others in code review. If a tenet blocks you, change the tenet in a pull request. Do not break it quietly.

## Folder layout

```
lib/
  main.dart, app.dart
  core/       Basic tools that know nothing about our app's data.
              Route names, theme, constants, network (HTTP), cache, storage.
  domain/     The data of our app, used by many screens.
              One folder for each topic: auth, profile, learner, program_content,
              learning_progress, tapbuddy, reference_data.
              Each folder has its models, repository and providers.
  shared/     Screen parts used by more than one feature
              (header, bottom bar, TapBuddy panel, loading and error views).
  app/        The place that connects everything: the router and the login
              redirects. It can use every other layer. Only main.dart and
              app.dart use it.
  features/   One folder for each part the user sees: auth, onboarding, welcome,
              splash, home, classroom, passport, settings, error.
              Each has its screens, widgets and its own screen state.
```

Inside a feature, make only the subfolders you need. Common ones are `presentation/` (screens and widgets), `providers/` and `models/`.

Code can only use other code in one direction:

```
app  →  features  →  shared  →  domain  →  core
```

A layer can use itself and the layers to its right. It must never use a layer to its left.

## Tenets

### 1. Group by data topic first, screen second

Data topics (auth, learner state, profile, course content) stay the same for a long time. Screens change often.

*Test: if you delete a screen, does anything in `domain/` need to change? It should not.*

### 2. Dependencies go in one direction: `app → features → shared → domain → core`

- `core/` knows nothing about the data of our app.
- `domain/` knows nothing about screens. It does not use widget packages (`flutter/material`, `widgets`, `cupertino`).
- `shared/` can use `domain/` and `core/`, but never `features/`.

*Test: `dart run scripts/check_architecture.dart` shows no `T2` problems.*

### 3. A feature never uses another feature

Feature A needs something from feature B? Then the code is in the wrong place. Choose one:

- It is **data or logic** → move it to `domain/`.
- It is **screen code** → move it to `shared/`.
- The two features always need each other → they are one feature. Join them.

*Test: the script shows no `T3` problems.*

### 4. Share code when a second feature needs it, not before

Code starts in the feature that needs it. When a second feature needs it, move it to `domain/` or `shared/` in the same pull request. Do not share code early. Do not let the second feature reach into the first one.

### 5. A feature owns its screen state. The domain owns shared state.

A form controller or a chat scroll position belongs to the feature. Learner state, the active profile and the login session are shared, so they live in `domain/`. Features read them through providers.

### 6. Screens stay thin

A screen puts widgets together and reads providers. Logic goes in a controller or a provider. Network and storage work goes in a repository. A file in `presentation/` has no HTTP calls, no cache keys and no JSON parsing.

*Test: the script shows no `T6` problems. A problem is when a file in `presentation/` uses `dio`, `hive`, secure storage, `core/cache`, `core/network` or `core/storage`.*

### 7. Repositories are the only way to data

Providers and screens never use the HTTP client, the cache or the bundled assets directly. This keeps the offline and cache rules in one place. That matters for our plan: "fetch once, save on the device, update locally".

### 8. Models are simple

A model holds data, parsing and simple values worked out from its data. It has no Flutter imports and no network or storage work. This makes models easy to test and safe to share.

### 9. Use clear names, and put files where people look

Use `<topic>_model.dart`, `<topic>_repository.dart`, `<topic>_provider.dart` and `<topic>_screen.dart`. If you cannot guess where a file is from its name, move it or rename it.

### 10. Choose a small simple change, not a clever design

Copying 20 lines into two features costs less than a wrong shared design. Share code after the third copy, or when it is clearly the same idea.

### 11. Move code or change code. Do not do both in one commit.

A commit that restructures code only moves files and fixes imports. Put logic changes in a different commit. This way no behavior is lost without notice, and reviewers can read the changes. `flutter analyze` and `flutter test` must pass after every commit.

## Allowed exceptions

The exceptions are listed in `scripts/check_architecture.dart`. To add one, write the reason here.

| Path | What is allowed | Reason |
|---|---|---|
| `core/router/`, `core/theme/` | Use Flutter widget packages | The route names build a `Page`, and the theme is `ThemeData`. |

## Enforcement

```bash
dart run scripts/check_architecture.dart
```

The script stops with exit code `1` if a rule is broken. It lists each problem and the rule that was broken. It understands both `package:` imports and relative imports.

Files outside `app/`, `core/`, `domain/`, `shared/` and `features/` are counted and printed, but not checked. If you add a new top-level folder in `lib/`, the script will show it.

Run the script before every pull request. We do not have a CI workflow yet. When we add one, run the script there too, so the rules do not depend on people remembering.

## Checklist for a new file

1. Is it a data topic that several screens use? → `domain/<topic>/`
2. Is it screen code that one feature uses? → `presentation/` of that feature
3. Is it screen code that two or more features use? → `shared/`
4. Is it a basic tool that knows nothing about our app? → `core/`
5. Does it use another feature? → Stop. Read tenet 3.
