import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/shared/ask_tap/ask_tap_chat.dart';

/// The Ask TAP chat (design M-S-06, M-D-01, M-D-02).
void main() {
  test('a question and its answer', () async {
    final chat = AskTapChat(ask: (m) async => 'Tap Add my work.');
    await chat.send('  How do I send a photo?  ');
    expect(chat.lines.map((l) => (l.kind, l.text)), [
      (AskTapLineKind.user, 'How do I send a photo?'),
      (AskTapLineKind.bot, 'Tap Add my work.'),
    ]);
    expect(chat.answered, isTrue);
    expect(chat.sending, isFalse);
  });

  test('an empty message is not sent', () async {
    var calls = 0;
    final chat = AskTapChat(ask: (m) async => '${calls++}');
    await chat.send('   ');
    expect(calls, 0);
    expect(chat.lines, isEmpty);
  });

  test('while one question is open, a second one waits', () async {
    var calls = 0;
    final chat = AskTapChat(
      ask: (m) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'ok';
      },
    );
    final first = chat.send('one');
    expect(chat.sending, isTrue);
    await chat.send('two');
    await first;
    expect(calls, 1);
  });

  test(
    'too many questions: a "busy" line, other errors: a "failed" line',
    () async {
      final busy = AskTapChat(
        ask: (m) async => throw ApiException('RATE_LIMITED', 'x'),
      );
      await busy.send('hi');
      expect(busy.lines.last.kind, AskTapLineKind.busy);

      final failed = AskTapChat(
        ask: (m) async => throw ApiException('UPSTREAM_ERROR', 'x'),
      );
      await failed.send('hi');
      expect(failed.lines.last.kind, AskTapLineKind.failed);

      final offline = AskTapChat(
        ask: (m) async => throw Exception('no network'),
      );
      await offline.send('hi');
      expect(offline.lines.last.kind, AskTapLineKind.failed);
      expect(offline.sending, isFalse);
    },
  );
}
