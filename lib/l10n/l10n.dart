import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// `context.l10n.someText`: the app text in the student's language.
///
/// Falls back to English when no translations are installed above the widget
/// (some tests build a widget without the app). All app text is in
/// `lib/l10n/app_en.arb`. A language that lacks a text shows the English one.
extension AppL10n on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}
