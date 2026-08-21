import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/app_header.dart';
import '../models/onboarding_models.dart';
import 'onboarding_chat_widgets.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    required this.messages,
    required this.scrollController,
    required this.isBotTyping,
    required this.interaction,
    required this.showTextInput,
    required this.inputController,
    required this.inputFocusNode,
    required this.inputHint,
    required this.inputEnabled,
    required this.isVoiceMuted,
    required this.onToggleVoice,
    required this.onSubmitText,
    super.key,
  });

  final List<OnboardingMessage> messages;
  final ScrollController scrollController;
  final bool isBotTyping;
  final Widget? interaction;
  final bool showTextInput;
  final TextEditingController inputController;
  final FocusNode inputFocusNode;
  final String inputHint;
  final bool inputEnabled;
  final bool isVoiceMuted;
  final VoidCallback onToggleVoice;
  final VoidCallback onSubmitText;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final maxBubbleWidth = isDesktop ? 355.0 : size.width * .78;

    return Scaffold(
      backgroundColor: AppTheme.onboardingBackground,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isDesktop ? 68 : 0,
              vertical: isDesktop ? 8 : 0,
            ),
            constraints: const BoxConstraints(maxWidth: 1080),
            color: AppTheme.cardBackground,
            child: Column(
              children: [
                const AppHeader(title: 'TAP Onboarding'),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 70 : 16,
                      16,
                      isDesktop ? 70 : 16,
                      22,
                    ),
                    itemCount:
                        messages.length +
                        (isBotTyping ? 1 : 0) +
                        (!isBotTyping && interaction != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        if (isBotTyping) {
                          return const OnboardingTypingIndicator();
                        }
                        return _InlineInteraction(
                          maxWidth: maxBubbleWidth,
                          child: interaction!,
                        );
                      }

                      if (index == messages.length + 1) {
                        return _InlineInteraction(
                          maxWidth: maxBubbleWidth,
                          child: interaction!,
                        );
                      }

                      return OnboardingMessageTile(
                        message: messages[index],
                        isDesktop: isDesktop,
                        maxBubbleWidth: maxBubbleWidth,
                        isVoiceMuted: isVoiceMuted,
                        onVoicePressed: onToggleVoice,
                      );
                    },
                  ),
                ),
                if (showTextInput)
                  OnboardingComposer(
                    controller: inputController,
                    focusNode: inputFocusNode,
                    hint: inputHint,
                    enabled: inputEnabled,
                    onSubmit: onSubmitText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineInteraction extends StatelessWidget {
  const _InlineInteraction({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 46, top: 4, bottom: 6),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
