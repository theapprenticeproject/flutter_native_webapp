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

| Layer     | Main location                 | Responsibility                                     |
| --------- | ----------------------------- | -------------------------------------------------- |
| UI        | `lib/screens`, `lib/widgets`  | Responsive rendering and user interaction          |
| State     | `lib/providers`               | Async loading, orchestration, controller lifetime  |
| Domain    | `lib/models`                  | Typed learner, enrollment, course, and flow models |
| Data      | `lib/data/repositories`       | Cache policy and API payloads                      |
| Transport | `lib/data/remote`             | Endpoints, Dio, auth and rate-limit errors         |
| Cache     | `lib/core/cache`              | Hive data and secure credentials                   |
| Content   | `assets/data`, `assets/flows` | Courses, UI flows, images, and language data       |

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
