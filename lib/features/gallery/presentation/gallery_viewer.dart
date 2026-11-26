import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/gallery/gallery_models.dart';
import '../../../shared/widgets/app_primary_button.dart';
import 'gallery_view.dart';

/// The full-screen viewer (R-6): "1 of 9", previous and next, swipe, close. A
/// student who has not shared is invited to ("Want to share your work too?").
class GalleryViewer extends StatefulWidget {
  const GalleryViewer({
    required this.items,
    required this.initialIndex,
    required this.canShare,
    required this.onShare,
    required this.onOpenVideo,
    super.key,
  });

  final List<GalleryItem> items;
  final int initialIndex;
  final bool canShare;
  final VoidCallback onShare;
  final void Function(String url) onOpenVideo;

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int to) => _controller.animateToPage(
    to,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final last = widget.items.length - 1;
    final item = widget.items[_index];
    // Design M-GA-03: a white page. "1 of 9" and the close button on top, the
    // work, who made it, and the way to share your own (M-GA-03b).
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.galleryPosition(
                        _index + 1,
                        widget.items.length,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.subheadingColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.galleryClose,
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F0F4),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _Page(
                  item: widget.items[i],
                  onOpenVideo: widget.onOpenVideo,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [InitialsCircle(item.initials)]),
            ),
            if (widget.canShare)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.galleryWantToShare,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.galleryNotHereBody,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.subheadingColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      label: context.l10n.galleryShareWork,
                      onPressed: widget.onShare,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  _Arrow(
                    tooltip: context.l10n.galleryPrevious,
                    icon: Icons.arrow_back_rounded,
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.gallerySwipe,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.subheadingColor,
                      ),
                    ),
                  ),
                  _Arrow(
                    tooltip: context.l10n.galleryNext,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _index < last ? () => _go(_index + 1) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon, size: 20),
    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F0F4)),
    onPressed: onPressed,
  );
}

class _Page extends StatelessWidget {
  const _Page({required this.item, required this.onOpenVideo});

  final GalleryItem item;
  final void Function(String url) onOpenVideo;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              size: 80,
              color: AppTheme.buttonColor,
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: context.l10n.galleryOpenVideo,
              onPressed: () => onOpenVideo(item.url),
            ),
          ],
        ),
      );
    }
    return InteractiveViewer(
      child: Center(
        child: Image.network(
          item.url,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image_outlined,
            size: 60,
            color: AppTheme.imagePlaceholder,
          ),
        ),
      ),
    );
  }
}
