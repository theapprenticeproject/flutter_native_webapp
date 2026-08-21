import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/class_chat_message_model.dart';
import '../../../providers/class_chat_controller.dart';
import 'class_message_content.dart';

class ClassChatBubbleRow extends StatelessWidget {
  const ClassChatBubbleRow({
    super.key,
    required this.message,
    required this.controller,
  });

  final ClassChatMessage message;
  final ClassChatController controller;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ClassChatSender.user;

    if (message.contentType == ClassChatContentType.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: _TypingIndicator()),
      );
    }

    if (message.contentType == ClassChatContentType.checkpoint) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ClassCheckpointCard(message: message, controller: controller),
      );
    }

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: ClassMessageContent(
                  message: message,
                  controller: controller,
                  isUser: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const _ClassAvatar(isUser: true),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _ClassAvatar(isUser: false),
          const SizedBox(width: 8),
          Expanded(
            child: ClassMessageContent(
              message: message,
              controller: controller,
              isUser: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassAvatar extends StatelessWidget {
  const _ClassAvatar({required this.isUser});

  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 16,
          color: AppTheme.buttonColor,
        ),
      );
    }

    return CircleAvatar(
      radius: 15,
      backgroundColor: AppTheme.classroomMessageSurface,
      child: ClipOval(
        child: Image.asset(
          'assets/onboarding/TAP-bot.png',
          fit: BoxFit.cover,
          width: 30,
          height: 30,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.smart_toy_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.classroomMessageSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: 40,
        height: 16,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) {
                final t = (_controller.value + (i * 0.2)) % 1.0;
                final scale =
                    0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: const CircleAvatar(
                    radius: 3,
                    backgroundColor: AppTheme.imagePlaceholder,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
