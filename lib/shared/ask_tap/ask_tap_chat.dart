import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';

/// [busy]: too many questions (the Worker's `RATE_LIMITED`). [failed]: any
/// other problem, for example no network or the AI provider is down.
enum AskTapLineKind { user, bot, busy, failed }

class AskTapLine {
  const AskTapLine(this.kind, [this.text = '']);
  final AskTapLineKind kind;
  final String text;
}

/// The conversation of the Ask TAP panel (design M-S-06, M-D-01, M-D-02).
class AskTapChat extends ChangeNotifier {
  AskTapChat({required this.ask});

  final Future<String> Function(String message) ask;
  final List<AskTapLine> lines = [];
  bool sending = false;

  /// TAP Buddy has answered at least once (the chips grey out, M-D-02).
  bool answered = false;

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || sending) return;
    lines.add(AskTapLine(AskTapLineKind.user, text));
    sending = true;
    notifyListeners();
    try {
      final reply = await ask(text);
      lines.add(AskTapLine(AskTapLineKind.bot, reply));
    } on ApiException catch (e) {
      lines.add(
        AskTapLine(
          e.code == 'RATE_LIMITED'
              ? AskTapLineKind.busy
              : AskTapLineKind.failed,
        ),
      );
    } catch (_) {
      lines.add(const AskTapLine(AskTapLineKind.failed));
    }
    sending = false;
    answered = true;
    notifyListeners();
  }
}
