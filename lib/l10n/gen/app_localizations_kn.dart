// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

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
}
