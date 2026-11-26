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
    this.createdAt,
    this.viewUrl,
  });

  final String unitName;
  final String assignmentId;
  final FeedbackStage stage;

  /// The Worker's feedback text, when there is one.
  final String? feedback;
  final int? score;

  /// When the work was sent, and a signed link to it (it expires).
  final DateTime? createdAt;
  final String? viewUrl;
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
        createdAt: latest?.createdAt,
        viewUrl: latest?.viewUrl,
      ),
    );
    if (projects.length == projectsPerYear) break;
  }
  return projects;
}

/// How many projects have valid feedback ("3 / 6 done").
int doneCount(List<MyProject> projects) =>
    projects.where((p) => p.stage == FeedbackStage.valid).length;

/// Where a project sits on the path (design M-ME-01).
enum PathState { done, current, locked }

class PathNode {
  const PathNode(this.project, this.state, this.number);
  final MyProject project;
  final PathState state;

  /// 1, 2, 3 ...
  final int number;
}

/// The path of the year: the projects with valid feedback are done, the first
/// one that is not is the current one ("you are here"), and the rest are locked.
/// A project is never done before the one in front of it: the units come in
/// sequence (R-83).
List<PathNode> projectPath(List<MyProject> projects) {
  var currentSeen = false;
  PathState stateOf(MyProject p) {
    if (currentSeen) return PathState.locked;
    if (p.stage == FeedbackStage.valid) return PathState.done;
    currentSeen = true;
    return PathState.current;
  }

  return [
    for (var i = 0; i < projects.length; i++)
      PathNode(projects[i], stateOf(projects[i]), i + 1),
  ];
}
