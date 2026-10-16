enum ProgramContentErrorReason {
  courseNotFound,
  languageNotAvailable,
  malformedContent,
}

class ExportProgramContentErrorModel implements Exception {
  const ExportProgramContentErrorModel({
    required this.reason,
    required this.detail,
    this.cause,
  });

  final ProgramContentErrorReason reason;
  final String detail;

  /// The underlying error, when this one wraps another (for example a failed
  /// asset load or cache write).
  final Object? cause;

  factory ExportProgramContentErrorModel.courseNotFound(
    String courseId, [
    Object? cause,
  ]) => ExportProgramContentErrorModel(
    reason: ProgramContentErrorReason.courseNotFound,
    detail: 'No course found for id "$courseId"',
    cause: cause,
  );

  factory ExportProgramContentErrorModel.languageNotAvailable(String lang) =>
      ExportProgramContentErrorModel(
        reason: ProgramContentErrorReason.languageNotAvailable,
        detail: 'No content bundle available for language "$lang"',
      );

  factory ExportProgramContentErrorModel.malformed(
    String source, [
    Object? cause,
  ]) => ExportProgramContentErrorModel(
    reason: ProgramContentErrorReason.malformedContent,
    detail: 'Malformed content at "$source"',
    cause: cause,
  );

  @override
  String toString() =>
      'ExportProgramContentErrorModel(${reason.name}: $detail'
      '${cause == null ? '' : '; cause: $cause'})';
}
