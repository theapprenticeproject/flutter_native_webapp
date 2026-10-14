# Architecture

## Runtime boundaries

### Flutter app

Owns presentation, navigation, local content, cached learner state, and temporary unit progress. Riverpod connects screens to repositories. Dio sends API requests and automatically attaches the stored bearer token.

### Cloudflare Worker

Owns the public API surface. It validates JWTs, injects the authenticated phone number, rate-limits requests, applies CORS, unwraps Frappe responses, refreshes near-expiry tokens, and handles Groq-based features.

### Frappe backend

Owns durable learner and account data: credentials, profiles, enrollment, XP, streaks, weekly windows, submissions, achievements, and scheduled maintenance jobs.

## Frontend layers

```text
screens/widgets
    -> Riverpod providers/controllers
        -> repositories
            -> HttpClient or LocalCache
                -> Worker API / Hive / secure storage
```

`lib/` is organised by layer, and each layer may only import the ones to its right.
See [Architecture Tenets](architecture-tenets.md) for the rules and how they are checked.

```text
app  ->  features  ->  shared  ->  domain  ->  core
```

| Layer     | Main location                                | Responsibility                                                         |
| --------- | -------------------------------------------- | ---------------------------------------------------------------------- |
| App       | `lib/app`                                    | Router wiring and auth redirects (the only place that sees every screen) |
| Features  | `lib/features/<feature>`                     | Screens, widgets and UI state for one user-facing feature              |
| Shared UI | `lib/shared/widgets`                         | Header, bottom bar, TapBuddy panel, loading and error views            |
| Domain    | `lib/domain/<concept>`                       | Models, repositories and providers for data shared by many screens     |
| Transport | `lib/core/network`                           | Endpoints, Dio, auth and rate-limit errors                             |
| Cache     | `lib/core/cache`                             | Hive data and secure credentials                                       |
| Content   | `assets/data`, `assets/flows`                | Courses, UI flows, images, and language data                           |

Domain concepts: `auth`, `profile`, `learner`, `program_content`, `learning_progress`, `tapbuddy`, `reference_data`.
Features: `auth`, `onboarding`, `welcome`, `splash`, `home`, `classroom`, `passport`, `settings`, `error`.

## Request lifecycle

1. A screen watches a Riverpod provider.
2. The provider obtains a repository.
3. The repository returns cached data unless a refresh is required.
4. `HttpClient` adds `Authorization: Bearer <token>`.
5. The Worker validates the token and derives the phone from it.
6. The Worker forwards the request to Frappe using `X-Flutter-Authorization`.
7. The Worker removes Frappe's outer `message` wrapper.
8. A refreshed token in the response is persisted automatically.
9. The repository merges the response into the device cache.

## Storage ownership

| Data                         | Durable owner                | Device behavior                                     |
| ---------------------------- | ---------------------------- | --------------------------------------------------- |
| Access/reset token and phone | Secure storage               | Cleared on logout                                   |
| Profiles and learner state   | Frappe                       | Cached in Hive by phone/learner ID                  |
| Active profile               | Device                       | Cached until changed or logout                      |
| Unit stage and pending XP    | Device until unit completion | Restored after refresh/restart, then submitted once |
| Course and flow JSON         | App bundle                   | Read locally; no API call                           |
| Tapbuddy history             | Device                       | Recent messages sent with each request              |
| Weekly completion keys       | Device plus Frappe           | Local count protects against stale server responses |

Cache keys use the `v2` schema in `CacheKeys`. Changing cached JSON shapes should also change the schema version or include a migration.
