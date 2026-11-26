import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/gallery/gallery_header_provider.dart';
import '../../../domain/gallery/gallery_provider.dart';
import '../../../shared/media/open_in_new_tab.dart';
import '../../../shared/widgets/app_nav.dart';
import 'gallery_view.dart';
import 'gallery_viewer.dart';

/// The Gallery tab (R-1, R-6, D9).
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    final notifier = ref.read(galleryProvider.notifier);
    final header = ref.watch(galleryHeaderProvider).valueOrNull;
    final shared = header?.shared ?? false;

    // "Share your work" goes to Home, where the activity card waits.
    void share() => context.go(AppRoutes.home);

    return AppNav(
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: GalleryView(
                  activityTitle: header?.activityTitle,
                  ownWorkUrl: header?.ownWorkUrl,
                  shared: shared,
                  ownName: header?.ownName,
                  grade: header?.grade,
                  items: gallery.items,
                  loading: gallery.loading,
                  failed: gallery.failed,
                  hasMore: gallery.hasMore,
                  loadingMore: gallery.loadingMore,
                  moreFailed: gallery.moreFailed,
                  onShare: share,
                  onLoadMore: notifier.loadMore,
                  onRetry: notifier.load,
                  onOpen: (i) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GalleryViewer(
                        items: gallery.items,
                        initialIndex: i,
                        canShare: !shared,
                        onShare: () {
                          Navigator.of(context).pop();
                          share();
                        },
                        onOpenVideo: openInNewTab,
                      ),
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
