# Architecture Tenets

These tenets guide how code in `lib/` is organised. When you are unsure where
something belongs, or a change feels awkward, check it against them.

Two of them are enforced by a script (see [Enforcement](#enforcement)). The rest
rely on review. If a tenet gets in your way, change the tenet in a pull request.
Do not quietly break it.

## Target layout

```
lib/
  main.dart, app.dart
  core/       Infrastructure with no knowledge of the app's domain.
              router, theme, constants, network (http), cache, storage.
  domain/     The app's data concepts, shared by many screens.
              One folder per concept (auth, learner, profile, program_content,
              flows, ...) holding its models, repository and providers.
  shared/     UI used by more than one feature (header, nav, error view, ...).
  features/   One folder per user-facing feature (home, classroom, onboarding,
              passport, settings, tap_buddy, ...).
              Each holds its screens, widgets and its own UI state.
```

Inside a feature, create only the subfolders you need. Typical ones are
`presentation/` (screens and widgets), `providers/` and `models/`.

Dependencies point one way:

```
features  →  shared  →  domain  →  core
```

A layer may import itself and anything to its right. It must never import
anything to its left.

## Tenets

### 1. Organise by domain concept first, screen second

Data concepts (auth, learner state, profile, program content) are the stable
core of the app. Screens come and go.

*Test: if a screen is deleted, does anything in `domain/` have to change? It
shouldn't.*

### 2. Dependencies point one way: `features → shared → domain → core`

- `core/` knows nothing about the app's domain.
- `domain/` knows nothing about screens, and imports no widget toolkit
  (`flutter/material`, `widgets`, `cupertino`).
- `shared/` may use `domain/` and `core/`, never `features/`.

*Test: `dart run scripts/check_architecture.dart` reports no `T2` violations.*

### 3. Features never import other features

If feature A needs something from feature B, it is in the wrong place. Pick one:

- It is **data or logic** → move it to `domain/`.
- It is **UI** → move it to `shared/`.
- The two features keep needing each other → they are one feature. Merge them.

*Test: the script reports no `T3` violations.*

### 4. Promote on the second use, not the first

Code starts in the feature that needs it. When a second feature needs it, move it
to `domain/` or `shared/` in the same pull request. Do not pre-share, and do not
let the second feature reach into the first.

### 5. A feature owns its UI state, the domain owns shared state

A form controller or a chat scroll position belongs to the feature. Learner
state, the active profile and the auth session are shared, so they live in
`domain/`. Features read them through providers.

### 6. Screens are thin

A screen composes widgets and reads providers. Logic goes in a controller or
provider, and I/O goes in a repository. A `presentation/` file has no HTTP calls,
no cache keys, no JSON parsing.

*Test: the script reports no `T6` violations (presentation importing `dio`,
`hive`, secure storage, or `core/cache`, `core/network`, `core/storage`).*

### 7. Repositories are the only door to data

Providers and screens never touch the HTTP client, the cache or bundled assets
directly. This keeps offline and caching behaviour in one place, which matters
for the app's "fetch once, save, update locally" design.

### 8. Models are plain and boring

Models hold data, parsing and simple derived values. No Flutter imports, no I/O.
That keeps them testable and safe to share.

### 9. Name it for what it is, put it where you would look

`<concept>_model.dart`, `<concept>_repository.dart`, `<concept>_provider.dart`,
`<concept>_screen.dart`. If you cannot guess where a file lives from its name,
move or rename it.

### 10. Prefer a small, boring move over a clever abstraction

Duplicating 20 lines in two features is cheaper than the wrong shared
abstraction. Share after the third near-copy, or when the concept is clearly the
same.

### 11. Move code or change code, never both in one commit

A refactor commit moves files and fixes imports only. Logic changes go in a
separate commit. This keeps behaviour from being lost silently, and keeps diffs
reviewable. `flutter analyze` and `flutter test` stay green after every commit.

## Documented exceptions

Exceptions are listed in `scripts/check_architecture.dart`. Adding one needs a
reason here.

| Path | Allowed | Why |
|---|---|---|
| `core/router/` | Import `features/` | The router wires every screen to a route. |
| `core/router/`, `core/theme/` | Import Flutter widget packages | They are Flutter by nature (`GoRouter`, `ThemeData`). |

## Enforcement

```bash
dart run scripts/check_architecture.dart
```

It exits `1` and lists each violation with the rule it broke. It resolves both
`package:` and relative imports, so import style does not matter.

During the migration, files outside `core/`, `domain/`, `shared/` and `features/`
(the old `models/`, `providers/`, `screens/`, `data/`, `widgets/`,
`data_loader/`) are counted and printed but not checked. The count reaching zero
is the sign the migration is done.

Run it before every pull request. There is no CI workflow in this repository yet.
When one is added, run the script there so the rules do not depend on memory.

## Checklist for a new file

1. Is it a data concept shared by several screens? → `domain/<concept>/`
2. Is it UI used by one feature? → that feature's `presentation/`
3. Is it UI used by two or more features? → `shared/`
4. Is it infrastructure with no app knowledge? → `core/`
5. Does it import another feature? → stop. See tenet 3.
