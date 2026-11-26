import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_tonal_button.dart';
import '../../../../shared/widgets/dashed_upload_box.dart';

/// Connection error (design M-C23): the sad TAP Buddy, what happened, Retry.
class ClassOfflineCard extends StatelessWidget {
  const ClassOfflineCard({
    super.key,
    required this.name,
    required this.onRetry,
  });

  final String name;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8FB),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(18),
            child: Image.asset(
              'assets/class-screen/offline-buddy.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.classOfflineTitle(name),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.classOfflineHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.subheadingColor,
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(label: context.l10n.buttonRetry, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// "Please send it again" (design M-C25): the upload box and "I'll do it later".
class ClassResendCard extends StatelessWidget {
  const ClassResendCard({
    super.key,
    required this.onAdd,
    required this.onLater,
  });

  final VoidCallback onAdd;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashedUploadBox(
          child: Column(
            children: [
              const Icon(
                Icons.upload_rounded,
                size: 22,
                color: AppTheme.buttonColor,
              ),
              const SizedBox(height: 8),
              AppPrimaryButton(
                label: context.l10n.classAddMyWork,
                onPressed: onAdd,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.classPhotoNeeded,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.subheadingColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppTonalButton(
          label: context.l10n.classDoLater,
          trailing: Icons.arrow_forward_rounded,
          onPressed: onLater,
        ),
      ],
    );
  }
}

/// The picture and the points of a valid work (design M-C27), then Continue.
class ClassYouWonCard extends StatelessWidget {
  const ClassYouWonCard({
    super.key,
    required this.image,
    required this.label,
    required this.points,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String image;
  final String label;
  final int points;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.classroomMessageSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      '$points',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppPrimaryButton(label: buttonLabel, onPressed: onContinue),
      ],
    );
  }
}

/// Buttons only, under the bubbles: the main choice and an optional second one.
class ClassChoiceButtons extends StatelessWidget {
  const ClassChoiceButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(label: primaryLabel, onPressed: onPrimary),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 8),
          AppTonalButton(label: secondaryLabel!, onPressed: onSecondary),
        ],
      ],
    );
  }
}
