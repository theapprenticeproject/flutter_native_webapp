import '../../../l10n/gen/app_localizations.dart';

/// The text of the page after a work that is not valid. The Worker's feedback
/// comes first when it sent some. With none, the page gives one sentence only
/// (it used to give two that meant the same).
String notValidText(
  AppLocalizations l, {
  required String? feedback,
  required bool canSend,
}) {
  final text = feedback?.trim() ?? '';
  if (canSend) {
    return text.isEmpty ? l.chatSendCorrectedOnly : l.chatSendCorrected(text);
  }
  return l.chatNoMoreTries(text.isEmpty ? l.chatNotAccepted : text);
}
