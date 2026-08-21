import 'learner_archetype.dart';
import 'program_content/course_detail_model.dart';

class ArchetypeStepSelector {
  ArchetypeStepSelector._();

  static CourseAssignmentModel? selectAssignment(
    List<CourseAssignmentModel> assignments,
    String archetype,
  ) {
    if (assignments.isEmpty) return null;

    final normalized = LearnerArchetype.normalize(archetype);
    for (final assignment in assignments) {
      if (assignment.id.toLowerCase().contains(normalized)) {
        return assignment;
      }
    }
    return assignments.first;
  }

  static CourseAssignmentStepModel? selectStep(
    List<CourseAssignmentStepModel> steps,
    String archetype,
  ) {
    if (steps.isEmpty) return null;

    final normalized = LearnerArchetype.normalize(archetype);
    final preferredKinds = switch (normalized) {
      LearnerArchetype.dormant => const ['emoji'],
      LearnerArchetype.fenceSitter => const ['text,audio', 'audio', 'text'],
      LearnerArchetype.irregularSubmitter => const ['image'],
      LearnerArchetype.submitter => const ['image,video', 'video'],
      _ => const ['emoji'],
    };

    for (final preferred in preferredKinds) {
      for (final step in steps) {
        if (_normalizeSubTypes(step.subTypes) == preferred) return step;
      }
    }
    return steps.first;
  }

  static String _normalizeSubTypes(String value) => value
      .split(',')
      .map((part) => part.trim().toLowerCase())
      .where((part) => part.isNotEmpty)
      .join(',');
}
