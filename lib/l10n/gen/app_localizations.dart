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
