import '../program_content/course_detail_model.dart';
import '../progress/progress_models.dart';
import '../submission/feedback_state.dart';

/// There are 6 projects a year (R-87).
/// shortcut: the cap is a constant. Use the real number when the course data
/// says how many projects count.
const projectsPerYear = 6;

/// One project in "My projects this year": a unit's work and where it stands.
class MyProject {
  const MyProject({
    required this.unitName,
    required this.assignmentId,
    required this.stage,
    this.feedback,
    this.score,
  });

  final String unitName;
  final String assignmentId;
  final FeedbackStage stage;

  /// The Worker's feedback text, when there is one.
  final String? feedback;
  final int? score;

  /// The label of the Figma frames: pending, given, wrong format.
  String get label => switch (stage) {
    FeedbackStage.notSent => 'Not started',
    FeedbackStage.waiting => 'Feedback pending',
    FeedbackStage.slow => 'Taking longer than expected',
    FeedbackStage.valid => 'Feedback given',
    FeedbackStage.notValid => 'Wrong format',
    FeedbackStage.notValidNoRetry => 'Not accepted',
  };
}

/// The text under a project: the Worker's feedback when there is some, and a
/// plain line for each state otherwise (the Figma "Feedback pending", "Feedback
/// given" and "Wrong format" screens).
extension MyProjectDetail on MyProject {
  String get detail {
    final text = feedback?.trim() ?? '';
    switch (stage) {
      case FeedbackStage.notSent:
        return 'You have not sent this project yet.';
      case FeedbackStage.waiting:
        return "I'm looking at your work. Please wait. "
            'Points will be provided after feedback.';
      case FeedbackStage.slow:
        return 'Your feedback is taking longer than expected. '
            'Please check again a little later.';
      case FeedbackStage.valid:
        return text.isEmpty ? 'Your project is valid. Well done!' : text;
      case FeedbackStage.notValid:
        return '${text.isEmpty ? 'This project needs another try.' : text}\n\n'
            'Open the activity from Home to send it again.';
      case FeedbackStage.notValidNoRetry:
        return '${text.isEmpty ? 'This project was not accepted.' : text}\n\n'
            'You have used both tries, so you cannot send it again.';
    }
  }
}

/// The projects of the course: one for each unit that has an assignment, at
/// most [projectsPerYear]. The state of each comes from the Worker's submissions
/// (the newest attempt decides, R-76).
///
/// [submissions] is null when the Worker could not be reached. Then
/// [savedStage] gives the last state saved on the phone for an assignment.
List<MyProject> buildProjects(
  List<CourseUnitModel> units,
  List<SubmissionInfo>? submissions, {
  DateTime? now,
  FeedbackStage? Function(String assignmentId)? savedStage,
}) {
  final projects = <MyProject>[];
  for (final unit in units) {
    final assignmentId = unit.assignments.firstOrNull?.assignmentId ?? '';
    if (assignmentId.isEmpty) continue;
    final latest = submissions == null
        ? null
        : latestFor(assignmentId, submissions);
    projects.add(
      MyProject(
        unitName: unit.name,
        assignmentId: assignmentId,
        stage: submissions == null
            ? (savedStage?.call(assignmentId) ?? FeedbackStage.notSent)
            : feedbackStage(latest, now: now),
        feedback: latest?.feedback,
        score: latest?.score,
      ),
    );
    if (projects.length == projectsPerYear) break;
  }
  return projects;
}

/// How many projects have valid feedback ("3 / 6 done").
int doneCount(List<MyProject> projects) =>
    projects.where((p) => p.stage == FeedbackStage.valid).length;
