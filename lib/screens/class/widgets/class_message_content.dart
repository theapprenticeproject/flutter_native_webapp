import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/class_chat_message_model.dart';
import '../../../providers/class_chat_controller.dart';
import 'class_card_shell.dart';
import 'class_quiz_cards.dart';
import 'class_section_checkpoint.dart';
import 'class_submission_card.dart';
import 'class_video_card.dart';

class ClassMessageContent extends StatelessWidget {
  const ClassMessageContent({
    super.key,
    required this.message,
    required this.controller,
    required this.isUser,
  });

  final ClassChatMessage message;
  final ClassChatController controller;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    switch (message.contentType) {
      case ClassChatContentType.text:
      case ClassChatContentType.unitTransition:
        return ClassTextBubble(text: message.text ?? '', isUser: isUser);
      case ClassChatContentType.checkpoint:
        return ClassCheckpointCard(message: message, controller: controller);
      case ClassChatContentType.video:
        return ClassVideoCard(
          key: ValueKey('video_${message.id}'),
          message: message,
          controller: controller,
        );
      case ClassChatContentType.submission:
        return ClassSubmissionCard(
          key: ValueKey('submission_${message.id}'),
          message: message,
          controller: controller,
        );
      case ClassChatContentType.submissionAnswerEcho:
        return ClassTextBubble(text: message.text ?? '', isUser: true);
      case ClassChatContentType.submissionReviewing:
        return const ClassTextBubble(
          text: 'Reviewing your submission...',
          isUser: false,
          isMuted: true,
        );
      case ClassChatContentType.submissionReview:
        return ClassSubmissionReviewCard(message: message);
      case ClassChatContentType.submissionReward:
        return ClassSubmissionRewardCard(
          message: message,
          controller: controller,
        );
      case ClassChatContentType.quizQuestion:
        return isUser
            ? ClassTextBubble(text: message.text ?? '', isUser: true)
            : ClassQuizQuestionCard(
                key: ValueKey('quiz_${message.id}'),
                message: message,
                controller: controller,
              );
      case ClassChatContentType.quizAnswerEcho:
        return ClassTextBubble(text: message.text ?? '', isUser: true);
      case ClassChatContentType.quizFeedback:
        return ClassQuizFeedbackCard(message: message);
      case ClassChatContentType.quizSummary:
        return ClassQuizSummaryCard(message: message);
      case ClassChatContentType.sessionEnd:
      case ClassChatContentType.weeklyCapReached:
        return const SizedBox.shrink();
      case ClassChatContentType.errorRetry:
        return ClassErrorRetryCard(message: message, controller: controller);
      case ClassChatContentType.loading:
        return const SizedBox.shrink();
    }
  }
}

class ClassCheckpointCard extends StatelessWidget {
  const ClassCheckpointCard({
    super.key,
    required this.message,
    required this.controller,
    this.fillAvailableHeight = false,
  });

  final ClassChatMessage message;
  final ClassChatController controller;
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final image = message.data['image'] as String?;
    final buttonLabel = message.data['buttonLabel'] as String? ?? 'Continue';
    final action = message.data['action'] as String? ?? '';

    if (action == 'video' ||
        action == 'submission' ||
        action == 'submission_retry' ||
        action == 'quiz') {
      return ClassSectionCheckpoint(
        kind: switch (action) {
          'video' => ClassSectionCheckpointKind.video,
          'quiz' => ClassSectionCheckpointKind.quiz,
          _ => ClassSectionCheckpointKind.submission,
        },
        text: message.text ?? '',
        buttonLabel: buttonLabel,
        onPressed: () => controller.continueCheckpoint(action),
        fillAvailableHeight: fillAvailableHeight,
      );
    }

    if ((action == 'quiz_begin_art' || action == 'quiz_complete_art') &&
        image != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.classroomMessageSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(image, height: 260, fit: BoxFit.contain),
          ),
        ),
      );
    }

    if (action == 'video_reward' && image != null) {
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.classroomMessageSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(image, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
                decoration: BoxDecoration(
                  color: AppTheme.classroomMessageSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        message.text ?? '',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.volume_up_rounded,
                      size: 22,
                      color: AppTheme.buttonColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 76,
                child: ElevatedButton(
                  onPressed: () => controller.continueCheckpoint(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (action == 'finish' && image != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.classroomMessageSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image, height: 210, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              Text(
                message.text ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => controller.continueCheckpoint(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClassTapBuddySpeakingOrb(),
          const SizedBox(height: 12),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  size: 15,
                  color: AppTheme.buttonColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hear again',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.buttonColor,
                  ),
                ),
              ],
            ),
          ),
          if (image != null) ...[
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230, maxWidth: 360),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              message.text ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C2C34),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 280,
            height: 48,
            child: ElevatedButton(
              onPressed: action.isEmpty
                  ? null
                  : () => controller.continueCheckpoint(action),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassTextBubble extends StatelessWidget {
  const ClassTextBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isMuted = false,
  });

  final String text;
  final bool isUser;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE2F5E9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.4,
            color: AppTheme.textColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.classroomMessageSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppTheme.classroomMessageSurface),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                fontStyle: isMuted ? FontStyle.italic : FontStyle.normal,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.volume_up_rounded,
            size: 18,
            color: AppTheme.imagePlaceholder,
          ),
        ],
      ),
    );
  }
}

class ClassErrorRetryCard extends StatelessWidget {
  const ClassErrorRetryCard({
    super.key,
    required this.message,
    required this.controller,
  });

  final ClassChatMessage message;
  final ClassChatController controller;

  @override
  Widget build(BuildContext context) {
    return ClassCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text ?? 'Something went wrong.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: controller.retryAfterError,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
