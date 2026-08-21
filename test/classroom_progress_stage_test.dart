import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/models/classroom_progress_stage.dart';
import 'package:tapapp/models/enrollment_model.dart';
import 'package:tapapp/models/program_content/course_detail_model.dart';

void main() {
  const unit = CourseUnitModel(
    name: 'Idea Becomes a Business',
    description: '',
    requiredComponents: '',
    difficulty: '',
    xp: 20,
    videos: [
      CourseVideoModel(
        id: 1,
        name: 'Video',
        description: '',
        youtubeId: 'video',
        points: 10,
      ),
    ],
    assignments: [
      CourseAssignmentModel(
        id: 'assignment',
        sequence: 1,
        name: 'Submission',
        description: '',
        type: '',
        difficulty: '',
        steps: [
          CourseAssignmentStepModel(
            step: 1,
            label: 'Step 1',
            subTypes: 'text',
            unguidedText: 'Answer',
          ),
        ],
      ),
    ],
    quiz: CourseQuizModel(
      id: 1,
      name: 'Quiz',
      questions: [
        CourseQuizQuestionModel(
          question: 'Question',
          options: {'a': 'Answer'},
          answerKey: 'a',
        ),
      ],
    ),
  );

  test('advances only after each persisted checkpoint', () {
    expect(
      ClassroomProgressResolver.resolve(
        enrollment: const EnrollmentModel(),
        unitIndex: 0,
        unit: unit,
      ).stage,
      ClassroomProgressStage.watchVideo,
    );

    expect(
      ClassroomProgressResolver.resolve(
        enrollment: const EnrollmentModel(videosCompleted: 1),
        unitIndex: 0,
        unit: unit,
      ).stage,
      ClassroomProgressStage.submitProject,
    );

    expect(
      ClassroomProgressResolver.resolve(
        enrollment: const EnrollmentModel(
          videosCompleted: 1,
          submissionIndex: 1,
        ),
        unitIndex: 0,
        unit: unit,
      ).stage,
      ClassroomProgressStage.takeQuiz,
    );

    expect(
      ClassroomProgressResolver.resolve(
        enrollment: const EnrollmentModel(
          videosCompleted: 1,
          submissionIndex: 1,
          quizzesCompleted: 1,
        ),
        unitIndex: 0,
        unit: unit,
      ).stage,
      ClassroomProgressStage.unitCompleted,
    );
  });

  test('does not use learner-wide submissions as course progress', () {
    expect(
      ClassroomProgressResolver.resolve(
        enrollment: const EnrollmentModel(
          videosCompleted: 1,
          submissionIndex: 0,
        ),
        unitIndex: 0,
        unit: unit,
      ).stage,
      ClassroomProgressStage.submitProject,
    );
  });
}
