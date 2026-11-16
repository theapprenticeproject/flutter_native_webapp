import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/http_client_provider.dart';
import 'gallery_notifier.dart';
import 'gallery_repository.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => GalleryRepository(ref.watch(httpClientProvider)),
);

/// The Gallery grid. It loads the first page when the tab opens.
final galleryProvider =
    StateNotifierProvider.autoDispose<GalleryNotifier, GalleryState>((ref) {
      final notifier = GalleryNotifier(ref.watch(galleryRepositoryProvider));
      notifier.load();
      return notifier;
    });
