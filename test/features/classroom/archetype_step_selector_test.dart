import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/models/archetype_step_selector.dart';
import 'package:tapapp/features/classroom/models/learner_archetype.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';

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
      ArchetypeStepSelector.selectStep(
        steps,
        LearnerArchetype.fenceSitter,
      )?.step,
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

  // R-63: the Make step in v1 is a photo or a video. Most bundled units have an
  // emoji step, a word step and an image step, and no image-and-video step. The
  // student must get the image step, not the first one (the emoji).
  test(
    'a student gets the photo step when there is no image-and-video step',
    () {
      const unit = [
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
      ];
      final step = ArchetypeStepSelector.selectStep(
        unit,
        LearnerArchetype.submitter,
      );
      expect(step?.step, 3);
      expect(step?.subTypes, 'image');
    },
  );

  test('the video step is preferred over the photo step when both exist', () {
    expect(
      ArchetypeStepSelector.selectStep(steps, LearnerArchetype.submitter)?.step,
      5,
      reason: 'image,video is the richest',
    );
  });

  test(
    'a student never gets an emoji step when a photo or video step exists',
    () {
      const onlyVideo = [
        CourseAssignmentStepModel(
          step: 1,
          label: 'Emoji',
          subTypes: 'emoji',
          unguidedText: 'x',
        ),
        CourseAssignmentStepModel(
          step: 2,
          label: 'Video',
          subTypes: 'video',
          unguidedText: 'y',
        ),
      ];
      expect(
        ArchetypeStepSelector.selectStep(
          onlyVideo,
          LearnerArchetype.submitter,
        )?.step,
        2,
      );
    },
  );

  test(
    'every bundled unit with assignment steps gives the student a photo or video step',
    () {
      final problems = <String>[];
      var checked = 0;
      for (final f in Directory(
        'assets/data/courses',
      ).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.json')) continue;
        final json = jsonDecode(f.readAsStringSync());
        if (json is! Map || json['units'] is! List) continue;
        for (final unit in json['units'] as List) {
          for (final a in ((unit as Map)['assigns'] as List? ?? const [])) {
            final steps = CourseAssignmentModel.fromJson(
              Map<String, dynamic>.from(a as Map),
            ).steps;
            // A few units have an assignment with no steps (a content gap). The
            // app treats those as "no submission needed".
            if (steps.isEmpty) continue;
            checked++;
            final chosen = ArchetypeStepSelector.selectStep(
              steps,
              LearnerArchetype.submitter,
            );
            final sub = (chosen?.subTypes ?? '').toLowerCase();
            if (!sub.contains('image') && !sub.contains('video')) {
              problems.add('${f.path} ${unit['uid']}: "$sub"');
            }
          }
        }
      }
      expect(checked, greaterThan(0));
      expect(problems, isEmpty, reason: problems.take(5).join('\n'));
    },
  );
}
