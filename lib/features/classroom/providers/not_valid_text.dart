import '../../../l10n/gen/app_localizations.dart';

/// The text of the page after a work that is not valid. The Worker's feedback
/// comes first when it sent some. With none, the page gives one sentence only
/// (it used to give two that meant the same). The student can send again as often
/// as needed.
String notValidText(AppLocalizations l, {required String? feedback}) {
  final text = feedback?.trim() ?? '';
  return text.isEmpty ? l.chatSendCorrectedOnly : l.chatSendCorrected(text);
}
