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

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @gallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'See what others made'**
  String get gallerySubtitle;

  /// No description provided for @galleryThisActivity.
  ///
  /// In en, this message translates to:
  /// **'THIS ACTIVITY'**
  String get galleryThisActivity;

  /// No description provided for @galleryYourSubmission.
  ///
  /// In en, this message translates to:
  /// **'Your submission'**
  String get galleryYourSubmission;

  /// No description provided for @galleryFromStudents.
  ///
  /// In en, this message translates to:
  /// **'From TAP students like you'**
  String get galleryFromStudents;

  /// No description provided for @galleryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the Gallery. Please try again.'**
  String get galleryLoadFailed;

  /// No description provided for @galleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared work yet. Be the first to share yours!'**
  String get galleryEmpty;

  /// No description provided for @galleryLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load more. Please try again.'**
  String get galleryLoadMoreFailed;

  /// No description provided for @galleryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get galleryLoadMore;

  /// No description provided for @galleryShareWork.
  ///
  /// In en, this message translates to:
  /// **'Share your work'**
  String get galleryShareWork;

  /// No description provided for @galleryYouShared.
  ///
  /// In en, this message translates to:
  /// **'You\'ve shared'**
  String get galleryYouShared;

  /// No description provided for @galleryVideoBy.
  ///
  /// In en, this message translates to:
  /// **'Video by {initials}'**
  String galleryVideoBy(String initials);

  /// No description provided for @galleryWorkBy.
  ///
  /// In en, this message translates to:
  /// **'Work by {initials}'**
  String galleryWorkBy(String initials);

  /// No description provided for @galleryClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get galleryClose;

  /// No description provided for @galleryPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get galleryPrevious;

  /// No description provided for @galleryNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get galleryNext;

  /// No description provided for @galleryPosition.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String galleryPosition(int n, int total);

  /// No description provided for @gallerySwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see more'**
  String get gallerySwipe;

  /// No description provided for @galleryWantToShare.
  ///
  /// In en, this message translates to:
  /// **'Want to share your work too?'**
  String get galleryWantToShare;

  /// No description provided for @galleryOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Open video'**
  String get galleryOpenVideo;

  /// No description provided for @profileNotYou.
  ///
  /// In en, this message translates to:
  /// **'Not {name}? Switch to your profile'**
  String profileNotYou(String name);

  /// No description provided for @profileSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get profileSwitch;

  /// No description provided for @profilePickPrompt.
  ///
  /// In en, this message translates to:
  /// **'Hi Champ, please select who I will talk to'**
  String get profilePickPrompt;

  /// No description provided for @profilesNone.
  ///
  /// In en, this message translates to:
  /// **'No student profiles found for this account.'**
  String get profilesNone;

  /// No description provided for @profilesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profiles. Please try again.'**
  String get profilesLoadFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load that profile. Please try again.'**
  String get profileLoadFailed;

  /// No description provided for @profileGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade}'**
  String profileGrade(String grade);

  /// No description provided for @profileStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get profileStudent;

  /// No description provided for @profileSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected ✓'**
  String get profileSelected;

  /// No description provided for @profileSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profileSelect;

  /// No description provided for @profileWhoLearning.
  ///
  /// In en, this message translates to:
  /// **'Who\'s learning today?'**
  String get profileWhoLearning;

  /// No description provided for @profileSelectToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a student profile to continue.'**
  String get profileSelectToContinue;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, {name}!'**
  String welcomeBack(String name);

  /// No description provided for @welcomeThere.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get welcomeThere;

  /// No description provided for @welcomeNewYear.
  ///
  /// In en, this message translates to:
  /// **'Are you ready for a New Year?'**
  String get welcomeNewYear;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @splashWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TAP!'**
  String get splashWelcome;

  /// No description provided for @splashBroughtBy.
  ///
  /// In en, this message translates to:
  /// **'Brought to you by MCD Delhi'**
  String get splashBroughtBy;

  /// No description provided for @splashGovt.
  ///
  /// In en, this message translates to:
  /// **'Govt. of Delhi x TAP Initiative'**
  String get splashGovt;

  /// No description provided for @errorPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorPageTitle;

  /// No description provided for @errorPageMessage.
  ///
  /// In en, this message translates to:
  /// **'We had trouble loading this page. Please check your internet connection and try again.'**
  String get errorPageMessage;

  /// No description provided for @errorPageButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get errorPageButton;

  /// No description provided for @errorPageDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey Champ\nI am not able to talk to you'**
  String get errorPageDesktopTitle;

  /// No description provided for @errorPageDesktopMessage.
  ///
  /// In en, this message translates to:
  /// **'Looks like you\'re offline. Click below to try again.'**
  String get errorPageDesktopMessage;

  /// No description provided for @errorPageDesktopButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorPageDesktopButton;

  /// No description provided for @headerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for today\'s class?'**
  String get headerSubtitle;

  /// No description provided for @headerHi.
  ///
  /// In en, this message translates to:
  /// **'Hi {name} 👋'**
  String headerHi(String name);

  /// No description provided for @loadingDefault.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingDefault;

  /// No description provided for @settingsSectionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section.'**
  String get settingsSectionLoadFailed;

  /// No description provided for @buttonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// No description provided for @settingsProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again later.'**
  String get settingsProfileLoadFailed;

  /// No description provided for @settingsNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No active profile found.'**
  String get settingsNoProfile;

  /// No description provided for @settingsPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get settingsPersonal;

  /// No description provided for @settingsFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get settingsFirstName;

  /// No description provided for @settingsLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get settingsLastName;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSibling.
  ///
  /// In en, this message translates to:
  /// **'Is a brother or sister also using TAP?'**
  String get settingsSibling;

  /// No description provided for @settingsYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get settingsYes;

  /// No description provided for @settingsNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get settingsNo;

  /// No description provided for @settingsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get settingsPhone;

  /// No description provided for @settingsVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get settingsVerified;

  /// No description provided for @settingsSchoolDetails.
  ///
  /// In en, this message translates to:
  /// **'School Details'**
  String get settingsSchoolDetails;

  /// No description provided for @settingsSchoolName.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get settingsSchoolName;

  /// No description provided for @settingsGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get settingsGrade;

  /// No description provided for @settingsSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get settingsSubject;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @settingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get settingsSaveChanges;

  /// No description provided for @settingsTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsTabProfile;

  /// No description provided for @settingsTabAbout.
  ///
  /// In en, this message translates to:
  /// **'About TAP'**
  String get settingsTabAbout;

  /// No description provided for @classFileReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file. Please try again.'**
  String get classFileReadFailed;

  /// No description provided for @classFileAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t access that. Please try again.'**
  String get classFileAccessFailed;

  /// No description provided for @classTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get classTakePhoto;

  /// No description provided for @classChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo from gallery'**
  String get classChoosePhoto;

  /// No description provided for @classRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record a video'**
  String get classRecordVideo;

  /// No description provided for @classChooseVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose video from gallery'**
  String get classChooseVideo;

  /// No description provided for @classTodaysActivity.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S ACTIVITY 🏎️🏎️'**
  String get classTodaysActivity;

  /// No description provided for @classStep.
  ///
  /// In en, this message translates to:
  /// **'STEP {n}/{total}'**
  String classStep(int n, int total);

  /// No description provided for @classWillCheck.
  ///
  /// In en, this message translates to:
  /// **'I will check for: {criteria}'**
  String classWillCheck(String criteria);

  /// No description provided for @classFileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load that file. Please try picking it again.'**
  String get classFileLoadFailed;

  /// No description provided for @classHintText.
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get classHintText;

  /// No description provided for @classHintAudio.
  ///
  /// In en, this message translates to:
  /// **'Type or transcribe your answer here...'**
  String get classHintAudio;

  /// No description provided for @classShareSubmission.
  ///
  /// In en, this message translates to:
  /// **'Share submission'**
  String get classShareSubmission;

  /// No description provided for @classSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get classSubmit;

  /// No description provided for @classSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get classSent;

  /// No description provided for @classDoLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do it later'**
  String get classDoLater;

  /// No description provided for @classFriendsSent.
  ///
  /// In en, this message translates to:
  /// **'Friends sent 👀'**
  String get classFriendsSent;

  /// No description provided for @classFriendsSaid.
  ///
  /// In en, this message translates to:
  /// **'Friends said 👀'**
  String get classFriendsSaid;

  /// No description provided for @classSeeFriends.
  ///
  /// In en, this message translates to:
  /// **'See what friends made 👀'**
  String get classSeeFriends;

  /// No description provided for @classKindEmoji.
  ///
  /// In en, this message translates to:
  /// **'👉 EMOJI'**
  String get classKindEmoji;

  /// No description provided for @classKindText.
  ///
  /// In en, this message translates to:
  /// **'💬 TEXT'**
  String get classKindText;

  /// No description provided for @classKindAudio.
  ///
  /// In en, this message translates to:
  /// **'🎤 AUDIO'**
  String get classKindAudio;

  /// No description provided for @classKindTextAudio.
  ///
  /// In en, this message translates to:
  /// **'💬 TEXT / 🎤 AUDIO'**
  String get classKindTextAudio;

  /// No description provided for @classKindPhoto.
  ///
  /// In en, this message translates to:
  /// **'📷 PHOTO'**
  String get classKindPhoto;

  /// No description provided for @classKindVideo.
  ///
  /// In en, this message translates to:
  /// **'🎥 VIDEO'**
  String get classKindVideo;

  /// No description provided for @classKindPhotoVideo.
  ///
  /// In en, this message translates to:
  /// **'📷 PHOTO / 🎥 VIDEO'**
  String get classKindPhotoVideo;

  /// No description provided for @classHowToSubmit.
  ///
  /// In en, this message translates to:
  /// **'How to submit'**
  String get classHowToSubmit;

  /// No description provided for @classCheck.
  ///
  /// In en, this message translates to:
  /// **'Check: {criteria}'**
  String classCheck(String criteria);

  /// No description provided for @classScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String classScore(String score);

  /// No description provided for @classNoSubmissionPoints.
  ///
  /// In en, this message translates to:
  /// **'No submission points were added for this attempt.'**
  String get classNoSubmissionPoints;

  /// No description provided for @classCongratsName.
  ///
  /// In en, this message translates to:
  /// **'Congratulations {name}!!!🥳'**
  String classCongratsName(String name);

  /// No description provided for @classPointsPill.
  ///
  /// In en, this message translates to:
  /// **'⊙ +{points} pts'**
  String classPointsPill(int points);

  /// No description provided for @classWonPoints.
  ///
  /// In en, this message translates to:
  /// **'You have won {points} points🪙😍\nYou did a great job champion!'**
  String classWonPoints(int points);

  /// No description provided for @classSubmissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Submission Help'**
  String get classSubmissionHelp;

  /// No description provided for @classWantToContinue.
  ///
  /// In en, this message translates to:
  /// **'Want to continue?'**
  String get classWantToContinue;

  /// No description provided for @classStartNext.
  ///
  /// In en, this message translates to:
  /// **'Start the next activity when you are ready.'**
  String get classStartNext;

  /// No description provided for @classLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get classLetsGo;

  /// No description provided for @classMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get classMaybeLater;

  /// No description provided for @classBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get classBackHome;

  /// No description provided for @classCourseComplete.
  ///
  /// In en, this message translates to:
  /// **'Course complete! 🎉'**
  String get classCourseComplete;

  /// No description provided for @classCourseCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You completed every activity in this course.'**
  String get classCourseCompleteBody;

  /// No description provided for @classWatchAnother.
  ///
  /// In en, this message translates to:
  /// **'Watch another video?'**
  String get classWatchAnother;

  /// No description provided for @classYoullEarn.
  ///
  /// In en, this message translates to:
  /// **'YOU\'LL EARN'**
  String get classYoullEarn;

  /// No description provided for @classDidWell.
  ///
  /// In en, this message translates to:
  /// **'You did really well! 🎉'**
  String get classDidWell;

  /// No description provided for @classFinishedForNow.
  ///
  /// In en, this message translates to:
  /// **'You\'ve finished your activities for now. Come back soon for the next one!'**
  String get classFinishedForNow;

  /// No description provided for @classTodaysPicture.
  ///
  /// In en, this message translates to:
  /// **'Today\'s picture'**
  String get classTodaysPicture;

  /// No description provided for @classPictureUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Congratulations !!🎉 You have unlocked today\'s picture'**
  String get classPictureUnlocked;

  /// No description provided for @classPictureLocked.
  ///
  /// In en, this message translates to:
  /// **'Finish each step to open today\'s secret picture! ✨'**
  String get classPictureLocked;

  /// No description provided for @classPictureSemantics.
  ///
  /// In en, this message translates to:
  /// **'Today\'s picture, {n} of 4 pieces'**
  String classPictureSemantics(int n);

  /// No description provided for @classQuizQuestion.
  ///
  /// In en, this message translates to:
  /// **'Q{n}. {question}'**
  String classQuizQuestion(int n, String question);

  /// No description provided for @classQuizOf.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {total}'**
  String classQuizOf(int n, int total);

  /// No description provided for @classConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get classConfirm;

  /// No description provided for @classCorrectPoints.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points} points'**
  String classCorrectPoints(int points);

  /// No description provided for @classCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get classCorrect;

  /// No description provided for @classNotQuite.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get classNotQuite;

  /// No description provided for @classCorrectAnswerIs.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String classCorrectAnswerIs(String answer);

  /// No description provided for @classQuizDone.
  ///
  /// In en, this message translates to:
  /// **'Quiz done!'**
  String get classQuizDone;

  /// No description provided for @classQuizScore.
  ///
  /// In en, this message translates to:
  /// **'You got {correct} out of {total} correct.'**
  String classQuizScore(int correct, int total);

  /// No description provided for @classWatchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch the video 👇'**
  String get classWatchVideo;

  /// No description provided for @classWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch: {title}'**
  String classWatchTitle(String title);

  /// No description provided for @classWatched.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get classWatched;

  /// No description provided for @classIWatched.
  ///
  /// In en, this message translates to:
  /// **'I watched it • +{points} points'**
  String classIWatched(int points);

  /// No description provided for @classSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get classSomethingWrong;

  /// No description provided for @classTapBuddy.
  ///
  /// In en, this message translates to:
  /// **'TAP Buddy'**
  String get classTapBuddy;

  /// No description provided for @chatSaveVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not save that you watched the video. Please check your connection and retry.'**
  String get chatSaveVideoFailed;

  /// No description provided for @chatVideoReward.
  ///
  /// In en, this message translates to:
  /// **'Wow! That’s amazing 🤩  {name}, you just earned {points} points🪩 for watching the video 🥳🥳🥳\n\nNow it’s time to do the activity submission 🌟'**
  String chatVideoReward(String name, int points);

  /// No description provided for @chatTryPractice.
  ///
  /// In en, this message translates to:
  /// **'That\'s a good try — let\'s keep practicing this one.'**
  String get chatTryPractice;

  /// No description provided for @chatSlowFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is taking longer than expected 🕒\nPlease check again a little later.'**
  String get chatSlowFeedback;

  /// No description provided for @chatWaitingFeedback.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking at your work 👀\nPlease wait. Come back later to see my feedback!\n\nPoints will be provided after feedback.'**
  String get chatWaitingFeedback;

  /// No description provided for @chatBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get chatBackHome;

  /// No description provided for @chatValidDefault.
  ///
  /// In en, this message translates to:
  /// **'Great work! Your project is valid ✅'**
  String get chatValidDefault;

  /// No description provided for @chatAskPoints.
  ///
  /// In en, this message translates to:
  /// **'Do you want to know your total points collected so far?'**
  String get chatAskPoints;

  /// No description provided for @chatYesYesYes.
  ///
  /// In en, this message translates to:
  /// **'Yes Yes Yes 😍'**
  String get chatYesYesYes;

  /// No description provided for @chatWonTitle.
  ///
  /// In en, this message translates to:
  /// **'YOU WON! 🏆'**
  String get chatWonTitle;

  /// No description provided for @chatWonEarned.
  ///
  /// In en, this message translates to:
  /// **'Your valid work earned +{points} points 🪙'**
  String chatWonEarned(int points);

  /// No description provided for @chatWonTotal.
  ///
  /// In en, this message translates to:
  /// **'Your points: {total} 🪙'**
  String chatWonTotal(int total);

  /// No description provided for @chatSendCorrected.
  ///
  /// In en, this message translates to:
  /// **'{reason}\n\nNo worries; please send it again!'**
  String chatSendCorrected(String reason);

  /// No description provided for @chatNoMoreTries.
  ///
  /// In en, this message translates to:
  /// **'{reason}\n\nYou have used both tries, so you cannot send this work again.'**
  String chatNoMoreTries(String reason);

  /// No description provided for @chatSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get chatSendAgain;

  /// No description provided for @chatReadyShare.
  ///
  /// In en, this message translates to:
  /// **'Are you ready to share your work? 📸'**
  String get chatReadyShare;

  /// No description provided for @chatYesLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Yes, let\'s go'**
  String get chatYesLetsGo;

  /// No description provided for @chatNotToday.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get chatNotToday;

  /// No description provided for @chatFileTooBig.
  ///
  /// In en, this message translates to:
  /// **'That file is too big 😅\nPlease choose a smaller photo or a shorter video.'**
  String get chatFileTooBig;

  /// No description provided for @chatSubmitAgain.
  ///
  /// In en, this message translates to:
  /// **'Submit Again'**
  String get chatSubmitAgain;

  /// No description provided for @chatAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'You already sent this work. Let\'s go on! 💪'**
  String get chatAlreadySent;

  /// No description provided for @chatSendWorkFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not send your work. Please check your connection and retry.'**
  String get chatSendWorkFailed;

  /// No description provided for @chatSaveSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not save your completed submission. Please check your connection and retry.'**
  String get chatSaveSubmissionFailed;

  /// No description provided for @chatProTip.
  ///
  /// In en, this message translates to:
  /// **'Pro tip: Take the photo in good light and show your full work 📸✨\n\nI’m excited to see what you made😅\nYou can do this! ⭐💪'**
  String get chatProTip;

  /// No description provided for @chatQuizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz complete!'**
  String get chatQuizComplete;

  /// No description provided for @chatStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Let’s start the {unit} quiz🚀🚀🚀'**
  String chatStartQuiz(String unit);

  /// No description provided for @chatQuizButton.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get chatQuizButton;

  /// No description provided for @chatTodayPlay.
  ///
  /// In en, this message translates to:
  /// **'Today we\'re going to play with {unit}.\nWatch a short video, then make your own project.'**
  String chatTodayPlay(String unit);

  /// No description provided for @chatWatchButton.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get chatWatchButton;

  /// No description provided for @chatFinalWin.
  ///
  /// In en, this message translates to:
  /// **'Activity Points    {activity} 🪙\nQuiz Points    {quiz} 🪙'**
  String chatFinalWin(int activity, int quiz);

  /// No description provided for @chatSaveQuizFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not save your quiz result. Please check your connection and retry.'**
  String get chatSaveQuizFailed;

  /// No description provided for @chatQuizTotals.
  ///
  /// In en, this message translates to:
  /// **'Great job Champ!\nDo you want to know your total points collected so far?'**
  String get chatQuizTotals;

  /// No description provided for @chatSaveSubmissionStill.
  ///
  /// In en, this message translates to:
  /// **'Still could not save your submission progress. Please check your connection and retry.'**
  String get chatSaveSubmissionStill;

  /// No description provided for @chatSaveVideoStill.
  ///
  /// In en, this message translates to:
  /// **'We still could not save the video checkpoint. Please check your connection and retry.'**
  String get chatSaveVideoStill;

  /// No description provided for @chatSaveGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong saving your progress.'**
  String get chatSaveGeneric;

  /// No description provided for @chatWatchedEcho.
  ///
  /// In en, this message translates to:
  /// **'I watched it'**
  String get chatWatchedEcho;

  /// No description provided for @chatLaterEcho.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do it later 🕒'**
  String get chatLaterEcho;

  /// No description provided for @chatPraise.
  ///
  /// In en, this message translates to:
  /// **'I am SO proud of you {name} 🥹 That\'s the spirit! [+{points} pts]'**
  String chatPraise(String name, int points);

  /// No description provided for @classPictureFullTitle.
  ///
  /// In en, this message translates to:
  /// **'You opened the full picture! 🥳'**
  String get classPictureFullTitle;

  /// No description provided for @classPictureFullBody.
  ///
  /// In en, this message translates to:
  /// **'You finished all 4 steps. Great job, champ!'**
  String get classPictureFullBody;

  /// No description provided for @classPicturePartTitle.
  ///
  /// In en, this message translates to:
  /// **'{n} of 4 pieces opened'**
  String classPicturePartTitle(int n);

  /// No description provided for @classPicturePartBody.
  ///
  /// In en, this message translates to:
  /// **'Finish each step to open the whole picture'**
  String get classPicturePartBody;

  /// No description provided for @chatVideoRepeat.
  ///
  /// In en, this message translates to:
  /// **'Points are given only the first time you watch the video 🎬\n\nNow it’s time to do the activity submission 🌟'**
  String get chatVideoRepeat;

  /// No description provided for @chatSendCorrectedOnly.
  ///
  /// In en, this message translates to:
  /// **'Hi Champ 👋\nI couldn\'t review your work 🥺 Because the photo was either a bit unclear or not of today\'s activity.\n\nNo worries; please send it again!'**
  String get chatSendCorrectedOnly;

  /// No description provided for @chatNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t review your work 🥺 Because the photo was either a bit unclear or not of today\'s activity.'**
  String get chatNotAccepted;
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
