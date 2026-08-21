import '../data/local/asset_loader.dart';
import '../models/state_model.dart';

class AssetDataSource {
  AssetDataSource(this._assetLoader);

  final AssetLoader _assetLoader;

  static const String _statesPath = 'assets/data/states/states.json';
  static const String _courseIndexPathTemplate =
      'assets/data/courses/{lang}/index.json';
  static const String _courseDetailPathTemplate =
      'assets/data/courses/{lang}/{courseId}.json';

  static String _districtPath(String stateId) =>
      'assets/data/district/${StateModel.assetFileNameFor(stateId)}.json';

  static String _courseIndexPath(String lang) =>
      _courseIndexPathTemplate.replaceFirst('{lang}', lang);

  static String _courseDetailPath(String courseId, String lang) =>
      _courseDetailPathTemplate
          .replaceFirst('{lang}', lang)
          .replaceFirst('{courseId}', courseId);

  Future<List<dynamic>> fetchStatesIndex() =>
      _assetLoader.loadJsonList(_statesPath);

  Future<List<dynamic>> fetchDistrictsForState(String stateId) =>
      _assetLoader.loadJsonList(_districtPath(stateId));

  Future<Map<String, dynamic>> fetchCourseIndex({String lang = 'en'}) =>
      _assetLoader.loadJson(_courseIndexPath(lang));

  Future<Map<String, dynamic>> fetchCourseDetail(
    String courseId, {
    String lang = 'en',
  }) => _assetLoader.loadJson(_courseDetailPath(courseId, lang));
}
