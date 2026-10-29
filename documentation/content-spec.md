# Content specification (draft)

**Status:** proposal. Two points are open (section 8). Nothing here is decided until the team agrees.
**For:** the TapApp team and the curriculum team. It supports R-18 to R-25, R-52, R-54, R-55, R-57, R-58, R-79 and R-91 in the [v1 requirements](v1-requirements.md), and open decision O-9.

## 1. The idea

- The curriculum team writes content in **Frappe** (the master copy). Today that already holds courses, units, videos, quizzes and assignments with translations.
- A **Publish** step turns that content into **versioned files** and puts them in object storage (R2) behind a CDN.
- The app downloads the files. It never reads Frappe for content. This keeps load off `frappe_tap` (R-78).
- Everything the app shows from content is in these files, except the **quiz answers**. Those stay on the server (R-91).

## 2. Who does what (proposed)

| Task | Owner |
|---|---|
| Write and translate content, record audio | Curriculum team. Contact: Manu Agarwal (O-1) |
| Press Publish | Curriculum team |
| Build, check and upload the files | A publish job (built by the tech team) |
| The standard flow template | Open: git or Frappe (section 8) |

## 3. File layout

```
content/manifest.json
content/units/<unit-id>/<lang>.json
content/flow/standard/<lang>.json
content/audio/<lang>/<message-id>.mp3
content/exemplars/<assignment-id>/<file>
content/events/<event-id>/<lang>.json      (events, R-86)
current/<batch-id>.json                    (the current activity for a batch, R-93)
```

- `<lang>` is a language code. v1 has `en` and `hi` (R-23).
- File names use only lowercase letters, digits, `-` and `_`.
- Files are never changed after upload. A new version gets a new name or a new hash.

## 4. The manifest

The app downloads `manifest.json` first. It lists every file and its hash, so the app downloads only what changed (R-19).

```json
{
  "schema": "manifest/1",
  "version": 42,
  "published_at": "2026-11-03T10:00:00+05:30",
  "languages": ["en", "hi"],
  "files": {
    "units/VA_L1_TD-27378/hi.json": { "hash": "sha256:9f2c…", "bytes": 4120 },
    "flow/standard/hi.json":        { "hash": "sha256:51ab…", "bytes": 9876 },
    "audio/hi/msg-welcome-01.mp3":  { "hash": "sha256:c0de…", "bytes": 54300 }
  }
}
```

Rules:
- `version` goes up by one at each publish.
- A unit that is already open keeps the old files until it is finished (R-21).
- If a file fails to download, the app shows a clear message and a Retry button (R-22).

## 5. A unit file

One file for each unit and language. It holds what the Watch, Make and Quiz steps show.

```json
{
  "schema": "unit/1",
  "unit_id": "VA_L1_TD-27378",
  "language": "hi",
  "title": "…",
  "video": { "youtube_id": "abc123", "title": "…", "length_seconds": 600 },
  "assignment": {
    "assignment_id": "VA_L1_TD-27378",
    "instructions": "…",
    "submission_types": ["image", "video"],
    "exemplars": ["exemplars/VA_L1_TD-27378/1.webp"]
  },
  "quiz": {
    "quiz_id": "Q-1001",
    "questions": [
      {
        "question_id": "QQ-1",
        "text": "…",
        "options": [ { "key": "a", "text": "…" }, { "key": "b", "text": "…" } ]
      }
    ]
  },
  "picture_pieces": 4
}
```

Rules:
- **No answer key.** The correct option of each question stays on the server. The server checks each answer (R-91).
- `submission_types` can be `image`, `video` or `text`. Voice is later (R-10).
- Quiz questions are text only in v1 (R-67).
- A question picture, if it comes later, is a field `image` with a file path.

## 6. A message (standard flow)

`flow/standard/<lang>.json` holds the messages of the one standard flow (R-52). Each message has an id, so audio and text stay linked.

```json
{
  "schema": "flow/1",
  "language": "hi",
  "messages": [
    {
      "id": "msg-welcome-01",
      "text": "नमस्ते {student_name}!",
      "spoken_text": "नमस्ते!",
      "audio": { "file": "audio/hi/msg-welcome-01.mp3", "text_hash": "sha256:77d1…" }
    }
  ]
}
```

Rules:
- Placeholders look like `{student_name}` or `{course_name}`. A message with a placeholder has a `spoken_text` written without the name (R-57).
- The `audio.text_hash` is the hash of the `text` the clip was recorded for. If the text changes and the hash no longer matches, the clip is **out of date** (R-54). The app then shows no speaker icon for that message, and never plays another language (R-55).
- Messages never play by themselves. The student taps the speaker icon (R-17).
- Feedback audio is not in these files. It is made for each student (R-56).

## 6a. The current activity of a batch

`current/<batch-id>.json` is a tiny file. It tells the app which unit is current for a batch, so the app does not call the server for it (R-93).

```json
{
  "schema": "current/1",
  "batch_id": "BT00000024",
  "unit_id": "VA_L1_TD-27378",
  "released_at": "2026-11-03T16:00:00+05:30",
  "deadline_at": "2026-11-10T16:00:00+05:30"
}
```

- A **sync script** writes this file. It uses the same logic as the WhatsApp content calls: the current week from `Weekly Student Flow` (`get_student_current_week`), then the batch's `Learning Unit` for that week (`get_learning_units_by_week`). It rewrites the file only if something changed. Whether the team's manual weekly update is made in `Weekly Student Flow` is still to be confirmed (R-93).
- It is not part of the versioned content: the app reads it often, and the CDN caches it for about a minute.
- The app compares `released_at` with what it knows. A newer value means a new activity.

## 7. Checking before publish

- Each file type has a **JSON Schema** (`manifest/1`, `unit/1`, `flow/1`). The publish job checks every file against it.
- Extra checks:
  - every language in the manifest has a unit file, a flow file and (for messages that need audio) a clip;
  - every audio file named in a message exists and its `text_hash` matches;
  - every `exemplars` path exists;
  - no unit file contains a field that looks like an answer key.
- A publish with an error is refused. The curriculum team sees which file and why.

## 8. Open points

1. **Where is the content authored?** We propose Frappe and the existing import from Google Sheets. The curriculum team has not confirmed. Another tool may suit them better.
2. **Where does the standard flow template live?** We propose git (developers own it, and it rarely changes). The alternative is Frappe, so the curriculum team can edit messages without a developer.

## 9. Not covered yet

- How the publish job reads the existing Frappe doctypes (`Course Level`, `Learning Unit`, `VideoClass`, `Quiz`, `Assignment`) and their translations. That needs a mapping table once the points above are answered.
- Events (R-86): the file shape is listed in the layout but not specified.
- Picture pieces (R-69): only the count is in the unit file.
