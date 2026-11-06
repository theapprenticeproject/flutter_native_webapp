# UI gaps: Figma "Student App Direction" vs the app

Source: the design has six screens (Screen 1 Who is learning, Screen 2 Home, Screen 3 Event, Screen 4 Class, Screen 5 Gallery, Screen 6 Me). The **45 separate frames** are PNG files in `/home/rjs/Documents/TAP/Requirements/student-app-direction-export/`. The first six large exports are in `/home/rjs/dev/tap/app_design_v1/Student App Direction/`.

**Names:** "Screen 1" to "Screen 6" are the screens of the design. "F-1" to "F-8" are the frames that must be corrected (in the requirements). They are different lists.

**Updated 2026-11-05** to follow `v1-requirements.md`. **The requirements always win.** Where the design and the requirements differ, we follow the requirements. The Figma frames that must be corrected are listed in section 3 of the requirements, "Figma frames that need correcting" ("F-1" to "F-8"). The R-numbers below point to the requirements. The task numbers (D1, D2 and so on) are in `v1-task-breakdown.md`.

How this was made: I looked at the exported images and skimmed the app code.
I did not run the app. I could not read the Figma file itself (no edit access),
so colors, fonts and spacing below are read from images. They are close, not exact.
Check them in Figma before you build.

## Decisions that change the design

- **3 tabs, no Class tab** (R-1, R-2). The bottom nav has Home, Gallery and Me. The mockups for Screen 2, Screen 3 and Screen 5 still show 4 tabs (F-3). Screen 4 "Class" is the **activity flow** (Watch, Make, Quiz, Results). The student opens it from Home.
- **The v1 test release is mid-November** for 30 to 100 kids. The flow is hardcoded and linear (R-61).
- **No deadline in v1** (R-72). Remove the countdown and the "time left" pills (F-8).
- **No theme switch in v1** (R-73, F-4). The app stays light.
- **No weekly limit in v1** (R-39). **Streaks are paused** (section 2 of the requirements), and **gems are not in the design**.
- **Points follow R-75**, not the numbers in the frames (F-5): video +10, work shared +25, each correct quiz answer +1, correct work +10 after valid feedback.
- **Events and the announcement banner are later (v1.1)** (R-5, R-86). Home keeps an empty place for a banner (R-94).
- **Edit profile is later** (R-74). Voice notes are later (R-10, R-65). Text submissions are later (R-63).
- **Messages never play by themselves** (R-17). The speaker icon plays a pre-recorded audio clip. There is **no text-to-speech**.

## Summary

| Figma screen | App today | In v1? | Gap |
|---|---|---|---|
| Bottom nav | 4 tabs (Home, Class, Passport, Profile) | Yes (R-1) | Change to 3 tabs: Home, Gallery, Me (task D1) |
| Screen 1 Who is learning | `profile_select_screen.dart` | Yes (R-3) | Small to medium (D1, D2) |
| Screen 2 Home | `home_screen.dart` | Yes (R-4) | Medium (D7) |
| Screen 3 Event | None | **No, v1.1** (R-5, R-86) | Not built in v1 |
| Screen 4 Class / activity flow | `class_screen.dart` | Yes (R-61 to R-70) | Medium to large (D3 to D6) |
| Screen 5 Gallery | None (Passport is different) | The tab: yes. The content: P2 (D9) | New |
| Screen 6 Me | `passport_screen.dart` + `settings_screen.dart` | Yes, without Edit profile (R-7) | Large (D8) |

## Shared pieces

- **Bottom nav** (`lib/shared/widgets/app_nav.dart`):
  - Go from 4 items to 3: Home, Gallery, Me.
  - Remove the Class route as a tab. Keep it as a pushed route from Home.
  - Rename Passport to Gallery and Profile to Me.
  - The active tab is a filled purple block with white text. The app already does this.
  - Inactive icons in the design are dark grey rounded squares. The app already does this too.
  - Check the new item widths.
  - The Gallery tab always exists, also when the Gallery has no content yet. Then it shows the curriculum's example works (R-1, R-58).
