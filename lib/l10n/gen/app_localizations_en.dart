// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get openLinkTitle => 'Open your TAP link';

  @override
  String get openLinkBody =>
      'Go to the WhatsApp message from TAP and tap the link in it. You will come back here and be ready to learn.';

  @override
  String get navHome => 'Home';

  @override
  String get navGallery => 'Gallery';

  @override
  String get navMe => 'Me';

  @override
  String get linkOpening => 'Opening your link...';

  @override
  String get linkNotWorkingTitle => 'This link is not working';

  @override
  String get linkNotWorkingMessage => 'Please ask for a new link on WhatsApp.';

  @override
  String get buttonOk => 'OK';

  @override
  String get buttonTryAgain => 'Try again';

  @override
  String get errorCourseNotReadyTitle => 'This course is not ready';

  @override
  String get errorCourseNotReadyMessage =>
      'We could not open your course. Please tell your teacher.';

  @override
  String get errorSessionEndedTitle => 'Please open your link again';

  @override
  String get errorSessionEndedMessage =>
      'Your session has ended. Open the link that TAP sent you on WhatsApp to carry on.';

  @override
  String get errorWaitTitle => 'Please wait a little';

  @override
  String get errorWaitMessage =>
      'Too many tries. Wait a minute, then try again.';

  @override
  String get errorNoCourseTitle => 'No course yet';

  @override
  String get errorNoCourseMessage =>
      'You are not in a course yet. Ask your teacher, then try again.';

  @override
  String get errorNoInternetTitle => 'No internet';

  @override
  String get errorNoInternetMessage =>
      'Check your internet connection, then try again.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericMessage => 'We could not load this. Please try again.';

  @override
  String get errorNotFoundTitle => 'We could not find you';

  @override
  String get errorNotFoundMessage =>
      'This phone number is not signed up for TAP yet. Please ask your teacher.';

  @override
  String get errorLimitTitle => 'That is all for now';

  @override
  String get errorLimitMessage =>
      'You have reached the limit for this activity.';

  @override
  String get homeTitle => 'Home';

  @override
  String homeCourseLabel(String course) {
    return 'Core $course 1';
  }

  @override
  String get homeCourseNotReady =>
      'Your course is not ready yet. Please tell your teacher.';

  @override
  String get homeCongrats => 'Congrats Champ!';

  @override
  String get homeActivityComplete => 'Activity\ncomplete 🥳';

  @override
  String get homeDoneForWeek => 'Done for the\nweek 🥳';

  @override
  String get homeKeepWinning => 'Keep winning';

  @override
  String get homePoints => 'Points';

  @override
  String get homeReadyForNext => 'Ready to continue with your next activity?';

  @override
  String get homeSeeYouNextWeek =>
      'See you next week champ with a new activity video!';

  @override
  String get homeLetsGo => 'Let\'s go 🎉';

  @override
  String get homePendingQuiz => 'Pending: Quiz';

  @override
  String get homeStartQuiz => 'Start Quiz';

  @override
  String get homeWeeklyLimit => 'Weekly limit reached';

  @override
  String get homeStartActivity => 'Start Activity';

  @override
  String get homeFeedbackReady => 'Feedback ready';

  @override
  String get homePendingFeedback => 'Pending: Feedback';

  @override
  String get homeFeedbackReadyText =>
      'Your feedback is ready! Tap to see what I think.';

  @override
  String get homeFeedbackSlowText =>
      'Your feedback is taking longer than expected. Please check again a little later.';

  @override
  String get homeFeedbackWaitingText =>
      'I\'m looking at your work. Please wait, and come back later to see my feedback.\n\nPoints will be provided after feedback.';

  @override
  String get homeSeeFeedback => 'See feedback';

  @override
  String get homeCheckAgain => 'Check again';

  @override
  String get homeToDoSend => 'To do: Send project';

  @override
  String get homeSendProject => 'Send my project';

  @override
  String get meTitle => 'Me';

  @override
  String get meSubtitle => 'Have a look at your progress';

  @override
  String meClass(String grade) {
    return 'Class $grade';
  }

  @override
  String meNextLevel(String name) {
    return 'Next: $name';
  }

  @override
  String get meTotalPoints => 'Total points';

  @override
  String get mePointsHelp =>
      'What are points? You earn them by doing TAP activities.';

  @override
  String get meProjectsTitle => 'My projects this year';

  @override
  String meProjectsDone(int done, int total) {
    return '$done / $total done';
  }

  @override
  String get meNoProjects =>
      'No projects yet. Finish an activity to see it here.';

  @override
  String get meSettings => 'Settings';

  @override
  String get switchProfileFailed =>
      'Could not switch profile. Please try again.';

  @override
  String get projectNotStarted => 'Not started';

  @override
  String get projectFeedbackPending => 'Feedback pending';

  @override
  String get projectSlow => 'Taking longer than expected';

  @override
  String get projectFeedbackGiven => 'Feedback given';

  @override
  String get projectWrongFormat => 'Wrong format';

  @override
  String get projectNotAccepted => 'Not accepted';

  @override
  String get projectNotSentDetail => 'You have not sent this project yet.';

  @override
  String get projectWaitingDetail =>
      'I\'m looking at your work. Please wait. Points will be provided after feedback.';

  @override
  String get projectSlowDetail =>
      'Your feedback is taking longer than expected. Please check again a little later.';

  @override
  String get projectValidDetail => 'Your project is valid. Well done!';

  @override
  String get projectNotValidDefault => 'This project needs another try.';

  @override
  String get projectNotValidHint =>
      'Open the activity from Home to send it again.';

  @override
  String get projectNotAcceptedDefault => 'This project was not accepted.';

  @override
  String get projectNotAcceptedHint =>
      'You have used both tries, so you cannot send it again.';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get gallerySubtitle => 'See what others made';

  @override
  String get galleryThisActivity => 'THIS ACTIVITY';

  @override
  String get galleryYourSubmission => 'Your submission';

  @override
  String get galleryFromStudents => 'From TAP students like you';

  @override
  String get galleryLoadFailed =>
      'We couldn\'t load the Gallery. Please try again.';

  @override
  String get galleryEmpty => 'No shared work yet. Be the first to share yours!';

  @override
  String get galleryLoadMoreFailed =>
      'We couldn\'t load more. Please try again.';

  @override
  String get galleryLoadMore => 'Load more';

  @override
  String get galleryShareWork => 'Share your work';

  @override
  String get galleryYouShared => 'You\'ve shared';

  @override
  String galleryVideoBy(String initials) {
    return 'Video by $initials';
  }

  @override
  String galleryWorkBy(String initials) {
    return 'Work by $initials';
  }

  @override
  String get galleryClose => 'Close';

  @override
  String get galleryPrevious => 'Previous';

  @override
  String get galleryNext => 'Next';

  @override
  String galleryPosition(int n, int total) {
    return '$n of $total';
  }

  @override
  String get gallerySwipe => 'Swipe to see more';

  @override
  String get galleryWantToShare => 'Want to share your work too?';

  @override
  String get galleryOpenVideo => 'Open video';

  @override
  String profileNotYou(String name) {
    return 'Not $name? Switch to your profile';
  }

  @override
  String get profileSwitch => 'Switch Profile';

  @override
  String get profilePickPrompt => 'Hi Champ, please select who I will talk to';

  @override
  String get profilesNone => 'No student profiles found for this account.';

  @override
  String get profilesLoadFailed => 'Could not load profiles. Please try again.';

  @override
  String get profileLoadFailed =>
      'Could not load that profile. Please try again.';

  @override
  String profileGrade(String grade) {
    return 'Grade $grade';
  }

  @override
  String get profileStudent => 'Student';

  @override
  String get profileSelected => 'Selected ✓';

  @override
  String get profileSelect => 'Select';

  @override
  String welcomeBack(String name) {
    return 'Welcome Back, $name!';
  }

  @override
  String get welcomeThere => 'there';

  @override
  String get welcomeNewYear => 'Are you ready for a New Year?';

  @override
  String get buttonContinue => 'Continue';

  @override
  String get splashWelcome => 'Welcome to TAP!';

  @override
  String get splashBroughtBy => 'Brought to you by MCD Delhi';

  @override
  String get splashGovt => 'Govt. of Delhi x TAP Initiative';

  @override
  String get errorPageTitle => 'Something went wrong';

  @override
  String get errorPageMessage =>
      'We had trouble loading this page. Please check your internet connection and try again.';

  @override
  String get errorPageButton => 'Try Again';

  @override
  String get errorPageDesktopTitle => 'Hey Champ\nI am not able to talk to you';

  @override
  String get errorPageDesktopMessage =>
      'Looks like you\'re offline. Click below to try again.';

  @override
  String get errorPageDesktopButton => 'Retry';

  @override
  String get headerSubtitle => 'Ready for today\'s class?';

  @override
  String headerHi(String name) {
    return 'Hi $name 👋';
  }

  @override
  String get loadingDefault => 'Loading...';

  @override
  String get settingsSectionLoadFailed => 'Could not load this section.';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get settingsProfileLoadFailed =>
      'Could not load your profile. Please try again later.';

  @override
  String get settingsNoProfile => 'No active profile found.';

  @override
  String get settingsPersonal => 'Personal Details';

  @override
  String get settingsFirstName => 'First name';

  @override
  String get settingsLastName => 'Last name';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSibling => 'Is a brother or sister also using TAP?';

  @override
  String get settingsYes => 'Yes';

  @override
  String get settingsNo => 'No';

  @override
  String get settingsPhone => 'Phone number';

  @override
  String get settingsVerified => 'Verified';

  @override
  String get settingsSchoolDetails => 'School Details';

  @override
  String get settingsSchoolName => 'School Name';

  @override
  String get settingsGrade => 'Grade';

  @override
  String get settingsSubject => 'Subject';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get settingsSaveChanges => 'Save Changes';

  @override
  String get settingsTabProfile => 'Profile';

  @override
  String get settingsTabAbout => 'About TAP';

  @override
  String get classFileReadFailed =>
      'Couldn\'t read that file. Please try again.';

  @override
  String get classFileAccessFailed =>
      'Couldn\'t access that. Please try again.';

  @override
  String get classTakePhoto => 'Take a photo';

  @override
  String get classChoosePhoto => 'Choose photo from gallery';

  @override
  String get classRecordVideo => 'Record a video';

  @override
  String get classChooseVideo => 'Choose video from gallery';

  @override
  String get classTodaysActivity => 'TODAY\'S ACTIVITY 🏎️🏎️';

  @override
  String classStep(int n, int total) {
    return 'STEP $n/$total';
  }

  @override
  String classWillCheck(String criteria) {
    return 'I will check for: $criteria';
  }

  @override
  String get classFileLoadFailed =>
      'We couldn\'t load that file. Please try picking it again.';

  @override
  String get classHintText => 'Type your answer here...';

  @override
  String get classHintAudio => 'Type or transcribe your answer here...';

  @override
  String get classShareSubmission => 'Share submission';

  @override
  String get classSubmit => 'Submit';

  @override
  String get classSent => 'Sent';

  @override
  String get classDoLater => 'I\'ll do it later';

  @override
  String get classFriendsSent => 'Friends sent 👀';

  @override
  String get classFriendsSaid => 'Friends said 👀';

  @override
  String get classSeeFriends => 'See what friends made 👀';

  @override
  String get classKindEmoji => '👉 EMOJI';

  @override
  String get classKindText => '💬 TEXT';

  @override
  String get classKindAudio => '🎤 AUDIO';

  @override
  String get classKindTextAudio => '💬 TEXT / 🎤 AUDIO';

  @override
  String get classKindPhoto => '📷 PHOTO';

  @override
  String get classKindVideo => '🎥 VIDEO';

  @override
  String get classKindPhotoVideo => '📷 PHOTO / 🎥 VIDEO';

  @override
  String get classHowToSubmit => 'How to submit';

  @override
  String classCheck(String criteria) {
    return 'Check: $criteria';
  }

  @override
  String classScore(String score) {
    return 'Score: $score';
  }

  @override
  String get classNoSubmissionPoints =>
      'No submission points were added for this attempt.';

  @override
  String classCongratsName(String name) {
    return 'Congratulations $name!!!🥳';
  }

  @override
  String classPointsPill(int points) {
    return '⊙ +$points pts';
  }

  @override
  String classWonPoints(int points) {
    return 'You have won $points points🪙😍\nYou did a great job champion!';
  }

  @override
  String get classSubmissionHelp => 'Submission Help';

  @override
  String get classWantToContinue => 'Want to continue?';

  @override
  String get classStartNext => 'Start the next activity when you are ready.';

  @override
  String get classLetsGo => 'Let\'s go';

  @override
  String get classMaybeLater => 'Maybe later';

  @override
  String get classBackHome => 'Back to home';

  @override
  String get classCourseComplete => 'Course complete! 🎉';

  @override
  String get classCourseCompleteBody =>
      'You completed every activity in this course.';

  @override
  String get classWatchAnother => 'Watch another video?';

  @override
  String get classYoullEarn => 'YOU\'LL EARN';

  @override
  String get classDidWell => 'You did really well! 🎉';

  @override
  String get classFinishedForNow =>
      'You\'ve finished your activities for now. Come back soon for the next one!';

  @override
  String get classTodaysPicture => 'Today\'s picture';

  @override
  String get classPictureUnlocked =>
      'Congratulations !!🎉 You have unlocked today\'s picture';

  @override
  String get classPictureLocked =>
      'Finish each step to open today\'s secret picture! ✨';

  @override
  String classPictureSemantics(int n) {
    return 'Today\'s picture, $n of 4 pieces';
  }

  @override
  String classQuizQuestion(int n, String question) {
    return 'Q$n. $question';
  }

  @override
  String classQuizOf(int n, int total) {
    return 'Question $n of $total';
  }

  @override
  String get classConfirm => 'Confirm';

  @override
  String classCorrectPoints(int points) {
    return 'Correct! +$points points';
  }

  @override
  String get classCorrect => 'Correct!';

  @override
  String get classNotQuite => 'Not quite';

  @override
  String classCorrectAnswerIs(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get classQuizDone => 'Quiz done!';

  @override
  String classQuizScore(int correct, int total) {
    return 'You got $correct out of $total correct.';
  }

  @override
  String get classWatchVideo => 'Watch the video 👇';

  @override
  String classWatchTitle(String title) {
    return 'Watch: $title';
  }

  @override
  String get classWatched => 'Watched';

  @override
  String classIWatched(int points) {
    return 'I watched it • +$points points';
  }

  @override
  String get classSomethingWrong => 'Something went wrong.';

  @override
  String get classTapBuddy => 'TAP Buddy';

  @override
  String get chatSaveVideoFailed =>
      'We could not save that you watched the video. Please check your connection and retry.';

  @override
  String chatVideoReward(String name, int points) {
    return 'Wow! That’s amazing 🤩  $name, you just earned $points points🪩 for watching the video 🥳🥳🥳\n\nNow it’s time to do the activity submission 🌟';
  }

  @override
  String get chatTryPractice =>
      'That\'s a good try — let\'s keep practicing this one.';

  @override
  String get chatSlowFeedback =>
      'Your feedback is taking longer than expected 🕒\nPlease check again a little later.';

  @override
  String get chatWaitingFeedback =>
      'I\'m looking at your work 👀\nPlease wait. Come back later to see my feedback!\n\nPoints will be provided after feedback.';

  @override
  String get chatBackHome => 'Back to Home';

  @override
  String get chatValidDefault => 'Great work! Your project is valid ✅';

  @override
  String get chatAskPoints =>
      'Do you want to know your total points collected so far?';

  @override
  String get chatYesYesYes => 'Yes Yes Yes 😍';

  @override
  String get chatWonTitle => 'YOU WON! 🏆';

  @override
  String chatWonEarned(int points) {
    return 'Your valid work earned +$points points 🪙';
  }

  @override
  String chatWonTotal(int total) {
    return 'Your points: $total 🪙';
  }

  @override
  String chatSendCorrected(String reason) {
    return '$reason\n\nNo worries; please send it again!';
  }

  @override
  String chatNoMoreTries(String reason) {
    return '$reason\n\nYou have used both tries, so you cannot send this work again.';
  }

  @override
  String get chatSendAgain => 'Send again';

  @override
  String get chatReadyShare => 'Are you ready to share your work? 📸';

  @override
  String get chatYesLetsGo => 'Yes, let\'s go';

  @override
  String get chatNotToday => 'Not today';

  @override
  String get chatFileTooBig =>
      'That file is too big 😅\nPlease choose a smaller photo or a shorter video.';

  @override
  String get chatSubmitAgain => 'Submit Again';

  @override
  String get chatAlreadySent => 'You already sent this work. Let\'s go on! 💪';

  @override
  String get chatSendWorkFailed =>
      'We could not send your work. Please check your connection and retry.';

  @override
  String get chatSaveSubmissionFailed =>
      'We could not save your completed submission. Please check your connection and retry.';

  @override
  String get chatProTip =>
      'Pro tip: Take the photo in good light and show your full work 📸✨\n\nI’m excited to see what you made😅\nYou can do this! ⭐💪';

  @override
  String get chatQuizComplete => 'Quiz complete!';

  @override
  String chatStartQuiz(String unit) {
    return 'Let’s start the $unit quiz🚀🚀🚀';
  }

  @override
  String get chatQuizButton => 'Quiz';

  @override
  String chatTodayPlay(String unit) {
    return 'Today we\'re going to play with $unit.\nWatch a short video, then make your own project.';
  }

  @override
  String get chatWatchButton => 'Watch';

  @override
  String chatFinalWin(int activity, int quiz) {
    return 'Activity Points    $activity 🪙\nQuiz Points    $quiz 🪙';
  }

  @override
  String get chatSaveQuizFailed =>
      'We could not save your quiz result. Please check your connection and retry.';

  @override
  String get chatQuizTotals =>
      'Great job Champ!\nDo you want to know your total points collected so far?';

  @override
  String get chatSaveSubmissionStill =>
      'Still could not save your submission progress. Please check your connection and retry.';

  @override
  String get chatSaveVideoStill =>
      'We still could not save the video checkpoint. Please check your connection and retry.';

  @override
  String get chatSaveGeneric => 'Something went wrong saving your progress.';

  @override
  String get chatWatchedEcho => 'I watched it';

  @override
  String get chatLaterEcho => 'I\'ll do it later 🕒';

  @override
  String chatPraise(String name, int points) {
    return 'I am SO proud of you $name 🥹 That\'s the spirit! [+$points pts]';
  }

  @override
  String get classPictureFullTitle => 'You opened the full picture! 🥳';

  @override
  String get classPictureFullBody =>
      'You finished all 4 steps. Great job, champ!';

  @override
  String classPicturePartTitle(int n) {
    return '$n of 4 pieces opened';
  }

  @override
  String get classPicturePartBody =>
      'Finish each step to open the whole picture';

  @override
  String get chatVideoRepeat =>
      'Points are given only the first time you watch the video 🎬\n\nNow it’s time to do the activity submission 🌟';

  @override
  String get chatSendCorrectedOnly =>
      'Hi Champ 👋\nI couldn\'t review your work 🥺 Because the photo was either a bit unclear or not of today\'s activity.\n\nNo worries; please send it again!';

  @override
  String get chatNotAccepted =>
      'I couldn\'t review your work 🥺 Because the photo was either a bit unclear or not of today\'s activity.';

  @override
  String get profileWelcome => 'Welcome';

  @override
  String profileClass(String grade) {
    return 'Class $grade';
  }

  @override
  String get classStepWatch => 'Watch';

  @override
  String get classStepMake => 'Make';

  @override
  String get classStepQuiz => 'Quiz';

  @override
  String get classStepResults => 'Results';
}
