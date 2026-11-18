/// The Worker named a course that is not bundled in the app.
///
/// In v1 all course content is inside the app (decided 2026-11-09), so the
/// Worker's `course_id` must be one of the bundled ids. The app shows an error
/// and does not quietly show another course. The id is for logs only and is
/// never shown to the student.
class CourseNotBundledException implements Exception {
  const CourseNotBundledException(this.courseId);

  final String? courseId;

  @override
  String toString() => 'CourseNotBundledException($courseId)';
}

/// The course to use for the Worker's [courseId]. It must match a bundled id
/// exactly (capital letters and spelling too). Otherwise it throws
/// [CourseNotBundledException].
String resolveBundledCourse(String? courseId, Iterable<String> bundled) {
  if (courseId != null && courseId.isNotEmpty && bundled.contains(courseId)) {
    return courseId;
  }
  throw CourseNotBundledException(courseId);
}
