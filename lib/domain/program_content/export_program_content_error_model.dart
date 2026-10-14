enum ProgramContentErrorReason {
  courseNotFound,
  languageNotAvailable,
  malformedContent,
}

class ExportProgramContentErrorModel implements Exception {
  const ExportProgramContentErrorModel({
    required this.reason,
    required this.detail,
  });

  final ProgramContentErrorReason reason;
  final String detail;

  factory ExportProgramContentErrorModel.courseNotFound(String courseId) =>
      ExportProgramContentErrorModel(
        reason: ProgramContentErrorReason.courseNotFound,
        detail: 'No course found for id "$courseId"',
      );

  factory ExportProgramContentErrorModel.languageNotAvailable(String lang) =>
      ExportProgramContentErrorModel(
        reason: ProgramContentErrorReason.languageNotAvailable,
        detail: 'No content bundle available for language "$lang"',
      );

  factory ExportProgramContentErrorModel.malformed(String source) =>
      ExportProgramContentErrorModel(
        reason: ProgramContentErrorReason.malformedContent,
        detail: 'Malformed content at "$source"',
      );

  @override
  String toString() =>
      'ExportProgramContentErrorModel(${reason.name}: $detail)';
}
