import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/gallery/gallery_models.dart';

/// The body of the Gallery tab (R-6): the current activity, the student's own
/// work, and a grid of other students' valid work with initials only (R-59,
/// R-85), "Load more" and a way into the viewer. It takes plain data so it is
/// easy to test. There is no time-left pill in v1 (R-72).
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
    super.key,
  });

  final String? activityTitle;

  /// A link to the student's own work, when it is known.
  final String? ownWorkUrl;
  final bool shared;
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        if (activityTitle != null) ...[
          Text(
            context.l10n.galleryThisActivity,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.subheadingColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activityTitle!,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Title(context.l10n.galleryYourSubmission),
        const SizedBox(height: 10),
        _OwnWork(url: ownWorkUrl, shared: shared, onShare: onShare),
        const SizedBox(height: 26),
        _Title(context.l10n.galleryFromStudents),
        const SizedBox(height: 10),
        ..._grid(context),
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
        OutlinedButton(
          onPressed: onLoadMore,
          child: Text(context.l10n.galleryLoadMore),
        ),
    ];
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
      fontWeight: FontWeight.w900,
      color: AppTheme.headingText,
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

class _OwnWork extends StatelessWidget {
  const _OwnWork({
    required this.url,
    required this.shared,
    required this.onShare,
  });

  final String? url;
  final bool shared;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    if (!shared) {
      // shortcut: a plain border. The Figma frame has a dashed one.
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_photo_alternate_outlined, size: 36),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onShare,
              child: Text(context.l10n.galleryShareWork),
            ),
          ],
        ),
      );
    }
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.softLavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            Image.network(
              url!,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.image_outlined, size: 40),
            )
          else
            const Icon(Icons.image_outlined, size: 40),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                context.l10n.galleryYouShared,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.buttonColor,
                ),
              ),
            ),
          ),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppTheme.softLavender,
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
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_outlined, size: 36),
                      ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.initials,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
