import '../../domain/me/my_projects.dart';
import '../../domain/submission/feedback_state.dart';
import '../../l10n/gen/app_localizations.dart';

/// The words for a project in "My projects this year" (the Figma frames:
/// pending, given, wrong format).
extension MyProjectText on MyProject {
  String labelOf(AppLocalizations l) => switch (stage) {
    FeedbackStage.notSent => l.projectNotStarted,
    FeedbackStage.waiting => l.projectFeedbackPending,
    FeedbackStage.slow => l.projectSlow,
    FeedbackStage.valid => l.projectFeedbackGiven,
    FeedbackStage.notValid => l.projectWrongFormat,
  };

  /// The Worker's feedback when there is some, and a plain line for each state
  /// otherwise.
  String detailOf(AppLocalizations l) {
    final text = feedback?.trim() ?? '';
    switch (stage) {
      case FeedbackStage.notSent:
        return l.projectNotSentDetail;
      case FeedbackStage.waiting:
        return l.projectWaitingDetail;
      case FeedbackStage.slow:
        return l.projectSlowDetail;
      case FeedbackStage.valid:
        return text.isEmpty ? l.projectValidDetail : text;
      case FeedbackStage.notValid:
        return '${text.isEmpty ? l.projectNotValidDefault : text}\n\n'
            '${l.projectNotValidHint}';
    }
  }
}
