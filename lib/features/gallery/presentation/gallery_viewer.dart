import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/gallery/gallery_models.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF15151A),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  color: Colors.white,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    '${_index + 1} of ${widget.items.length}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous',
                  color: Colors.white,
                  icon: const Icon(Icons.chevron_left_rounded, size: 34),
                  onPressed: _index > 0 ? () => _go(_index - 1) : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Swipe to see more',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Next',
                  color: Colors.white,
                  icon: const Icon(Icons.chevron_right_rounded, size: 34),
                  onPressed: _index < last ? () => _go(_index + 1) : null,
                ),
              ],
            ),
            if (widget.canShare)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Want to share your work too?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.onShare,
                      child: const Text('Share your work'),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
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
              color: Colors.white,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => onOpenVideo(item.url),
              child: const Text('Open video'),
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
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
