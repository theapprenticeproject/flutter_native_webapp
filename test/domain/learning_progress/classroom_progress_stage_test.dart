import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/classroom_progress_stage.dart';
import 'package:tapapp/domain/learner/enrollment_model.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/domain/learning_progress/activity_models.dart';

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

  // R-66: the work is postponed. Video and quiz are done, no submission yet.
  // The student must come back to the Make step, and Home shows "send project".
  test('video and quiz done, work not sent: the stage is submitProject', () {
    final snapshot = ClassroomProgressResolver.resolve(
      enrollment: const EnrollmentModel(
        videosCompleted: 1,
        quizzesCompleted: 1,
        submissionIndex: 0,
      ),
      unitIndex: 0,
      unit: unit,
    );
    expect(snapshot.stage, ClassroomProgressStage.submitProject);
    expect(snapshot.videoDone, isTrue);
    expect(snapshot.quizDone, isTrue);
    expect(snapshot.submissionDone, isFalse);
  });

  // R-83: a unit is finished only when the feedback is valid. The Worker says
  // whether the work was sent and what the feedback is.
  group('with the feedback state from the Worker', () {
    const done = EnrollmentModel(videosCompleted: 1, quizzesCompleted: 1);

    ClassroomProgressStage stage(
      FeedbackStage feedback, {
      EnrollmentModel enrollment = done,
    }) => ClassroomProgressResolver.resolve(
      enrollment: enrollment,
      unitIndex: 0,
      unit: unit,
      feedback: feedback,
    ).stage;

    test('work not sent: the Make step', () {
      expect(
        stage(FeedbackStage.notSent),
        ClassroomProgressStage.submitProject,
      );
    });

    test('sent, quiz done, no valid feedback yet: awaiting feedback', () {
      for (final f in [
        FeedbackStage.waiting,
        FeedbackStage.slow,
        FeedbackStage.notValid,
        FeedbackStage.notValidNoRetry,
      ]) {
        expect(stage(f), ClassroomProgressStage.awaitingFeedback, reason: '$f');
      }
    });

    test('valid feedback, video and quiz done: the Results chat comes next', () {
      // The unit is not finished yet. It closes after the Results chat (R-68).
      expect(stage(FeedbackStage.valid), ClassroomProgressStage.resultsReady);
    });

    test('sent but the quiz is not done: the quiz comes next', () {
      expect(
        stage(
          FeedbackStage.waiting,
          enrollment: const EnrollmentModel(videosCompleted: 1),
        ),
        ClassroomProgressStage.takeQuiz,
      );
    });

    test('the video comes first, whatever the feedback is', () {
      expect(
        stage(FeedbackStage.valid, enrollment: const EnrollmentModel()),
        ClassroomProgressStage.watchVideo,
      );
    });

    test('a local submission index alone does not finish the unit', () {
      // The Worker said the feedback is not valid: the phone's old index
      // must not open the next unit.
      expect(
        stage(
          FeedbackStage.waiting,
          enrollment: const EnrollmentModel(
            videosCompleted: 1,
            quizzesCompleted: 1,
            submissionIndex: 1,
          ),
        ),
        ClassroomProgressStage.awaitingFeedback,
      );
    });

    test('Home shows "submission pending" while awaiting feedback', () {
      expect(
        ClassroomProgressStage.awaitingFeedback.homeStage,
        LearningStage.submissionPending,
      );
    });

    // A not-valid result is feedback too: Home says "feedback ready" and the
    // button opens the activity, where the page with the message and "Send
    // again" is. Home does not repeat that message.
    test('Home shows "feedback ready" for a work that is not valid', () {
      for (final f in [FeedbackStage.notValid, FeedbackStage.notValidNoRetry]) {
        expect(
          homeStageFor(ClassroomProgressStage.awaitingFeedback, f),
          LearningStage.feedbackReady,
          reason: '$f',
        );
      }
    });

    test('waiting, slow or unknown feedback stays "submission pending"', () {
      for (final f in [FeedbackStage.waiting, FeedbackStage.slow, null]) {
        expect(
          homeStageFor(ClassroomProgressStage.awaitingFeedback, f),
          LearningStage.submissionPending,
          reason: '$f',
        );
      }
    });

    test('the feedback changes no other stage', () {
      for (final stage in ClassroomProgressStage.values) {
        if (stage == ClassroomProgressStage.awaitingFeedback) continue;
        expect(
          homeStageFor(stage, FeedbackStage.notValid),
          stage.homeStage,
          reason: '$stage',
        );
      }
    });

    test('Home shows "feedback ready" when the Results chat is next', () {
      expect(
        ClassroomProgressStage.resultsReady.homeStage,
        LearningStage.feedbackReady,
      );
    });

    test(
      'after the Results chat the phone marks the submission done: finished',
      () {
        // The Results chat calls applyValidFeedback, which bumps this index.
        expect(
          stage(
            FeedbackStage.valid,
            enrollment: const EnrollmentModel(
              videosCompleted: 1,
              quizzesCompleted: 1,
              submissionIndex: 1,
            ),
          ),
          ClassroomProgressStage.unitCompleted,
        );
      },
    );
  });
}
