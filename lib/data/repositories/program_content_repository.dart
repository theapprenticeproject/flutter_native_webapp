import '../../core/cache/domain_cache/program_content_cache.dart';
import '../../core/cache/local_cache.dart';
import '../../data_loader/asset_data_source.dart';
import '../../data_loader/data_loader.dart';
import '../../models/program_content/course_detail_model.dart';
import '../../models/program_content/course_index_entry_model.dart';
import '../../models/program_content/export_program_content_error_model.dart';

class ProgramContentRepository {
  ProgramContentRepository(this._dataLoader, this._assetDataSource);

  final DataLoader _dataLoader;
  final AssetDataSource _assetDataSource;

  static ProgramContentRepository create(
    LocalCache localCache,
    AssetDataSource assetDataSource,
  ) => ProgramContentRepository(DataLoader(localCache), assetDataSource);

  Future<List<CourseIndexEntryModel>> fetchCourseIndex({
    String lang = 'en',
    bool forceRefresh = false,
  }) async {
    final json = await _dataLoader.loadJson(
      cacheKey: ProgramContentCache.courseIndex(lang),
      fetch: () => _assetDataSource.fetchCourseIndex(lang: lang),
      forceRefresh: forceRefresh,
    );
    return CourseIndexEntryModel.listFromJson(json['courses']);
  }

  Future<CourseDetailModel> fetchCourseDetail(
    String courseId, {
    String lang = 'en',
    bool forceRefresh = false,
  }) async {
    Map<String, dynamic> json;
    try {
      json = await _dataLoader.loadJson(
        cacheKey: ProgramContentCache.courseDetail(courseId, lang),
        fetch: () => _assetDataSource.fetchCourseDetail(courseId, lang: lang),
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      throw ExportProgramContentErrorModel.courseNotFound(courseId);
    }

    try {
      return CourseDetailModel.fromJson(json);
    } catch (_) {
      throw ExportProgramContentErrorModel.malformed(
        ProgramContentCache.courseDetail(courseId, lang),
      );
    }
  }

  Future<void> invalidateCourse(String courseId, {String lang = 'en'}) =>
      _dataLoader.invalidate(ProgramContentCache.courseDetail(courseId, lang));

  Future<void> invalidateIndex({String lang = 'en'}) =>
      _dataLoader.invalidate(ProgramContentCache.courseIndex(lang));
}
