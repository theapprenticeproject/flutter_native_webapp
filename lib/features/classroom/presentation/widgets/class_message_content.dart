import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/class_chat_message_model.dart';
import '../../providers/class_chat_controller.dart';
import 'class_quiz_cards.dart';
import 'class_results_cards.dart';
import 'class_section_checkpoint.dart';
import 'class_submission_card.dart';
import 'class_submitted_preview.dart';
import 'class_video_reward_card.dart';
import 'class_video_card.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_tonal_button.dart';
import '../../../../shared/text/first_name.dart';

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
        return ClassTextBubble(
          text: message.text ?? '',
          isUser: isUser,
          isWarning: message.data['warning'] == true,
        );
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
        // The photo or video the student sent has its own bubble.
        if (message.data['isPreview'] == true) {
          return ClassSubmittedPreview(
            bytes: message.data['previewBytes'] as Uint8List?,
            isVideo: message.data['isVideo'] == true,
            progress: controller.uploadProgress,
          );
        }
        return ClassTextBubble(text: message.text ?? '', isUser: true);
      case ClassChatContentType.submissionReview:
        return ClassSubmissionReviewCard(message: message);
      case ClassChatContentType.submissionReward:
        return ClassSubmissionRewardCard(message: message);
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

    // The screens after the work (design M-C23 to M-C27).
    if (message.data['bare'] == true) {
      return ClassChoiceButtons(
        primaryLabel: buttonLabel,
        onPrimary: () => controller.continueCheckpoint(action),
        secondaryLabel: message.data['secondaryLabel'] as String?,
        onSecondary: () => controller.continueCheckpoint(
          message.data['secondaryAction'] as String? ?? '',
        ),
      );
    }
    if (message.data['resend'] == true) {
      return ClassResendCard(
        onAdd: () => controller.continueCheckpoint(action),
        onLater: () => controller.continueCheckpoint(
          message.data['secondaryAction'] as String? ?? '',
        ),
      );
    }
    if (action == 'results_points') {
      return AppTonalButton(
        label: buttonLabel,
        onPressed: () => controller.continueCheckpoint(action),
      );
    }
    if (action == 'results_done' && image != null) {
      return ClassYouWonCard(
        image: image,
        label: message.data['pointsLabel'] as String? ?? '',
        points: message.data['points'] as int? ?? 0,
        buttonLabel: buttonLabel,
        onContinue: () => controller.continueCheckpoint(action),
      );
    }

    if (action == 'video' ||
        action == 'submission' ||
        action == 'submission_retry' ||
        action == 'share_work' ||
        action == 'not_today' ||
        action == 'send_again' ||
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
        secondaryLabel: message.data['secondaryLabel'] as String?,
        onSecondary: () => controller.continueCheckpoint(
          message.data['secondaryAction'] as String? ?? '',
        ),
      );
    }

    if ((action == 'quiz_begin_art' ||
            action == 'quiz_complete_art' ||
            action == 'art') &&
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
      return ClassVideoRewardCard(
        image: image,
        text: message.text ?? '',
        buttonLabel: buttonLabel,
        onContinue: () => controller.continueCheckpoint(action),
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
              AppPrimaryButton(
                label: buttonLabel,
                onPressed: () => controller.continueCheckpoint(action),
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
          const ClassTapBuddyOrb(),
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
            child: AppPrimaryButton(
              label: buttonLabel,
              onPressed: action.isEmpty
                  ? null
                  : () => controller.continueCheckpoint(action),
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
    this.isWarning = false,
  });

  final String text;
  final bool isUser;
  final bool isMuted;

  /// A pink bubble: the work was not valid (design M-C25).
  final bool isWarning;

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
        color: isWarning
            ? const Color(0xFFFBE4E4)
            : AppTheme.classroomMessageSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
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
        ],
      ),
    );
  }
}

/// A save or a send failed (design M-C23): the sad TAP Buddy and Retry.
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
    return ClassOfflineCard(
      name: firstName(controller.studentName),
      onRetry: controller.retryAfterError,
    );
  }
}
