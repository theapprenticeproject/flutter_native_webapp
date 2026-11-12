class ProgramContentCache {
  ProgramContentCache._();

  static const String schemaVersion = 'v2';

  static String _k(String parts) => '$schemaVersion:$parts';

  static String courseIndex(String lang) => _k('program_content:index:$lang');

  static String courseDetail(String courseId, String lang) =>
      _k('program_content:detail:$lang:$courseId');
}
