import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_turn_model.dart';
import '../providers/language_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/tap_buddy_context_provider.dart';
import '../providers/tapbuddy_chat_provider.dart';

class TapBuddyPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const TapBuddyPanel({super.key, required this.onClose});

  @override
  ConsumerState<TapBuddyPanel> createState() => _TapBuddyPanelState();
}

class _TapBuddyPanelState extends ConsumerState<TapBuddyPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatTurnModel> _messages = [];
  bool _historyLoaded = false;
  bool _isSending = false;
  String? _pendingRetryMessage;
  String? _errorText;

  String? _phone;
  String? _learnerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final activeProfile = await ref
        .read(profileRepositoryProvider.future)
        .then((repository) => repository.readActiveProfile());
    if (!mounted || activeProfile == null) return;

    final repository = await ref.read(tapbuddyChatRepositoryProvider.future);
    final resolvedProfile = activeProfile;
    final transcript = await repository.readTranscript(
      resolvedProfile.phone,
      resolvedProfile.learnerId,
    );

    if (!mounted) return;
    setState(() {
      _phone = activeProfile.phone;
      _learnerId = activeProfile.learnerId;
      _messages.addAll(transcript);
      _historyLoaded = true;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? retryText]) async {
    final text = (retryText ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;
    if (_phone == null || _learnerId == null) return;

    setState(() {
      _isSending = true;
      _errorText = null;
      _pendingRetryMessage = null;
      if (retryText == null) {
        _messages.add(ChatTurnModel.user(text));
        _inputController.clear();
      }
    });
    _scrollToBottom();

    try {
      final repository = await ref.read(tapbuddyChatRepositoryProvider.future);
      final languageCode = ref.read(languageProvider);
      final context = await ref.read(tapBuddyContextProvider.future);

      final reply = await repository.sendMessage(
        phone: _phone!,
        learnerId: _learnerId!,
        message: text,
        grade: context.grade,
        language: languageCode,
        context: context.toJson(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatTurnModel.assistant(reply));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorText = "Couldn't reach TAP Buddy. Please try again.";
        _pendingRetryMessage = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 560 ? (width * 0.82).clamp(292.0, 330.0) : 330.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: panelWidth,
          height: double.infinity,
          child: SafeArea(
            left: false,
            child: Column(
              children: [
                _PanelHeader(onClose: widget.onClose),
                const Divider(height: 1, color: Color(0xFFE8E8EF)),
                Expanded(
                  child: !_historyLoaded
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                          children: [
                            const Center(child: _DatePill()),
                            const SizedBox(height: 10),
                            if (_messages.isEmpty) ...const [
                              _BuddyMessage(
                                'Hey there Champ!\nHow may I help you?',
                              ),
                              _BuddyMessage(
                                'Type your question below and I\'ll help you out.',
                              ),
                            ],
                            for (final turn in _messages)
                              turn.role == 'user'
                                  ? _UserMessage(turn.content)
                                  : _BuddyMessage(turn.content),
                            if (_isSending) const _TypingBubble(),
                            if (_errorText != null)
                              _ErrorRetryBubble(
                                text: _errorText!,
                                onRetry: () => _send(_pendingRetryMessage),
                              ),
                          ],
                        ),
                ),
                _InputBar(
                  controller: _inputController,
                  enabled: _historyLoaded && !_isSending,
                  onSend: () => _send(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _PanelHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Image.asset('assets/onboarding/TAP-bot.png', width: 28, height: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TAP Buddy',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C1C21),
                    ),
                  ),
                  Text(
                    'YOUR LEARNING DIDI',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF777887),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: const Color(0xFF777887),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F1F5),
                fixedSize: const Size(32, 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E4EA)),
      ),
      child: Text(
        'Today',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BuddyMessage extends StatelessWidget {
  final String text;

  const _BuddyMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFF4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.35,
                  color: const Color(0xFF1C1C21),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.volume_up_rounded,
              size: 14,
              color: Color(0xFF5B5BD6),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMessage extends StatelessWidget {
  final String text;

  const _UserMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2E6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.35,
                  color: const Color(0xFF1C1C21),
                ),
              ),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.done_rounded, size: 13, color: Color(0xFF58B77D)),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFF4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(width: 28, height: 12, child: _TypingDots()),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_controller.value + (i * 0.2)) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Transform.scale(
              scale: scale,
              child: const CircleAvatar(
                radius: 2.6,
                backgroundColor: Color(0xFF9C9DAB),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ErrorRetryBubble extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorRetryBubble({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDEDEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEBAFA6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.35,
                color: const Color(0xFFD34B40),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD34B40),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Type here...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9A9BA8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: enabled ? onSend : null,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF5B5BD6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
