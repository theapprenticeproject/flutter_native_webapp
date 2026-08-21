import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/models/archetype_step_selector.dart';
import 'package:tapapp/models/learner_archetype.dart';
import 'package:tapapp/models/program_content/course_detail_model.dart';

void main() {
  const steps = [
    CourseAssignmentStepModel(
      step: 1,
      label: 'Emoji response',
      subTypes: 'emoji',
      unguidedText: 'Emoji',
    ),
    CourseAssignmentStepModel(
      step: 2,
      label: 'Word or voice',
      subTypes: 'text,audio',
      unguidedText: 'Reflect',
    ),
    CourseAssignmentStepModel(
      step: 3,
      label: 'Observation',
      subTypes: 'image',
      unguidedText: 'Photo',
    ),
    CourseAssignmentStepModel(
      step: 5,
      label: 'Project evidence',
      subTypes: 'image,video',
      unguidedText: 'Project',
    ),
  ];

  test('selects one progressively richer submission for each archetype', () {
    expect(
      ArchetypeStepSelector.selectStep(steps, LearnerArchetype.dormant)?.step,
      1,
    );
    expect(
      ArchetypeStepSelector.selectStep(steps, LearnerArchetype.fenceSitter)
          ?.step,
      2,
    );
    expect(
      ArchetypeStepSelector.selectStep(
        steps,
        LearnerArchetype.irregularSubmitter,
      )?.step,
      3,
    );
    expect(
      ArchetypeStepSelector.selectStep(steps, LearnerArchetype.submitter)?.step,
      5,
    );
  });
}