- **Header** (`lib/shared/widgets/app_header.dart`):
  - Design: TAP and government logos as two small grey chips (top left).
  - Below that: "Hi Aarav 👋", a points pill ("3 Points"), and an "Ask TAP" pill.
  - The app header is a different layout, with a bigger brand block and dividers.
  - Build one new header for Home, Gallery and Me.
  - The points pill shows the total from the server (R-75). In the Results step, the header points update **after the "Yes" tap**, when the "YOU WON" card shows them, so the reveal is not spoiled (R-68).
- **Back header for the activity flow** (Screen 4):
  - Design: round back button, title or points pill, "Ask TAP" pill.
  - The app has a long bar with dividers and a large back icon.
- **Theme** (`lib/core/theme/app_theme.dart`):
  - The purple (`#5B5BD6`) and the Inter font look the same as the design. The accent color may change to green: not decided (R-8).
  - Missing: a full text style set. Only 2 styles exist today.
  - Missing: shared tokens for the pill shape, the card radius and the light purple chip color.
  - Many screens use raw colors instead. Move them into the theme before building new screens.
  - Fonts are bundled in the app. The page must not download a font. Replace the 7.6 MB loader GIF with a light one (R-43, task D0).
- **Reusable widgets to add**:
  - Pill / chip (points, status)
  - Avatar with initials ("AK")
  - Primary button
  - Soft purple button ("Load more", "Ask TAP")
  - Card with image placeholder
  - Status tags (Feedback pending, Wrong format, You've shared)
  - Speaker icon for chat messages (plays a clip, see "Audio" below)
  - Today's picture badge, 0/4 to 4/4 (R-69, task D16)
- **Offline screen** (R-71): "I am not able to talk to you. Looks like you're offline", with a Retry button. One exception: a quiz that has already started can be finished without a network (R-91).

## Screen 1: Who is learning

Screens: choose a profile, a profile selected, "Welcome Back, Aarav! Are you ready for a New Year?".

- **Design**:
  - Big round buddy picture.
  - Title "Welcome" and the line "Hi Champ, please select who I will talk to".
  - A "Hear again" button.
  - Profile rows with initials, "Class 5 • Science", and a Select button.
  - The picked row gets a purple border and a "Selected ✓" tag.
  - A Continue button appears after you pick one.
  - Then a welcome-back screen with a larger picture.
- **App today**: title "Who's learning today?", a list of profiles, no buddy picture,
  no "Hear again", different wording.
- **In v1** (R-3, R-32, R-34):
  - The student opens the app from the WhatsApp magic link. The link carries the phone.
  - If the phone has one child, the app goes straight in. If it has several, the student picks a name.
  - There is no password and no onboarding in the app. The kids are already registered.
  - The student can switch profile later from Me.
  - No photos of students. The TAP Buddy picture is used (R-60).
- **To do** (tasks D1, D2):
  - Redo the layout and add the picture.
  - "Hear again" plays a **pre-recorded clip** (R-17, R-62). It is not text-to-speech. Hide the button when the message has no clip in the student's language (R-54, R-55).
  - Add the selected state and the Continue button.
  - Add the welcome-back screen.
  - Use the translated fallback for "Champ" when the name is missing (R-25).

## Screen 2: Home

- **Design**:
  - Header (logos, "Hi Aarav 👋", points pill, "Ask TAP").
  - An optional **event banner** at the top (light purple). It shows the event name, a short line, and a "Starts in 3 days" pill.
    Its button is Join or Continue.
  - One big **activity card**: image, title, "+40 points" tag, and a Start Activity button.
    A "Pending: Submission" tag and a time-left tag show up when a submission is waiting.
    In that state the button says "Send Submission".
- **App today**: a stage-based dashboard (`start_activity_card`, `send_project_card`,
  `quiz_pending_card`, `completed_card`, a card deck).
  The idea matches, but the look and layout differ.
- **In v1** (R-4, R-83, R-94):
  - Home shows **one** activity card. The next activity opens only after valid feedback for the one before.
  - The card states are: start, submission pending, send submission.
  - The banner place is **empty in v1**. The app reads banners from one place in the Worker, which returns an empty list. Keep the room above the card.
  - No time-left tag (R-72).
  - The points on the card: **not decided** (open question 3). R-75 gives points for each step, not one total, so "+40" is not right.
- **To do** (task D7):
  - Restyle the cards to the new look.
  - Keep the banner place (empty).
  - Check that every state in the app has a design. The design shows only "start" and "send submission". There is no design for "quiz pending" or "completed". The designer has to add them or confirm that we reuse the existing ones.

## Screen 3: Event (Builder Festival)

**Later (v1.1).** Not built in v1 (R-5, R-86). Events are a new feature in `frappe_tap`. They are standalone, not linked to a course, and only one event is active for a batch at a time.

- **Design**: an event card, a chat with the buddy, a video card, an "I want to take part" button,
  day choices (Today, Tomorrow, Saturday, Sunday), and a reminder message.
  The event card shows a "12,480 students across India are taking part" strip.
- **For v1**: only leave room for it (R-94). Do not build the screen.
- **Still open for v1.1**: is the chat scripted or does it use the buddy API? Is the "students across India" number real data?

## Screen 4: Class (activity flow)

About 30 frames. This is the biggest design.

- **Design**:
  - Four steps at the top: Watch, Make, Quiz, Results.
  - Chat style with the buddy.
  - Video card with a big purple play button.
  - Make step: write, photo, and voice-note modes.
  - Camera and gallery picker as a bottom sheet.
  - A TAP Buddy help panel.
  - Feedback and error states (wrong format, send again).
  - Quiz cards with right and wrong answers.
  - Result screens with big prize pictures ("WOW Champ", "10 points").
  - A floating buddy button at the bottom right.
- **App today**: `class_screen.dart` and the widgets in `classroom/presentation/widgets/`.
  The pieces exist (video, submission, quiz, reveal, checkpoint).
- **In v1:**
  - **The steps, in this order:** Watch, Make, Quiz, Results, with a step bar (R-61).
  - **Watch (R-62, R-90, D3):** the intro with "Hear again", then the video (YouTube, about 10 minutes). The student taps **"I watched it"**. The button turns on after 5 minutes. It gives +10. The app does not check the video. The Figma has no frame for this button (F-7).
  - **Make (R-63, R-64, R-66, D5):** a **photo or a video** only. The student can take or choose it, sees a preview, and sends. The video is limited to 90 seconds (R-9). A refused camera gives a clear message (R-11). A failed upload does not lose the work (R-13). The student can choose **"I'll do it later"**: the app goes on to the Quiz and asks again after it. The text and voice versions are later.
  - **Quiz (R-67, R-91, D4):** text questions only. All questions come together, and the app gives right or wrong at once. The answers are sent when the quiz ends. The server checks them again and its result counts. A started quiz can be finished offline.
  - **Results (R-68, R-16, D6, D13, D17):** feedback messages, each with a speaker icon. Then "Yes" for the total points, and a "YOU WON" card that waits for the tap. If the feedback is not ready, the app shows a waiting screen (F-6) and a "taking longer than expected" state. The Results step also opens from the WhatsApp feedback link. If the work is **not valid**, the student gets 0 points, sees why and must **send again** (R-76).
  - **Today's picture badge** (R-69, D16): 0/4 to 4/4 on every screen. The 4th piece unlocks only after valid feedback. The badge and the Results step wait for the server's result.
  - **Ask TAP** (R-70, D10): a help panel with **prepopulated questions** for the step. No text box and no microphone. This is P2.
  - **Audio** (R-17, D15): the speaker icon on a message plays a clip when the student taps it. The feedback audio uses the same player (R-56).
- **To do**:
  - Compare the app one frame at a time after the shared parts are done.
  - Add the step bar if it is missing.
  - Restyle the chat bubbles and the cards.
  - Skip the voice-recording frames and the text mode (later).
  - Ask the designer for the missing frames: "I watched it" (F-7), the waiting screen label (F-6), the "not valid" state, the quiz states (answers could not be sent, quiz continues) and "taking longer than expected".
  - Use the 45 separate frames in `student-app-direction-export/` for detail. The large export was too small to read.

## Screen 5: Gallery (new tab)

- **Design**:
  - Header, then "THIS WEEK'S ACTIVITY", the activity title, a time-left pill and a points pill.
  - "Your submission": shows your work with a "You've shared" tag.
    If you have not shared, it shows a dashed box and a "Share your work" button.
  - "From TAP students like you": a two-column grid of other learners' work with name and initials. A "Load more" button.
  - Full-screen viewer: "1 of 9", a close button, previous and next arrows, "Swipe to see more".
    It has a "Want to share your work too?" prompt for learners who have not shared.
- **App today**: Passport. It is a different feature, so this is a new screen.
- **In v1** (R-6, R-58, R-59, R-85, R-88, D9):
  - The tab always exists. Without content it shows the curriculum's **example works**, which are not other students' work (R-58).
  - Other students' work is shown only if its feedback says it is **valid**. Only pictures and videos. The order is random. A few items at a time (5 to 10). Each shows **initials only** (R-59, R-85).
  - The Gallery reads **copies in R2**, made after valid feedback. The student's own work stays private in GCS (R-88).
  - No time-left pill (R-72).
  - **Frame mismatches** (frame "M-GA-02 · Gallery — not shared yet"): (a) each card shows a **name** ("Priya S.") next to the initials chip, but R-85 says **initials only**; (b) the caption "Class 4 · same activity · shared from schools across TAP" says the work is filtered by class and activity, but in v1 the order is random and any valid work is shown (R-85); (c) the pill "Ends in 2 days 15 hrs" and the text "Share it before the timer ends to earn +25 points" show a deadline, which v1 does not have (R-72), and the points follow R-75. The designer has to fix these frames.
  - The designer says the Gallery design is still being shaped (R-6).
  - The Gallery content is **P2**: it can follow the first test.
- **To do**: the tab and an empty state with the examples first. Then the grid, the viewer and a provider (task D9). The data side is the risk.
- **Passport content**: Passport is replaced by Me (R-7). Streaks are paused (section 2) and gems are not in the design.

## Screen 6: Me

About 10 frames.

- **Design**:
  - "Not Aarav? Switch to your profile" strip with a Switch profile button.
  - Profile card (name, verified tick, class, school, Edit profile).
  - Buddy level picture and skill chips ("Making new things").
  - Level bar ("Bronze Buddy", "120 / 400 points").
  - Total points card with a "What are points?" hint.
  - A "My projects this year" path map (3 / 6 done).
  - Project detail and feedback screens ("Feedback pending", "Feedback given", "Wrong format").
  - Edit profile form.
  - Settings sheet (app language, read messages aloud, theme: default, light, dark).
  - Switch Profile sheet.
- **App today**: Passport (points, gems, streak) and Profile/Settings (`settings_screen.dart`,
  `profile_details_view.dart`, `profile_switcher.dart`). They are two separate places.
- **In v1** (R-7, R-73, R-74, R-87, R-95, D8):
  - One Me screen: profile, level, points, "My projects this year", project feedback screens, settings and switch profile.
  - **Edit profile is later** (R-74). Do not build the form or the save call. Show the profile data only.
  - **Level names and thresholds** are server settings (R-41).
  - **"My projects"** reads the submissions, the feedback (valid or not), the points and the course's assignments. There are 6 projects a year (R-87).
  - **Skill chips** are placeholders: a fixed list, the same for every student. The curriculum team gives the tags (R-95).
  - **Settings:** app language and account options. **No theme switch** (R-73, F-4). The messages are not read aloud automatically (R-17). The speaker icons on messages replace "read messages aloud".
  - **No Sign out** in v1 (R-35). "Deactivate" and "Delete account" are later (R-36).
- **To do**:
  - Merge Passport and Profile into one Me screen.
  - Add the levels, the projects path map and the feedback detail screens (new).
  - Check that the Switch Profile sheet matches the design.

## Things the design needs that the app may not have

| Item | Status |
|---|---|
| Text-to-speech | **Not needed.** Messages use pre-recorded clips (R-17). |
| Dark theme | **Not in v1** (R-73). |
| Events | **Later, v1.1** (R-5, R-86). |
| Gallery of other learners' work | **P2.** The tab and the examples come first. |
| Skill chips | Fixed placeholders (R-95). |
| Buddy levels | Server settings (R-41). |
| Voice-note recording | **Later** (R-10, R-65). |
| Edit profile | **Later** (R-74). |
| Audio player for clips | **New, needed** (R-17, R-56, task D15). |
| Today's picture badge | **New, needed** (R-69, task D16). |

## Suggested order

This follows the task list (`v1-task-breakdown.md`, group D).

1. **Clean up and the theme** (D0): remove hard-coded values, streaks and gems, bundle the fonts, text styles, tokens, shared widgets, the new header. Put the **Hindi and English text** (D14) in place here, so new screens use translation files from the start.
2. **App shell and nav** (D1): 3 tabs, with Class as a pushed route, the offline screen.
3. **Login screens** (D2): the magic link, the name picker, switch profile. And **Screen 1** (the welcome-back screen).
4. **Screen 4 the activity flow, one step at a time**: Watch (D3), Make (D5), Quiz (D4), then the **audio player (D15) before Results**, because Results uses the speaker icons (D6 depends on D15), then Results (D6, D17) and the badge (D16). Add the **interaction events** (D18) after the Quiz (D4) and Results (D6) exist, because it logs their steps.
5. **Screen 2 Home** (D7).
6. **Screen 6 Me** (D8).
7. **Feedback link** (D13) if the product team approves it (O-28).
8. After the first test (P2): **Screen 5 Gallery** content (D9) and **Ask TAP** (D10).
9. **Screen 3 Event** is v1.1.

Each step is its own commit on its own branch, so you can review it by itself.

## Open questions

Answered since the first version:
- Text-to-speech: not in scope. Clips are used (R-17).
- Dark theme: not in v1 (R-73).
- Events: v1.1 (R-86).
- Gallery data: the Worker reads copies in R2 (R-85, R-88).
- Passport content: replaced by Me. Streaks are paused (section 2) and gems are not in the design (R-7).

Still open:
1. Can we get edit access to the Figma file? It gives exact colors, sizes and fonts (task A4).
2. The designer has to fix the frames in F-1 to F-8 and add the missing ones:
   - "I watched it" (F-7) and the waiting label (F-6);
   - "quiz pending" and "completed" on Home, and the "not valid" state;
   - **new quiz states:** the answers could not be sent (with Retry), and the student comes back and the quiz continues from the saved answers (R-91);
   - the **Gallery frames**: initials only, no "Class 4 · same activity" caption, no timer;
   - **"taking longer than expected"** when the feedback does not arrive (task D17, decision A13).
3. **What does the Home card show for points, if anything?** The design shows "+40 points". R-75 gives points for each step (video +10, sharing +25, each correct quiz answer +1, valid work +10), not one total for the activity. Neither the requirements nor the docs say which number the card shows. Options: show nothing, show the sum of the steps, or show only the steps that give points at once. The product team has to decide (R-4).
4. Does the accent color change to green (R-8)?
5. The Gallery design is still being shaped (R-6).
