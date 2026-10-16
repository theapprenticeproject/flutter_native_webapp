# Testing and Operations

## Automated tests

```bash
flutter test
flutter analyze
npm run format:check
mkdocs build --strict
```

Current Flutter tests cover onboarding flow parsing, classroom stage resolution, learner/course submission index separation, local progress restoration, weekly limits, and archetype step selection.

Add tests when changing cache behavior, progress indexes, archetype mapping, weekly windows, flow JSON parsing, or API response models.

## Manual critical-path test

1. Login and select a learner profile.
2. Confirm Home displays the correct next unit and thumbnail.
3. Complete video, submission, and quiz; verify one final progress request.
4. Confirm XP and enrollment indexes increase once.
5. Choose **Maybe later** and return Home.
6. Reopen Class and verify the next unit does not start automatically.
7. Choose **Let's go** and complete the second unit.
8. Verify Home/Class show the weekly-complete state and no third unit starts.
9. Restart during a unit and confirm local stage recovery.
10. Test phone and desktop widths.

## Inspecting and repairing dev test learners

`scripts/frappe/dev_learner_tools.py` helps when a test account shows the wrong course or needs to run onboarding again. It is for the **dev** Frappe site only. Copy it to the server, then in the bench directory:

```bash
bench --site <site-name> console
```
```python
exec(open("/path/to/dev_learner_tools.py").read())
show_phone("9123456780")                      # profiles, learners, enrollments (read only)
set_course("TL00017435", "Basic-Electronics-science-lab-C2258")              # dry run
set_course("TL00017435", "Basic-Electronics-science-lab-C2258", apply=True)  # saves
reset_for_onboarding("9123456780", "TL00017435", apply=True)  # run onboarding again
```

- Every function prints the site name first. Check it before you apply anything.
- Writing functions only print what they would change until you pass `apply=True`.
- `set_course(..., ignore_links=True)` skips Frappe's check that the course exists as a record of the linked doctype. The dev site's working enrollments store the app's bundled course ids (like `Basic-Electronics-science-lab-C2258`), so a plain save may be refused.
- After a change, log out and back in (or use a private window), because the app reads cached learner state first.
- `show_schema()` and `course_names()` print the doctypes and fields the script depends on, if the backend changes.

## Rate limits

Worker limits are per Cloudflare client IP:

| Bucket                     | Limit         |
| -------------------------- | ------------- |
| Forgot-password OTP        | 5 per hour    |
| Tapbuddy/submission review | 20 per hour   |
| Other routes               | 60 per minute |

If KV is unavailable or errors, the current Worker fails open. Monitor KV errors because rate limiting is then inactive.

## Troubleshooting

### Asset returns 404

Confirm exact file case, `pubspec.yaml` declaration, and perform a full rebuild. Browser `/assets/assets/...` paths are expected for logical paths beginning with `assets/`.

### Learner state never changes

Inspect `/learner/submit-progress` for `progress_recorded`, `conflict`, and enrollment indexes. Confirm deployed Frappe implements the method targeted by the Worker.

### Wrong unit opens

Compare enrollment `videos_completed`, `submission_index`, and `quizzes_completed`. The current unit is the first unit whose required components are incomplete. Do not substitute the learner-wide submission index.

### Next unit starts after Maybe later

Inspect the cached Home continuation marker. It must be cleared only by **Let's go**, not when Class opens or **Maybe later** is selected.

### Protected endpoint returns 401

Check bearer format, token type, phone ownership, expiry, and whether Worker/Frappe JWT secrets match. A token returned in a successful response is a refresh and should replace the old token.

### AI endpoint returns 502

Check Groq credentials/model access and payload size. Image/audio URLs must be externally reachable. The Worker returns `invalid_model_response` when review JSON is invalid.

## Production signals

Monitor Worker request count, `401`, `429`, and `5xx` rates; Frappe method latency and job failures; progress conflicts; Groq failures; and frontend asset errors. Never log passwords, OTPs, bearer tokens, full student submissions, or secret values.
