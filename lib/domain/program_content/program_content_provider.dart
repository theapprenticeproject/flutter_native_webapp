import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/asset_loader.dart';
import 'program_content_repository.dart';
import '../reference_data/asset_data_source.dart';
import 'course_detail_model.dart';
import '../profile/student_language_provider.dart';
import '../../core/cache/local_cache_provider.dart';

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
      return repository.fetchCourseDetail(
        courseId,
        lang: ref.watch(studentLanguageProvider),
      );
    });

/// Course id to course name, from the bundled course list. The student picker
/// shows it next to the class ("Class 5 • Science").
final courseNameByIdProvider = FutureProvider<Map<String, String>>((ref) async {
  final repository = await ref.watch(programContentRepositoryProvider.future);
  final courses = await repository.fetchCourseIndex();
  return {for (final c in courses) c.id: c.name.trim()};
});
