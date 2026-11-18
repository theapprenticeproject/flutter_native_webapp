// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

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
}
