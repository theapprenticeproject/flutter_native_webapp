import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/onboarding_models.dart';

class OnboardingMessageTile extends StatelessWidget {
  const OnboardingMessageTile({
    required this.message,
    required this.isDesktop,
    required this.maxBubbleWidth,
    required this.isVoiceMuted,
    required this.onVoicePressed,
    super.key,
  });

  final OnboardingMessage message;
  final bool isDesktop;
  final double maxBubbleWidth;
  final bool isVoiceMuted;
  final VoidCallback onVoicePressed;

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isBot) const _BotAvatar(),
          Flexible(
            child: Column(
              crossAxisAlignment: isBot
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (message.text.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isBot
                              ? AppTheme.fieldBackground
                              : AppTheme.chatSuccessBubble,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isBot ? 7 : 18),
                            bottomRight: Radius.circular(isBot ? 18 : 7),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                message.text,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isBot
                                      ? AppTheme.textColor
                                      : AppTheme.successText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (isBot && message.hasVoice) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: onVoicePressed,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Icon(
                                    isVoiceMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    size: 16,
                                    color: AppTheme.buttonColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isBot)
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 4),
                          child: Icon(
                            Icons.done_all,
                            size: 16,
                            color: AppTheme.streakColor,
                          ),
                        ),
                    ],
                  ),
                if (message.content != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 450 : maxBubbleWidth,
                    ),
                    child: message.content!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingTypingIndicator extends StatelessWidget {
  const OnboardingTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_BotAvatar(), _TypingBubble()],
    ),
  );
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: CircleAvatar(
      radius: 19,
      backgroundColor: AppTheme.imageBgColor,
      child: ClipOval(
        child: Image.asset(
          'assets/onboarding/TAP-bot.png',
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) =>
              const Icon(Icons.android, color: AppTheme.buttonColor),
        ),
      ),
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.fieldBackground,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (_) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            color: AppTheme.subheadingColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

class OnboardingComposer extends StatelessWidget {
  const OnboardingComposer({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.enabled,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      color: AppTheme.cardBackground,
      border: Border(top: BorderSide(color: AppTheme.imageBgColor)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: enabled
                  ? AppTheme.fieldBackground
                  : AppTheme.fieldBackground.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.subheadingColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: enabled ? onSubmit : null,
          backgroundColor: AppTheme.buttonColor,
          foregroundColor: AppTheme.cardBackground,
          elevation: 0,
          child: const Icon(Icons.send, size: 18),
        ),
      ],
    ),
  );
}

class OnboardingActionButtons extends StatelessWidget {
  const OnboardingActionButtons({
    required this.options,
    required this.onSelect,
    super.key,
  });

  final List<dynamic> options;
  final void Function(String value, String? nextStep) onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(
      children: options.map((option) {
        final value = option['value']?.toString() ?? '';
        final primary = {
          'confirm',
          'yes',
          'start',
          'start_learning',
        }.contains(value);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ElevatedButton(
              onPressed: () => onSelect(value, option['next_step']?.toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary
                    ? AppTheme.buttonColor
                    : AppTheme.imageBgColor,
                foregroundColor: primary
                    ? AppTheme.cardBackground
                    : AppTheme.buttonColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                option['label']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
