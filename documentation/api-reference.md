# API Reference

This page documents the **Cloudflare Worker API called by Flutter**. Use the Worker base URL, not the Frappe URL, in Postman.

## Authentication

After login, add this header to protected requests:

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

The Worker also accepts `X-Flutter-Authorization`. Protected endpoints derive `phone` from the token, so a different request phone is replaced or rejected.

## Endpoint summary

| Method | Path                               | Auth         | Purpose                               |
| ------ | ---------------------------------- | ------------ | ------------------------------------- |
| POST   | `/auth/check-phone`                | No           | Check registration/password status    |
| POST   | `/auth/login`                      | No           | Login and return profiles             |
| POST   | `/auth/forgot-password/send-otp`   | No           | Send reset OTP                        |
| POST   | `/auth/forgot-password/verify-otp` | No           | Exchange OTP for reset token          |
| POST   | `/auth/reset-password`             | Reset token  | Set password and receive access token |
| GET    | `/profiles`                        | Access token | Paginated profiles with state         |
| GET    | `/profiles/search`                 | Access token | Search/filter profiles                |
| POST   | `/profiles/select`                 | Access token | Select learner and return full state  |
| POST   | `/profiles/avatar`                 | Access token | Update avatar                         |
| POST   | `/profiles/update`                 | Access token | Update permitted fields               |
| GET    | `/students/search`                 | Access token | Search student roster                 |
| GET    | `/students`                        | Access token | Fetch students in bulk                |
| POST   | `/students/update`                 | Access token | Update one student                    |
| POST   | `/students/bulk-update`            | Access token | Update multiple students              |
| GET    | `/learner/state`                   | Access token | Get selected state sections           |
| POST   | `/learner/enroll`                  | Access token | Activate a course enrollment          |
| POST   | `/learner/submit-progress`         | Access token | Persist unit progress and XP          |
| GET    | `/achievements`                    | Access token | List achievements                     |
| POST   | `/achievements/award`              | Access token | Award/update achievement              |
| POST   | `/onboarding/complete`             | Access token | Save onboarding profile/course        |
| POST   | `/tapbuddy/chat`                   | Access token | Context-aware learning chat           |
| POST   | `/submission-review/review`        | Access token | AI review for text/image/audio        |

## Postman sequence

### 1. Login

```http
POST {{worker_url}}/auth/login
```

```json
{
  "phone": "9999999999",
  "password": "your-password"
}
```

Store `token` from the response as a Postman environment variable.

### 2. Select a profile

```http
POST {{worker_url}}/profiles/select
Authorization: Bearer {{token}}
```

```json
{
  "phone": "9999999999",
  "learner_id": "TL00017423",
  "fields": "profile,xp,level,streak,window,archetype,submission,enrollment,achievements"
}
```

### 3. Read learner state

```http
GET {{worker_url}}/learner/state?learner_id=TL00017423&fields=xp,level,window,enrollment
Authorization: Bearer {{token}}
```

### 4. Complete one unit

Indexes are one-based completed counts.

```http
POST {{worker_url}}/learner/submit-progress
Authorization: Bearer {{token}}
```

```json
{
  "learner_id": "TL00017423",
  "xp": 37,
  "activity_type": "unit_complete",
  "video_index": 1,
  "submission_index": 1,
  "quiz_index": 1,
  "fields": "profile,xp,level,streak,window,archetype,submission,enrollment,achievements"
}
```

The frontend expects `progress_recorded: true`. A conflict with no recorded progress triggers an authoritative state refresh.

### 5. Ask Tapbuddy

```http
POST {{worker_url}}/tapbuddy/chat
Authorization: Bearer {{token}}
```

```json
{
  "phone": "9999999999",
  "learner_id": "TL00017423",
  "message": "Can you explain this lesson?",
  "grade": "6",
  "language": "English",
  "context": {
    "course_name": "Basic Electronics",
    "unit_name": "Simple circuits",
    "xp": 120,
    "streak": 2,
    "has_reached_weekly_cap": false,
    "has_active_class_session": true
  },
  "history": []
}
```

### 6. Review a text submission

```http
POST {{worker_url}}/submission-review/review
Authorization: Bearer {{token}}
```

```json
{
  "phone": "9999999999",
  "learner_id": "TL00017423",
  "submission_type": "text",
  "submission_text": "A circuit needs a closed path for current to flow.",
  "question": "When does current flow?",
  "expected_answer": "The circuit must be closed.",
  "rubric": "Mentions a complete or closed path."
}
```

Image review accepts `image_url`; audio review accepts `audio_url`. URLs must be reachable by Groq, or an image may be a `data:image/...` URI.

## Common responses

| Status | Meaning                                                             |
| ------ | ------------------------------------------------------------------- |
| 200    | Handled; still check `success`, `processed`, or `progress_recorded` |
| 400    | Missing or invalid input                                            |
| 401    | Invalid, expired, mismatched, or wrong-type token                   |
| 404    | Worker route or Frappe record not found                             |
| 429    | Worker rate limit reached                                           |
| 502    | Frappe/Groq unavailable or invalid AI response                      |
