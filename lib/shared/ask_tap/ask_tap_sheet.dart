import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/profile/student_language_provider.dart';
import '../../domain/tap_buddy/tap_buddy_provider.dart';
import '../../l10n/l10n.dart';
import '../text/first_name.dart';
import '../widgets/app_primary_button.dart';
import 'ask_tap_chat.dart';

/// Opens the Ask TAP panel (design M-S-06). [screen] says where the student is
/// (`home` or `activity`); it goes to the AI with the language and [extra]
/// (for example the unit and the step). [fromActivity] adds "Back to my activity" under each answer.
Future<void> showAskTapSheet(
  BuildContext context, {
  required String studentName,
  required String screen,
  Map<String, Object?> extra = const {},
  bool fromActivity = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  // The answers can be selected and copied.
  builder: (_) => SelectionArea(
    child: AskTapSheet(
      studentName: studentName,
      screen: screen,
      extra: extra,
      fromActivity: fromActivity,
    ),
  ),
);

class AskTapSheet extends ConsumerStatefulWidget {
  const AskTapSheet({
    super.key,
    required this.studentName,
    required this.screen,
    this.extra = const {},
    this.fromActivity = false,
  });

  final String studentName;
  final String screen;
  final Map<String, Object?> extra;
  final bool fromActivity;

  @override
  ConsumerState<AskTapSheet> createState() => _AskTapSheetState();
}

class _AskTapSheetState extends ConsumerState<AskTapSheet> {
  late final AskTapChat _chat;
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final repo = ref.read(tapBuddyRepositoryProvider);
    final language = ref.read(studentLanguageProvider);
    _chat = AskTapChat(
      ask: (message) => repo.ask(
        message,
        context: {
          'screen': widget.screen,
          'language': language,
          ...widget.extra,
        },
      ),
    )..addListener(_onChat);
  }

  void _onChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chat.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String message) {
    _text.clear();
    _chat.send(message);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => Column(
            children: [
              _Header(onClose: () => Navigator.of(context).maybePop()),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(child: _TodayChip(label: l.askTapToday)),
                    const SizedBox(height: 12),
                    _Bubble(text: l.askTapHello(firstName(widget.studentName))),
                    for (final line in _chat.lines) _lineView(l, line),
                    if (_chat.sending) const _Bubble(text: '…'),
                    if (widget.fromActivity && _chat.answered) ...[
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: l.askTapBack,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ],
                ),
              ),
              _InputBar(
                controller: _text,
                enabled: !_chat.sending,
                onSend: _send,
                hint: l.askTapHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lineView(AppLocalizations l, AskTapLine line) => switch (line.kind) {
    AskTapLineKind.user => _Bubble(text: line.text, user: true),
    AskTapLineKind.bot => _Bubble(text: line.text),
    AskTapLineKind.busy => _Bubble(text: l.askTapBusy),
    AskTapLineKind.failed => _Bubble(text: l.askTapFailed),
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.classroomMessageSurface,
            child: ClipOval(
              child: Image.asset(
                'assets/onboarding/TAP-bot.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.askTapTitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.askTapSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.subheadingColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, this.user = false});

  final String text;
  final bool user;

  @override
  Widget build(BuildContext context) => Align(
    alignment: user ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: user
            ? const Color(0xFFE2F5E9)
            : AppTheme.classroomMessageSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
    ),
  );
}

/// The text box and the send button. There is no microphone: the WhatsApp
/// browser has no speech input.
// shortcut: no microphone (design M-S-06), because speech is not available in
// the WhatsApp browser. Add it when voice input is built.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.hint,
  });

  final TextEditingController controller;
  final bool enabled;
  final void Function(String) onSend;
  final String hint;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF3F3F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: enabled ? () => onSend(controller.text) : null,
            icon: const Icon(Icons.arrow_upward_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.buttonColor),
          ),
        ],
      ),
    ),
  );
}
