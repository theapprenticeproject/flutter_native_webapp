import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/asset_loader.dart';
import '../data/repositories/program_content_repository.dart';
import '../data_loader/asset_data_source.dart';
import '../models/program_content/course_detail_model.dart';
import 'local_cache_provider.dart';

final assetDataSourceProvider = Provider<AssetDataSource>((ref) {
  return AssetDataSource(const AssetLoader());
});

final programContentRepositoryProvider =
    FutureProvider<ProgramContentRepository>((ref) async {
      final localCache = await ref.watch(localCacheProvider.future);
      return ProgramContentRepository.create(
        localCache,
        ref.watch(assetDataSourceProvider),
      );
    });

final courseDetailDataProvider = FutureProvider.autoDispose
    .family<CourseDetailModel, String>((ref, courseId) async {
      final repository = await ref.watch(
        programContentRepositoryProvider.future,
      );
      return repository.fetchCourseDetail(courseId);
    });
