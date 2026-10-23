# UI gaps: Figma "Student App Direction" vs the app

Source: six PNG exports in `/home/rjs/dev/tap/app_design_v1/Student App Direction/`
(F1 Who is learning, F2 Home, F3 Event, F4 Class, F5 Gallery, F6 Me).

How this was made: I looked at the exported images and skimmed the app code.
I did not run the app. I could not read the Figma file itself (no edit access),
so colors, fonts and spacing below are read from images. They are close, not exact.
Check them in Figma before you build.

## Decision from the designer (after the meeting)

There is **no "Class" tab**. The bottom nav has **3 items: Home, Gallery, Me**.
The mockups for F2, F3 and F5 still show 4 tabs. Those mockups are old on this point.

What this means:
- F4 "Class" is not a tab. It is the **activity flow** (Watch, Make, Quiz, Results).
  The learner opens it from Home (Start Activity, Continue, Join).
- The app today has 4 tabs: Home, Class, Passport, Profile.

## Summary

| Figma screen | App today | Gap |
|---|---|---|
| Bottom nav | 4 tabs (Home, Class, Passport, Profile) | Change to 3 tabs: Home, Gallery, Me |
| F1 Who is learning | `profile_select_screen.dart` | Small to medium |
| F2 Home | `home_screen.dart` | Medium |
| F3 Event | None | New (needs product answers) |
| F4 Class / activity flow | `class_screen.dart` | Medium to large |
| F5 Gallery | None (Passport is different) | New |
| F6 Me | `passport_screen.dart` + `settings_screen.dart` | Large (merge and redo) |

## Shared pieces

- **Bottom nav** (`lib/shared/widgets/app_nav.dart`):
  - Go from 4 items to 3: Home, Gallery, Me.
  - Remove the Class route as a tab. Keep it as a pushed route from Home.
  - Rename Passport to Gallery and Profile to Me.
  - The active tab is a filled purple block with white text. The app already does this.
  - Inactive icons in the design are dark grey rounded squares. The app already does this too.
  - Check the new item widths.
- **Header** (`lib/shared/widgets/app_header.dart`):
  - Design: TAP and government logos as two small grey chips (top left).
  - Below that: "Hi Aarav 👋", a points pill ("3 Points"), and an "Ask TAP" pill.
  - The app header is a different layout, with a bigger brand block and dividers.
  - Build one new header for Home, Gallery and Me.
- **Back header for the activity flow** (F3, F4):
  - Design: round back button, title or points pill, "Ask TAP" pill.
  - The app has a long bar with dividers and a large back icon.
- **Theme** (`lib/core/theme/app_theme.dart`):
  - The purple (`#5B5BD6`) and the Inter font look the same as the design.
  - Missing: a full text style set. Only 2 styles exist today.
  - Missing: shared tokens for the pill shape, the card radius and the light purple chip color.
  - Many screens use raw colors instead. Move them into the theme before building new screens.
- **Reusable widgets to add**:
  - Pill / chip (time left, points, status)
  - Avatar with initials ("AK")
  - Primary button
  - Soft purple button ("Load more", "Ask TAP")
  - Card with image placeholder
  - Status tags (Feedback pending, Wrong format, You've shared)

## F1: Who is learning

Screens: choose a profile, a profile selected, "Welcome Back, Aarav! Are you ready for a New Year?".

- **Design**:
  - Big round buddy picture.
  - Title "Welcome" and the line "Hi Champ, please select who I will talk to".
  - A "Hear again" button (reads the text aloud).
  - Profile rows with initials, "Class 5 • Science", and a Select button.
  - The picked row gets a purple border and a "Selected ✓" tag.
  - A Continue button appears after you pick one.
  - Then a welcome-back screen with a larger picture.
- **App today**: title "Who's learning today?", a list of profiles, no buddy picture,
  no "Hear again", different wording.
- **To do**:
  - Redo the layout and add the picture.
  - Add the "Hear again" button. This needs text-to-speech. Ask if it is in scope.
  - Add the selected state and the Continue button.
  - Add the welcome-back screen.

## F2: Home

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
- **To do**:
  - Restyle the cards to the new look.
  - Add the event banner (new).
  - Check that every stage in the app has a design.
    The design shows only "start" and "send submission". There is no design for quiz pending or completed.

## F3: Event (Builder Festival)

- **Design**: an event card, a chat with the buddy, a video card, an "I want to take part" button,
  day choices (Today, Tomorrow, Saturday, Sunday), and a reminder message.
  The event card shows a "12,480 students across India are taking part" strip.
- **App today**: nothing like it.
- **Questions for product**:
  - Where does event data come from? Does the server have an API for events?
  - Is this chat scripted, or does it use the buddy API?
  - The "students across India" number: is it real data?
- **To do**: do not start until these are answered. Build it last.

## F4: Class (activity flow)

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
- **To do**:
  - Compare the app one frame at a time after the shared parts are done.
  - Add the step bar if it is missing.
  - Restyle the chat bubbles and the cards.
  - Check the voice-recording frames. Voice notes may not exist in the app yet.
  - Zoom into the 11251px export in Figma for detail. It was too small to read here.

## F5: Gallery (new tab)

- **Design**:
  - Header, then "THIS WEEK'S ACTIVITY", the activity title, a time-left pill and a points pill.
  - "Your submission": shows your work with a "You've shared" tag.
    If you have not shared, it shows a dashed box and a "Share your work" button.
  - "From TAP students like you": a two-column grid of other learners' work with name and initials. A "Load more" button.
  - Full-screen viewer: "1 of 9", a close button, previous and next arrows, "Swipe to see more".
    It has a "Want to share your work too?" prompt for learners who have not shared.
- **App today**: Passport. It is a different feature, so this is a new screen.
- **Questions for product**:
  - Does the server have an API for learner submissions that other students can see?
  - What about privacy and checking content before it is shown to others?
  - What happens to the current Passport content?
- **To do**: new screen, grid and viewer widgets, and a provider. The data side is the risk.

## F6: Me

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
- **To do**:
  - Merge them into one Me screen.
  - Add the levels, the projects path map and the feedback detail screens (new).
  - Add the theme switch (default, light, dark). The app has only a light theme today. Dark theme is a big task. Ask if it is in scope.
  - Add "Read messages aloud". This needs text-to-speech.
  - Check that profile sheets match the design.

## Things the design needs that the app may not have

- Text-to-speech ("Hear again", "Read messages aloud", the speaker icons on chat bubbles)
- Dark theme
- Events
- Gallery of other learners' work
- Skill chips and buddy levels (check the learner data)
- Voice-note recording

## Suggested order

1. **Theme and shared widgets**: text styles, tokens, pill, avatar, buttons, new header.
2. **Nav**: 3 tabs, with Class as a pushed route.
3. **F1** profile select and welcome back.
4. **F2** Home restyle.
5. **F4** activity flow restyle, one step at a time.
6. **F6** Me, then **F5** Gallery. Both depend on product and API answers.
7. **F3** Event, last.

Each step is its own commit on its own branch, so you can review it by itself.

## Open questions

1. Is text-to-speech in scope?
2. Is dark theme in scope?
3. Events and Gallery: which APIs exist? Who owns them?
4. What happens to Passport content (points, gems, streak, skill passport)? Does it move into Me?
5. Can we get edit access to the Figma file? It gives exact colors, sizes and fonts.
