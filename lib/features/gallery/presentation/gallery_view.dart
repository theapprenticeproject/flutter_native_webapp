import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/gallery/gallery_models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_tonal_button.dart';
import '../../../shared/widgets/dashed_upload_box.dart';

/// The body of the Gallery tab (R-6; design M-GA-01 and M-GA-02): the logos and
/// the current activity, the student's own work, and a grid of other students'
/// valid work with initials only (R-59, R-85), "Load more" and a way into the
/// viewer. It takes plain data so it is easy to test. There is no time-left
/// pill in v1 (R-72), and the "+25" pill of the design waits for the points
/// of the activity.
class GalleryView extends StatelessWidget {
  const GalleryView({
    required this.activityTitle,
    required this.ownWorkUrl,
    required this.shared,
    required this.items,
    required this.loading,
    required this.failed,
    required this.hasMore,
    required this.loadingMore,
    required this.moreFailed,
    required this.onShare,
    required this.onLoadMore,
    required this.onRetry,
    required this.onOpen,
    this.ownName,
    this.grade,
    super.key,
  });

  final String? activityTitle;

  /// A link to the student's own work, when it is known.
  final String? ownWorkUrl;
  final bool shared;

  /// The student's own name and class (for "Aarav Kumar (You)" and the line
  /// under "From TAP students like you").
  final String? ownName;
  final String? grade;
  final List<GalleryItem> items;
  final bool loading;
  final bool failed;
  final bool hasMore;
  final bool loadingMore;
  final bool moreFailed;
  final VoidCallback onShare;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final grade = this.grade?.trim() ?? '';
    return Column(
      children: [
        _Top(activityTitle: activityTitle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(child: _Title(context.l10n.galleryYourSubmission)),
                  if (shared) const _SharedChip(),
                ],
              ),
              const SizedBox(height: 10),
              _OwnWork(
                url: ownWorkUrl,
                shared: shared,
                name: ownName,
                onShare: onShare,
              ),
              const SizedBox(height: 26),
              _Title(context.l10n.galleryFromStudents),
              if (grade.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  context.l10n.galleryFromStudentsSub(grade),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.subheadingColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              ..._grid(context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _grid(BuildContext context) {
    if (loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (failed) {
      return [
        _Message(context.l10n.galleryLoadFailed),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.buttonTryAgain),
        ),
      ];
    }
    if (items.isEmpty) {
      // shortcut: the curriculum team's example works (R-58) are not bundled
      // yet. Show them here when that content exists.
      return [_Message(context.l10n.galleryEmpty)];
    }
    return [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) =>
            _Tile(item: items[i], onTap: () => onOpen(i)),
      ),
      const SizedBox(height: 14),
      if (moreFailed) ...[
        _Message(context.l10n.galleryLoadMoreFailed),
        const SizedBox(height: 8),
      ],
      if (loadingMore)
        const Center(child: CircularProgressIndicator())
      else if (hasMore)
        AppTonalButton(
          label: context.l10n.galleryLoadMore,
          onPressed: onLoadMore,
        ),
    ];
  }
}

/// The white top of the page: the logos, "THIS WEEK'S ACTIVITY" and its name.
class _Top extends StatelessWidget {
  const _Top({required this.activityTitle});

  final String? activityTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PostOnboardingBrand(compact: true),
          if (activityTitle != null) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.galleryThisActivity,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.buttonColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activityTitle!,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AppTheme.headingText,
    ),
  );
}

class _SharedChip extends StatelessWidget {
  const _SharedChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F7EE),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: AppTheme.successGreen,
        ),
        const SizedBox(width: 5),
        Text(
          context.l10n.galleryYouShared,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.successGreen,
          ),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subheadingColor),
    ),
  );
}

/// The small round badge with the initials of a student.
class InitialsCircle extends StatelessWidget {
  const InitialsCircle(this.initials, {super.key});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('initials-circle'),
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFE8E8FB),
      shape: BoxShape.circle,
    ),
    child: Text(
      initials,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.buttonColor,
      ),
    ),
  );
}

class _OwnWork extends StatelessWidget {
  const _OwnWork({
    required this.url,
    required this.shared,
    required this.name,
    required this.onShare,
  });

  final String? url;
  final bool shared;
  final String? name;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    if (!shared) {
      // Design M-GA-02: a dashed box that says the work is not here yet.
      return DashedUploadBox(
        key: const ValueKey('own-work-empty'),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 24,
              color: AppTheme.headingText,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.galleryNotHere,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.headingText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.galleryNotHereBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: context.l10n.galleryShareWork,
              onPressed: onShare,
            ),
          ],
        ),
      );
    }
    final who = (name ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.buttonColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E3EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: url != null
                ? Image.network(
                    url!,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_outlined, size: 40),
                  )
                : const Icon(Icons.image_outlined, size: 40),
          ),
          if (who.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                InitialsCircle(initialsOf(who)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.galleryYouSuffix(who),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.buttonColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});

  final GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.isVideo
          ? context.l10n.galleryVideoBy(item.initials)
          : context.l10n.galleryWorkBy(item.initials),
      button: true,
      child: InkWell(
        key: ValueKey('work-card-${item.submissionId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ColoredBox(
                      color: const Color(0xFFEDEDF3),
                      child: item.isVideo
                          ? const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 44,
                                color: AppTheme.buttonColor,
                              ),
                            )
                          : Image.network(
                              item.url,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.fallback,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_outlined, size: 36),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [InitialsCircle(item.initials)]),
            ],
          ),
        ),
      ),
    );
  }
}
