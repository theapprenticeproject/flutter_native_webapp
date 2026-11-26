import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';

/// Where the student's photo or video comes from.
enum MediaSource { camera, video, library }

/// A phone asks first (the WhatsApp browser opens the photo picker and has no
/// camera entry). A laptop has no camera choice, so its file dialog opens at once.
bool usesSourceSheet(TargetPlatform platform) =>
    platform == TargetPlatform.android || platform == TargetPlatform.iOS;

/// "Choose an action" (design M-S-02): round icons with a word under each.
/// [allowPhoto] shows Camera, [allowVideo] shows Video, and Photos is always
/// there. Closing the sheet answers null.
class MediaSourceSheet extends StatelessWidget {
  const MediaSourceSheet({
    super.key,
    required this.allowPhoto,
    required this.allowVideo,
  });

  final bool allowPhoto;
  final bool allowVideo;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.classChooseAction,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (allowPhoto)
                  _Action(
                    icon: Icons.photo_camera_outlined,
                    label: l.classCameraOption,
                    onTap: () => Navigator.pop(context, MediaSource.camera),
                  ),
                if (allowVideo)
                  _Action(
                    icon: Icons.videocam_outlined,
                    label: l.classVideoOption,
                    onTap: () => Navigator.pop(context, MediaSource.video),
                  ),
                _Action(
                  icon: Icons.photo_library_outlined,
                  label: l.classPhotosOption,
                  onTap: () => Navigator.pop(context, MediaSource.library),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppTheme.buttonColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textColor),
          ),
        ],
      ),
    ),
  );
}
