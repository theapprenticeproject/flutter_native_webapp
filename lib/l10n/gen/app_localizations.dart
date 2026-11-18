import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('mr'),
    Locale('pa'),
  ];

  /// Title of the page shown when nobody is signed in.
  ///
  /// In en, this message translates to:
  /// **'Open your TAP link'**
  String get openLinkTitle;

  /// No description provided for @openLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Go to the WhatsApp message from TAP and tap the link in it. You will come back here and be ready to learn.'**
  String get openLinkBody;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get navGallery;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @linkOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening your link...'**
  String get linkOpening;

  /// No description provided for @linkNotWorkingTitle.
  ///
  /// In en, this message translates to:
  /// **'This link is not working'**
  String get linkNotWorkingTitle;

  /// No description provided for @linkNotWorkingMessage.
  ///
  /// In en, this message translates to:
  /// **'Please ask for a new link on WhatsApp.'**
  String get linkNotWorkingMessage;

  /// No description provided for @buttonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get buttonOk;

  /// No description provided for @buttonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get buttonTryAgain;

  /// No description provided for @errorCourseNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'This course is not ready'**
  String get errorCourseNotReadyTitle;

  /// No description provided for @errorCourseNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not open your course. Please tell your teacher.'**
  String get errorCourseNotReadyMessage;

  /// No description provided for @errorSessionEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Please open your link again'**
  String get errorSessionEndedTitle;

  /// No description provided for @errorSessionEndedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Open the link that TAP sent you on WhatsApp to carry on.'**
  String get errorSessionEndedMessage;

  /// No description provided for @errorWaitTitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait a little'**
  String get errorWaitTitle;

  /// No description provided for @errorWaitMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a minute, then try again.'**
  String get errorWaitMessage;

  /// No description provided for @errorNoCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'No course yet'**
  String get errorNoCourseTitle;

  /// No description provided for @errorNoCourseMessage.
  ///
  /// In en, this message translates to:
  /// **'You are not in a course yet. Ask your teacher, then try again.'**
  String get errorNoCourseMessage;

  /// No description provided for @errorNoInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get errorNoInternetTitle;

  /// No description provided for @errorNoInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection, then try again.'**
  String get errorNoInternetMessage;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this. Please try again.'**
  String get errorGenericMessage;

  /// No description provided for @errorNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not find you'**
  String get errorNotFoundTitle;

  /// No description provided for @errorNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This phone number is not signed up for TAP yet. Please ask your teacher.'**
  String get errorNotFoundMessage;

  /// No description provided for @errorLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'That is all for now'**
  String get errorLimitTitle;

  /// No description provided for @errorLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit for this activity.'**
  String get errorLimitMessage;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Core {course} 1'**
  String homeCourseLabel(String course);

  /// No description provided for @homeCourseNotReady.
  ///
  /// In en, this message translates to:
  /// **'Your course is not ready yet. Please tell your teacher.'**
  String get homeCourseNotReady;

  /// No description provided for @homeCongrats.
  ///
  /// In en, this message translates to:
  /// **'Congrats Champ!'**
  String get homeCongrats;

  /// No description provided for @homeActivityComplete.
  ///
  /// In en, this message translates to:
  /// **'Activity\ncomplete 🥳'**
  String get homeActivityComplete;

  /// No description provided for @homeDoneForWeek.
  ///
  /// In en, this message translates to:
  /// **'Done for the\nweek 🥳'**
  String get homeDoneForWeek;

  /// No description provided for @homeKeepWinning.
  ///
  /// In en, this message translates to:
  /// **'Keep winning'**
  String get homeKeepWinning;

  /// No description provided for @homePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get homePoints;

  /// No description provided for @homeReadyForNext.
  ///
  /// In en, this message translates to:
  /// **'Ready to continue with your next activity?'**
  String get homeReadyForNext;

  /// No description provided for @homeSeeYouNextWeek.
  ///
  /// In en, this message translates to:
  /// **'See you next week champ with a new activity video!'**
  String get homeSeeYouNextWeek;

  /// No description provided for @homeLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go 🎉'**
  String get homeLetsGo;

  /// No description provided for @homePendingQuiz.
  ///
  /// In en, this message translates to:
  /// **'Pending: Quiz'**
  String get homePendingQuiz;

  /// No description provided for @homeStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get homeStartQuiz;

  /// No description provided for @homeWeeklyLimit.
  ///
  /// In en, this message translates to:
  /// **'Weekly limit reached'**
  String get homeWeeklyLimit;

  /// No description provided for @homeStartActivity.
  ///
  /// In en, this message translates to:
  /// **'Start Activity'**
  String get homeStartActivity;

  /// No description provided for @homeFeedbackReady.
  ///
  /// In en, this message translates to:
  /// **'Feedback ready'**
  String get homeFeedbackReady;

  /// No description provided for @homePendingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Pending: Feedback'**
  String get homePendingFeedback;

  /// No description provided for @homeFeedbackReadyText.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is ready! Tap to see what I think.'**
  String get homeFeedbackReadyText;

  /// No description provided for @homeFeedbackSlowText.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is taking longer than expected. Please check again a little later.'**
  String get homeFeedbackSlowText;

  /// No description provided for @homeFeedbackWaitingText.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking at your work. Please wait, and come back later to see my feedback.\n\nPoints will be provided after feedback.'**
  String get homeFeedbackWaitingText;

  /// No description provided for @homeSeeFeedback.
  ///
  /// In en, this message translates to:
  /// **'See feedback'**
  String get homeSeeFeedback;

  /// No description provided for @homeCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get homeCheckAgain;

  /// No description provided for @homeToDoSend.
  ///
  /// In en, this message translates to:
  /// **'To do: Send project'**
  String get homeToDoSend;

  /// No description provided for @homeSendProject.
  ///
  /// In en, this message translates to:
  /// **'Send my project'**
  String get homeSendProject;

  /// No description provided for @meTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meTitle;

  /// No description provided for @meSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Have a look at your progress'**
  String get meSubtitle;

  /// No description provided for @meClass.
  ///
  /// In en, this message translates to:
  /// **'Class {grade}'**
  String meClass(String grade);

  /// No description provided for @meNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String meNextLevel(String name);

  /// No description provided for @meTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get meTotalPoints;

  /// No description provided for @mePointsHelp.
  ///
  /// In en, this message translates to:
  /// **'What are points? You earn them by doing TAP activities.'**
  String get mePointsHelp;

  /// No description provided for @meProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'My projects this year'**
  String get meProjectsTitle;

  /// No description provided for @meProjectsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} done'**
  String meProjectsDone(int done, int total);

  /// No description provided for @meNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Finish an activity to see it here.'**
  String get meNoProjects;

  /// No description provided for @meSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get meSettings;

  /// No description provided for @switchProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch profile. Please try again.'**
  String get switchProfileFailed;

  /// No description provided for @projectNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get projectNotStarted;

  /// No description provided for @projectFeedbackPending.
  ///
  /// In en, this message translates to:
  /// **'Feedback pending'**
  String get projectFeedbackPending;

  /// No description provided for @projectSlow.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than expected'**
  String get projectSlow;

  /// No description provided for @projectFeedbackGiven.
  ///
  /// In en, this message translates to:
  /// **'Feedback given'**
  String get projectFeedbackGiven;

  /// No description provided for @projectWrongFormat.
  ///
  /// In en, this message translates to:
  /// **'Wrong format'**
  String get projectWrongFormat;

  /// No description provided for @projectNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get projectNotAccepted;

  /// No description provided for @projectNotSentDetail.
  ///
  /// In en, this message translates to:
  /// **'You have not sent this project yet.'**
  String get projectNotSentDetail;

  /// No description provided for @projectWaitingDetail.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking at your work. Please wait. Points will be provided after feedback.'**
  String get projectWaitingDetail;

  /// No description provided for @projectSlowDetail.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is taking longer than expected. Please check again a little later.'**
  String get projectSlowDetail;

  /// No description provided for @projectValidDetail.
  ///
  /// In en, this message translates to:
  /// **'Your project is valid. Well done!'**
  String get projectValidDetail;

  /// No description provided for @projectNotValidDefault.
  ///
  /// In en, this message translates to:
  /// **'This project needs another try.'**
  String get projectNotValidDefault;

  /// No description provided for @projectNotValidHint.
  ///
  /// In en, this message translates to:
  /// **'Open the activity from Home to send it again.'**
  String get projectNotValidHint;

  /// No description provided for @projectNotAcceptedDefault.
  ///
  /// In en, this message translates to:
  /// **'This project was not accepted.'**
  String get projectNotAcceptedDefault;

  /// No description provided for @projectNotAcceptedHint.
  ///
  /// In en, this message translates to:
  /// **'You have used both tries, so you cannot send it again.'**
  String get projectNotAcceptedHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'kn', 'mr', 'pa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
