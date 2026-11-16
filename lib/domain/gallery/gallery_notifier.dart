import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gallery_models.dart';
import 'gallery_repository.dart';

class GalleryState {
  const GalleryState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.failed = false,
    this.moreFailed = false,
    this.hasMore = false,
  });

  final List<GalleryItem> items;

  /// The first page is loading.
  final bool loading;
  final bool loadingMore;

  /// The first page could not be loaded.
  final bool failed;

  /// "Load more" failed. What is on screen stays.
  final bool moreFailed;
  final bool hasMore;

  GalleryState copyWith({
    List<GalleryItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? failed,
    bool? moreFailed,
    bool? hasMore,
  }) => GalleryState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    failed: failed ?? this.failed,
    moreFailed: moreFailed ?? this.moreFailed,
    hasMore: hasMore ?? this.hasMore,
  );
}

/// Loads the Gallery page by page.
class GalleryNotifier extends StateNotifier<GalleryState> {
  GalleryNotifier(this._repo) : super(const GalleryState());

  final GalleryRepository _repo;
  String? _cursor;

  Future<void> load() async {
    state = const GalleryState();
    try {
      final page = await _repo.page();
      _cursor = page.cursor;
      state = GalleryState(
        items: page.items,
        loading: false,
        hasMore: page.hasMore,
      );
    } catch (_) {
      state = const GalleryState(loading: false, failed: true);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    state = state.copyWith(loadingMore: true, moreFailed: false);
    try {
      final page = await _repo.page(cursor: _cursor);
      _cursor = page.cursor;
      // The order is random, so the same work can come twice: show it once.
      final seen = state.items.map((i) => i.submissionId).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((i) => !seen.contains(i.submissionId)),
        ],
        loadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false, moreFailed: true);
    }
  }
}
