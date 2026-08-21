# Content and Assets

Learning content is bundled into the Flutter build. Changing JSON or images requires a new frontend build and deployment.

## Directory map

| Path                                          | Content                                       |
| --------------------------------------------- | --------------------------------------------- |
| `assets/data/courses/<lang>/index.json`       | Course list for a language                    |
| `assets/data/courses/<lang>/<course-id>.json` | Units, videos, assignments, quizzes           |
| `assets/data/courses/thumbnail/`              | Home and continuation thumbnails              |
| `assets/flows/en/flow_manifest.json`          | Available flow files/languages                |
| `assets/flows/en/activity/`                   | Classroom conversation and component registry |
| `assets/flows/en/onboarding/`                 | Student onboarding definition                 |
| `assets/reveal/`                              | Unit reveal images                            |
| `assets/data/district/`                       | State-specific districts                      |

## Course shape

Course JSON uses compact keys:

| Key                              | Meaning                                             |
| -------------------------------- | --------------------------------------------------- |
| `id`, `nm`, `lvl`, `vrt`, `desc` | Course identity and display fields                  |
| `units`                          | Ordered course units                                |
| `vids`                           | Unit videos; `yt` is YouTube ID and `pts` is reward |
| `assigns`                        | Assignment definitions and submission steps         |
| `sub_types`                      | `emoji`, `text,audio`, `image`, or `image,video`    |
| `quiz.qs`                        | Questions with options, answer key, and explanation |

## Add or update a course

1. Add course JSON under each supported language that should expose it.
2. Add metadata to that language's `index.json`.
3. Add `assets/data/courses/thumbnail/<course-id>.webp`.
4. Keep unit ordering stable once learners have progress indexes.
5. Validate every video ID, quiz answer key, and assignment `sub_types` value.
6. Test Home and Class at mobile and desktop widths.

## Add a language

1. Add it to `AppConstants.supportedLanguages`.
2. Add localization ARB files as needed.
3. Add `assets/data/courses/<lang>/index.json` and course files.
4. Add flow files and update the manifest, or intentionally use English fallback.
5. Register the asset directory in `pubspec.yaml`.

## Prevent asset 404 errors

Flutter code uses logical paths:

```dart
rootBundle.loadString('assets/flows/en/onboarding/student_onboarding.json');
Image.asset('assets/reveal/1.webp');
```

Flutter Web requests these as `/assets/assets/...`; the doubled browser path is normal. A 404 means the logical file was not included in the asset manifest, the path/case is wrong, or a newly added asset requires a full restart/rebuild. Hot reload does not reliably update the web asset manifest.

Check all three:

1. The file exists with exact case.
2. Its directory is declared under `flutter.assets` in `pubspec.yaml`.
3. The app was stopped, rebuilt, and restarted.
