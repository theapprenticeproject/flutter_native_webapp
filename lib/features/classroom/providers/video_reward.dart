import '../../../l10n/gen/app_localizations.dart';

/// What the chat shows after the video: the picture and the text.
typedef VideoReward = ({String? image, String text});

/// The points are the ones the Worker gave (R-41). A student who watches the
/// same video again gets `repeat: true` and 0 points: then there is no points
/// picture and no "you earned", only the reason.
VideoReward videoReward(
  AppLocalizations l, {
  required String studentName,
  required int points,
  required bool alreadyRecorded,
}) => alreadyRecorded && points == 0
    ? (image: null, text: l.chatVideoRepeat)
    : (
        image: 'assets/class-screen/10Points.png',
        text: l.chatVideoReward(studentName, points),
      );
