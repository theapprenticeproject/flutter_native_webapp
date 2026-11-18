import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/learner/learner_state_model.dart';
import '../../../domain/learner/learner_state_repository.dart';
import '../../../domain/learning_progress/picture_pieces.dart';
import '../../../domain/learning_progress/postponed_work.dart';
import '../../../domain/submission/feedback_state.dart';
import '../../../domain/submission/feedback_tracker.dart';
import '../../../domain/progress/progress_repository.dart';
import '../../../domain/progress/quiz_answers.dart';
import '../../../domain/progress/step_recorder.dart';
import '../../../domain/submission/submission_repository.dart';
import '../../../domain/submission/work_submitter.dart';
import '../../../core/network/api_exception.dart';
import '../models/activity_flow_model.dart';
import '../models/archetype_step_selector.dart';
import '../models/class_chat_message_model.dart';
import '../../../domain/learning_progress/classroom_progress_stage.dart';
import '../../../domain/learner/enrollment_model.dart';
import '../models/learner_archetype.dart';
import '../../../domain/program_content/course_detail_model.dart';
import '../models/submission_answer_model.dart';

/// `leave`: the student goes back to Home with the unit still open (R-66).
enum ClassSessionOutcome { none, choice, leave }

class ClassQuizToast {
  const ClassQuizToast({
    required this.id,
    required this.isCorrect,
    this.correctAnswer,
  });

  final int id;
  final bool isCorrect;
  final String? correctAnswer;
}

class ClassChatController extends ChangeNotifier {
  ClassChatController({
    required this.learnerId,
    required this.phone,
    required this.studentName,
    required this.courseDisplay,
    required ActivityFlowModel flow,
    required CourseUnitModel unit,
    CourseUnitModel? nextUnit,
    required this.unitIndex,
    required LearnerStateModel initialLearnerState,
    required LearnerStateRepository learnerStateRepository,
    required StepRecorder stepRecorder,
    required WorkSubmitter workSubmitter,
    required FeedbackTracker feedbackTracker,
    FeedbackStage? initialFeedback,
    VoidCallback? onProgressSaved,
  }) : _flow = flow,
       _unit = unit,
       _nextUnit = nextUnit,
       _learnerStateRepository = learnerStateRepository,
       _stepRecorder = stepRecorder,
       _workSubmitter = workSubmitter,
       _feedbackTracker = feedbackTracker,
       _feedback = initialFeedback,
       _learnerState = initialLearnerState,
       _startingPoints = initialLearnerState.xp ?? 0,
       _onProgressSaved = onProgressSaved {
    _begin();
  }

  final String learnerId;
  final String phone;
  final String studentName;
  final String courseDisplay;
  final int unitIndex;

  String get unitName => _unit.name;
  bool get hasNextUnit => _nextUnit != null;
  String get nextUnitName => _nextUnit?.name ?? _unit.name;

  final ActivityFlowModel _flow;
  final CourseUnitModel _unit;
  final CourseUnitModel? _nextUnit;
  final LearnerStateRepository _learnerStateRepository;
  final StepRecorder _stepRecorder;
  final WorkSubmitter _workSubmitter;
  final FeedbackTracker _feedbackTracker;

  /// Where the work for this unit stands (R-83). Null: not known.
  FeedbackStage? _feedback;

  /// The newest submission and its feedback, when the Worker answered.
  SubmissionInfo? _latestSubmission;

  /// The student has seen the Results chat (or the unit was closed before).
  /// Valid feedback closes the unit only after this (R-68).
  late bool _resultsDone;

  /// "Send again" is running: the next send replaces a not-valid one (R-76).
  bool _resending = false;
  final VoidCallback? _onProgressSaved;

  LearnerStateModel _learnerState;
  LearnerStateModel get learnerState => _learnerState;
  final int _startingPoints;

  // v1 has one flow for every student (R-61). The old archetype is gone. This
  // fixed value keeps the Make step a photo or a video (R-63). The step
  // selector is rebuilt in M3 to M5.
  String get _currentArchetype => LearnerArchetype.submitter;

  final List<ClassChatMessage> _messages = [];
  List<ClassChatMessage> get messages => List.unmodifiable(_messages);

  bool get isAwaitingInput => _awaitingInput;
  bool _awaitingInput = false;

  bool get isAwaitingContinue => _awaitingContinue;
  bool _awaitingContinue = false;

  ClassSessionOutcome get outcome => _outcome;
  ClassSessionOutcome _outcome = ClassSessionOutcome.none;

  String? get errorMessage => _errorMessage;
  String? _errorMessage;

  int _quizIndex = 0;
  int _quizCorrectCount = 0;

  /// The student's answers in question order, kept until the quiz is sent.
  final List<QuizAnswer> _quizAnswers = [];

  int _accumulatedVideoPoints = 0;
  int _accumulatedSubmissionPoints = 0;
  int _accumulatedQuizPoints = 0;
  int _completedUnitPoints = 0;
  bool _videoWatchedThisUnit = false;
  bool _submissionAcceptedThisUnit = false;
  bool _videoProgressSaved = false;
  bool _submissionProgressSaved = false;
  bool _quizProgressSaved = false;
  bool _submissionRewardShown = false;
  int _quizToastId = 0;
  ClassQuizToast? _quizToast;
  ClassQuizToast? get quizToast => _quizToast;

  SubmissionAnswer? _pendingWorkAnswer;

  /// The student chose "I'll do it later" on the Make step (R-66). Nothing is
  /// written to the server.
  bool _submissionPostponed = false;

  /// The student's total points from the last `submit_artwork` answer, saved
  /// when the step is saved on the phone.
  int? _pendingServerPoints;

  CourseAssignmentStepModel? _pendingAssignmentStep;
  CourseAssignmentModel? _pendingAssignment;

  final List<Timer> _pendingTimers = [];
  int _msgCounter = 0;

  CourseUnitModel get _currentUnit => _unit;
  CourseVideoModel? get _currentVideo {
    final vids = _currentUnit.videos;
    return vids.isNotEmpty ? vids.first : null;
  }

  CourseAssignmentModel? get _currentAssignment =>
      ArchetypeStepSelector.selectAssignment(
        _currentUnit.assignments,
        _currentArchetype,
      );

  List<CourseQuizQuestionModel> get _quizQuestions =>
      _currentUnit.quiz?.questions ?? const [];

  int get sessionTotalPoints =>
      _accumulatedVideoPoints +
      _accumulatedSubmissionPoints +
      _accumulatedQuizPoints;

  int get startingPoints => _startingPoints;

  int get displayedTotalPoints => startingPoints + sessionTotalPoints;

  ClassroomProgressStage get currentProgressStage {
    if (!_videoWatchedThisUnit) return ClassroomProgressStage.watchVideo;
    if (!_submissionAcceptedThisUnit) {
      return ClassroomProgressStage.submitProject;
    }
    if (!_quizProgressSaved) return ClassroomProgressStage.takeQuiz;
    if (_submissionNotRequired) return ClassroomProgressStage.unitCompleted;
    if (!(_feedback?.opensNextUnit ?? false)) {
      return ClassroomProgressStage.awaitingFeedback;
    }
    if (!_resultsDone) return ClassroomProgressStage.resultsReady;
    return ClassroomProgressStage.unitCompleted;
  }

  /// The unit can close only after valid feedback (R-83), unless it has no
  /// submission.
  bool get _feedbackAllowsCompletion =>
      _submissionNotRequired ||
      ((_feedback?.opensNextUnit ?? false) && _resultsDone);

  /// How many of the 4 pieces of today's picture are unlocked (R-69). It counts
  /// what the Worker has confirmed, and the 4th piece waits for valid feedback.
  int get unlockedPictureCount => unlockedPieces(
    videoDone: _videoWatchedThisUnit && _videoProgressSaved,
    workSent: _submissionAcceptedThisUnit,
    quizDone: _quizProgressSaved,
    feedbackValid: _feedback?.opensNextUnit ?? false,
  );

  double get revealProgress => pieceFraction(unlockedPictureCount);

  bool get _submissionNotRequired =>
      _currentAssignment == null || _currentAssignment!.steps.isEmpty;

  bool get _quizNotRequired => _quizQuestions.isEmpty;

  bool get _hasCompletedRequiredStages =>
      _videoWatchedThisUnit &&
      _feedbackAllowsCompletion &&
      (_quizNotRequired || _quizProgressSaved);

  void _resumeCurrentStage() {
    switch (currentProgressStage) {
      case ClassroomProgressStage.watchVideo:
        _showVideoStartCheckpoint();
        return;
      case ClassroomProgressStage.submitProject:
        _runStep('AF-006');
        return;
      case ClassroomProgressStage.takeQuiz:
        _showQuizStartCheckpoint();
        return;
      case ClassroomProgressStage.awaitingFeedback:
        _showWaitingForFeedback();
        return;
      case ClassroomProgressStage.resultsReady:
        unawaited(_showResults());
        return;
      case ClassroomProgressStage.unitCompleted:
        return;
    }
  }

  void _begin() {
    final enrollment = _learnerState.enrollment;
    final progress = ClassroomProgressResolver.resolve(
      enrollment: enrollment ?? const EnrollmentModel(),
      unitIndex: unitIndex,
      unit: _currentUnit,
      feedback: _feedback,
    );
    _videoWatchedThisUnit = progress.videoDone;
    _resultsDone = (enrollment?.submissionIndex ?? 0) > unitIndex;
    _submissionAcceptedThisUnit = progress.workSent;
    _videoProgressSaved = _videoWatchedThisUnit;
    _submissionProgressSaved = _submissionAcceptedThisUnit;
    _quizProgressSaved = progress.quizDone;

    switch (progress.stage) {
      case ClassroomProgressStage.watchVideo:
        _runStep('AF-001');
        return;
      case ClassroomProgressStage.submitProject:
        _runStep('AF-006');
        return;
      case ClassroomProgressStage.takeQuiz:
        _showQuizStartCheckpoint();
        return;
      case ClassroomProgressStage.awaitingFeedback:
        _showWaitingForFeedback();
        return;
      case ClassroomProgressStage.resultsReady:
        unawaited(_showResults());
        return;
      case ClassroomProgressStage.unitCompleted:
        if (_learnerState.hasPendingLocalProgress) {
          unawaited(_completeUnitThenReveal());
          return;
        }
        _outcome = ClassSessionOutcome.choice;
        notifyListeners();
        return;
    }
  }

  String _interpolate(String template, {int? explicitPoints}) {
    final unit = _currentUnit;
    final hour = DateTime.now().hour;
    final partOfDay = hour < 12
        ? 'morning'
        : (hour < 17 ? 'afternoon' : 'evening');
    return template
        .replaceAll('{{name}}', studentName)
        .replaceAll('{{part_of_day}}', partOfDay)
        .replaceAll('{{unit_name}}', unit.name)
        .replaceAll('{{course_display}}', courseDisplay)
        .replaceAll(
          '{{video_description}}',
          _currentVideo?.description ?? unit.description,
        )
        .replaceAll(
          '{{video_points}}',
          '${explicitPoints ?? _currentVideo?.points ?? 0}',
        )
        .replaceAll('{{submission_points}}', '${explicitPoints ?? unit.xp}')
        .replaceAll('{{quiz_question_count}}', '${_quizQuestions.length}');
  }

  void _runStep(String stepId) {
    final step = _flow.step(stepId);
    if (step == null) {
      _completeUnitThenReveal();
      return;
    }

    switch (stepId) {
      case 'AF-004':
        _showVideoStartCheckpoint();
        return;
      case 'AF-007':
        _emitAssignmentStep(step);
        return;
      case 'AF-008':
        return;
      case 'AF-QUIZ-QUESTION':
        _emitQuizQuestionStep(step);
        return;
      case 'AF-011':
        _emitQuizSummaryStep(step);
        return;
    }

    if (step.isStatic) {
      _emitStaticStep(step);
    }
  }

  void _emitStaticStep(FlowStepModel step) {
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: step.stepId,
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.text,
        text: _interpolate(step.displayText ?? ''),
      ),
    );
    _awaitingInput = false;
    notifyListeners();

    final next = step.nextStep;
    if (next == null) {
      _scheduleAutoAdvance(step.autoAdvanceMs ?? 1100, _completeUnitThenReveal);
      return;
    }

    if (step.autoAdvanceMs != null) {
      _scheduleAutoAdvance(step.autoAdvanceMs!, () => _runStep(next));
    } else {
      _scheduleAutoAdvance(1100, () => _runStep(next));
    }
  }

  void _emitVideoStep(FlowStepModel step) {
    final video = _currentVideo;
    if (video == null) {
      _runStep(step.nextStep ?? 'AF-006');
      return;
    }
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: step.stepId,
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.video,
        data: {
          'videoId': video.id,
          'title': video.name,
          'description': video.description,
          'youtubeId': video.youtubeId,
          'points': video.points,
        },
      ),
    );
    _awaitingInput = true;
    notifyListeners();
  }

  Future<void> markVideoWatched() async {
    final msgIndex = _messages.lastIndexWhere(
      (m) => m.stepId == 'AF-004' && !m.isPending,
    );
    final video = _currentVideo;
    if (video == null || _videoWatchedThisUnit) return;

    _videoWatchedThisUnit = true;
    _awaitingInput = false;

    if (msgIndex != -1) {
      _messages[msgIndex] = _messages[msgIndex].copyWith(
        data: {..._messages[msgIndex].data, 'watched': true},
      );
    }

    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'AF-004',
        sender: ClassChatSender.user,
        contentType: ClassChatContentType.text,
        text: 'I watched it',
      ),
    );

    final saved = await _saveVideoProgress();
    if (_disposed) return;
    if (!saved) {
      _videoWatchedThisUnit = false;
      _showProgressSaveRetry(
        'We could not save that you watched the video. Please check your connection and retry.',
        action: 'save_video',
      );
      return;
    }

    _awaitingInput = false;
    _pushCheckpoint(
      stepId: 'VIDEO-CHECKPOINT',
      image: 'assets/class-screen/10Points.png',
      text:
          'Wow! That’s amazing 🤩  $studentName, you just earned $_accumulatedVideoPoints points🪩 for watching the video 🥳🥳🥳\n\nNow it’s time to do the activity submission 🌟',
      buttonLabel: 'Continue',
      action: 'video_reward',
    );
    notifyListeners();
  }

  void _emitAssignmentStep(FlowStepModel step) {
    final assignment = _currentAssignment;
    if (assignment == null || assignment.steps.isEmpty) {
      _submissionAcceptedThisUnit = true;
      _showQuizStartCheckpoint();
      return;
    }

    final assignStep = ArchetypeStepSelector.selectStep(
      assignment.steps,
      _currentArchetype,
    );
    if (assignStep == null) {
      _submissionAcceptedThisUnit = true;
      _showQuizStartCheckpoint();
      return;
    }
    _pendingAssignment = assignment;
    _pendingAssignmentStep = assignStep;

    final kind = SubmissionKindResolver.fromSubTypes(assignStep.subTypes);

    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: step.stepId,
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.submission,
        data: {
          'assignmentName': assignment.name,
          'assignmentDesc': assignment.description,
          'unguidedText': assignStep.unguidedText,
          'guidedText': assignStep.guidedText,
          'subTypes': assignStep.subTypes,
          'validCriteria': assignStep.validCriteria,
          'submissionKind': kind.name,
          'stepNumber': 1,
          'stepTotal': 1,
        },
      ),
    );
    _awaitingInput = true;
    notifyListeners();
  }

  String _finalSubmissionPraise(int points) => _interpolate(
    _flow.step('AF-008')?.displayText ??
        'I am SO proud of you {{name}} 🥹 That\'s the spirit! [+{{submission_points}} pts]',
    explicitPoints: points,
  );

  Future<void> submitAssignmentAnswer(SubmissionAnswer answer) async {
    final step = _pendingAssignmentStep;
    final assignment = _pendingAssignment;
    if (step == null || assignment == null || !_awaitingInput) return;

    _awaitingInput = false;

    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'AF-007',
        sender: ClassChatSender.user,
        contentType: ClassChatContentType.submissionAnswerEcho,
        text: answer.displaySummary,
        data: {
          'kind': answer.kind.name,
          'text': answer.text,
          'emoji': answer.emoji,
        },
      ),
    );

    // A photo or a video goes to the Worker. The feedback comes later (D6).
    // Other answers are checked against the flow criteria.
    final isMediaSubmission =
        answer.kind == SubmissionKind.image ||
        answer.kind == SubmissionKind.video ||
        answer.kind == SubmissionKind.imageVideo;
    if (isMediaSubmission) {
      await _sendWork(answer, assignment);
      return;
    }
    final passed = answer.matchesCriteria(step.validCriteria);
    if (passed) {
      _feedback = FeedbackStage.valid;
      _resultsDone = true;
    }
    _pushSubmissionReview(
      passed
          ? _finalSubmissionPraise(0)
          : "That's a good try — let's keep practicing this one.",
      passed: passed,
    );
    await _finishAssignmentStep(accepted: passed);
  }

  /// "I'll do it later" (R-66): go on to the quiz. Nothing is sent to the server.
  void postponeSubmission() {
    if (_pendingAssignmentStep == null || !_awaitingInput) return;
    _awaitingInput = false;
    _pendingAssignment = null;
    _pendingAssignmentStep = null;
    _submissionPostponed = true;
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'AF-007',
        sender: ClassChatSender.user,
        contentType: ClassChatContentType.submissionAnswerEcho,
        text: "I'll do it later 🕒",
      ),
    );
    switch (afterDoItLater(quizDone: _quizProgressSaved)) {
      case PostponeNext.quiz:
        _messages.clear();
        _showQuizStartCheckpoint();
      case PostponeNext.leave:
        _leaveForLater();
    }
  }

  /// Asks the Worker where the work stands. Valid feedback also marks the
  /// submission step as done on the phone, so the unit can close.
  Future<void> _refreshFeedback() async {
    final assignmentId = _currentAssignment?.assignmentId ?? '';
    if (assignmentId.isEmpty) return;
    final check = await _feedbackTracker.check(learnerId, assignmentId);
    if (_disposed || check == null) return;
    _feedback = check.stage;
    _latestSubmission = check.submission ?? _latestSubmission;
  }

  /// "I'm looking at your work, please wait" (R-68), or "taking longer than
  /// expected" after 24 hours. The student can leave, check again, or wait: the
  /// app checks by itself every 30 seconds while this is open.
  void _showWaitingForFeedback() {
    final stage = _feedback ?? FeedbackStage.waiting;
    if (stage == FeedbackStage.notValid ||
        stage == FeedbackStage.notValidNoRetry) {
      _feedbackPoll?.cancel();
      _showNotValid(stage);
      return;
    }
    _messages.clear();
    _pushCheckpoint(
      stepId: 'WAITING',
      image: null,
      text: switch (stage) {
        FeedbackStage.slow =>
          'Your feedback is taking longer than expected 🕒\nPlease check again a little later.',
        _ =>
          "I'm looking at your work 👀\nPlease wait. Come back later to see my feedback!"
              '\n\nPoints will be provided after feedback.',
      },
      buttonLabel: 'Back to Home',
      action: 'not_today',
      secondaryLabel: 'Check again',
      secondaryAction: 'check_feedback',
    );
    _startFeedbackPolling();
  }

  Timer? _feedbackPoll;

  void _startFeedbackPolling() {
    _feedbackPoll?.cancel();
    _feedbackPoll = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_recheckFeedback()),
    );
    _pendingTimers.add(_feedbackPoll!);
  }

  Future<void> _recheckFeedback() async {
    final before = _feedback;
    await _refreshFeedback();
    if (_disposed) return;
    if (_feedback?.opensNextUnit ?? false) {
      _feedbackPoll?.cancel();
      unawaited(_showResults());
    } else if (_feedback != before) {
      _showWaitingForFeedback();
    }
  }

  // ---- Results chat (R-68) ----

  /// The Worker's feedback text, or a plain default when it sent none.
  String _feedbackText({required String fallback}) {
    final text = _latestSubmission?.feedback?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  /// The feedback is valid: TAP Buddy shows the feedback, asks "Do you want to
  /// know your total points?", and the "Yes" tap shows the "YOU WON" card. The
  /// header points change only after that tap, so the reveal is not spoiled.
  Future<void> _showResults() async {
    if (_latestSubmission == null) await _refreshFeedback();
    if (_disposed) return;
    _messages.clear();
    _pushCheckpoint(
      stepId: 'RESULTS-FEEDBACK',
      image: null,
      text: _feedbackText(fallback: 'Great work! Your project is valid ✅'),
      buttonLabel: 'Continue',
      action: 'results_next',
    );
  }

  void _askForPoints() {
    _messages.clear();
    _pushCheckpoint(
      stepId: 'RESULTS-ASK',
      image: null,
      text: 'Do you want to know your total points collected so far?',
      buttonLabel: 'Yes Yes Yes 😍',
      action: 'results_points',
    );
  }

  /// The "Yes" tap: take the student's points from the Worker, and show what
  /// the valid work earned (the rise since the last answer). The points are the
  /// Worker's, not worked out here (R-75).
  Future<void> _revealPoints() async {
    final before = _learnerState.xp ?? 0;
    await _learnerStateRepository.refreshPoints(learnerId);
    final fresh = await _learnerStateRepository.readCached(learnerId);
    if (_disposed) return;
    if (fresh != null) _learnerState = fresh;
    final total = _learnerState.xp ?? before;
    final earned = total > before ? total - before : 0;
    _accumulatedSubmissionPoints += earned;

    _messages.clear();
    _pushCheckpoint(
      stepId: 'RESULTS-WON',
      image: 'assets/class-screen/you-won.png',
      text:
          'YOU WON! 🏆\n'
          '${earned > 0 ? 'Your valid work earned +$earned points 🪙\n' : ''}'
          'Your points: $total 🪙',
      buttonLabel: 'Continue',
      action: 'results_done',
    );
    notifyListeners();
  }

  /// The Results chat is over: mark the submission step as done on the phone,
  /// and close the unit (R-83).
  Future<void> _finishResults() async {
    _resultsDone = true;
    _learnerState = await _learnerStateRepository.applyValidFeedback(
      learnerId,
      unitIndex: unitIndex,
    );
    if (_disposed) return;
    unawaited(_completeUnitThenReveal());
  }

  // ---- Not valid: send again (R-76) ----

  /// The work is not valid. The student is told why (the Worker's feedback) and
  /// can send again, up to 2 attempts in all.
  void _showNotValid(FeedbackStage stage) {
    final reason = _feedbackText(fallback: 'Please send your work again.');
    final canSend = stage == FeedbackStage.notValid;
    _messages.clear();
    _pushCheckpoint(
      stepId: 'NOT-VALID',
      image: null,
      text: canSend
          ? '$reason\n\nPlease send corrected work 📸'
          : '$reason\n\nYou have used both tries, so you cannot send this '
                'work again.',
      buttonLabel: canSend ? 'Send again' : 'Back to Home',
      action: canSend ? 'send_again' : 'not_today',
      secondaryLabel: canSend ? 'Back to Home' : null,
      secondaryAction: canSend ? 'not_today' : null,
    );
  }

  /// "Send again": a new upload, with a new slot and a new key.
  void _sendAgain() {
    final assignmentId = _currentAssignment?.assignmentId ?? '';
    if (assignmentId.isEmpty) return;
    _workSubmitter.startNewAttempt(assignmentId);
    _resending = true;
    _messages.clear();
    _runStep('AF-006');
  }

  /// After the quiz: ask again if the student is ready to share the work.
  void _askToShareWork() {
    _messages.clear();
    _pushCheckpoint(
      stepId: 'SHARE-WORK',
      image: null,
      text: 'Are you ready to share your work? 📸',
      buttonLabel: "Yes, let's go",
      action: 'share_work',
      secondaryLabel: 'Not today',
      secondaryAction: 'not_today',
    );
  }

  /// "Not today": back to Home. The unit stays open and Home shows the
  /// "send project" card, because the video and the quiz are done and there is
  /// no submission yet.
  void _leaveForLater() {
    _outcome = ClassSessionOutcome.leave;
    _onProgressSaved?.call();
    notifyListeners();
  }

  void _pushSubmissionReview(String text, {required bool passed}) => _push(
    ClassChatMessage(
      id: _newId(),
      stepId: 'AF-008',
      sender: ClassChatSender.bot,
      contentType: ClassChatContentType.submissionReview,
      text: text,
      data: {'passed': passed, 'isFinalStep': passed},
    ),
  );

  /// Sends the photo or video to the Worker (slot, upload, `submit_artwork`).
  /// The points shown are the ones the Worker gives (+25 for attempt 1).
  Future<void> _sendWork(
    SubmissionAnswer answer,
    CourseAssignmentModel assignment,
  ) async {
    var points = 0;
    var alreadySent = false;
    try {
      final bytes = answer.bytes;
      if (bytes == null || assignment.assignmentId.isEmpty) {
        throw StateError('No file or no assignment id to send.');
      }
      final result = await _workSubmitter.submit(
        assignmentId: assignment.assignmentId,
        type: answer.kind == SubmissionKind.video
            ? SubmissionType.video
            : SubmissionType.image,
        bytes: bytes,
      );
      points = result.pointsAwarded;
      _pendingServerPoints = result.pointsTotal;
      await _feedbackTracker.markSent(learnerId, assignment.assignmentId);
      _feedback = FeedbackStage.waiting;
    } on ApiException catch (e) {
      if (e.code != 'CONFLICT') return _workNotSent(answer);
      // Both attempts are used (R-76). The work was sent before: go on.
      alreadySent = true;
      _feedback ??= FeedbackStage.waiting;
    } on FileTooBigException {
      _pushCheckpoint(
        stepId: 'SUBMISSION-RETRY',
        image: null,
        text:
            'That file is too big 😅\nPlease choose a smaller photo or a shorter video.',
        buttonLabel: 'Submit Again',
        action: 'submission_retry',
      );
      return;
    } catch (e) {
      debugPrint('Could not send the work: $e');
      return _workNotSent(answer);
    }
    _pendingWorkAnswer = null;
    if (_resending) {
      _resending = false;
      _showWaitingForFeedback();
      return;
    }
    _pushSubmissionReview(
      alreadySent
          ? 'You already sent this work. Let\'s go on! 💪'
          : _finalSubmissionPraise(points),
      passed: true,
    );
    await _finishAssignmentStep(accepted: true, points: points);
  }

  void _workNotSent(SubmissionAnswer answer) {
    _pendingWorkAnswer = answer;
    _showProgressSaveRetry(
      'We could not send your work. Please check your connection and retry.',
      action: 'send_work',
    );
  }

  void _retrySendWork() {
    final answer = _pendingWorkAnswer;
    final assignment = _pendingAssignment;
    if (answer == null || assignment == null) return;
    unawaited(_sendWork(answer, assignment));
  }

  Future<void> _finishAssignmentStep({
    required bool accepted,
    int points = 0,
  }) async {
    _pendingAssignment = null;
    _pendingAssignmentStep = null;
    if (accepted) {
      _submissionAcceptedThisUnit = true;
      _accumulatedSubmissionPoints += points;

      final saved = await _saveSubmissionProgress(points);
      if (_disposed) return;
      if (!saved) {
        _showProgressSaveRetry(
          'We could not save your completed submission. Please check your connection and retry.',
          action: 'save_submission',
        );
        return;
      }
      await _continueToQuizAfterSavedSubmission();
    } else {
      _pushCheckpoint(
        stepId: 'SUBMISSION-RETRY',
        image: null,
        text:
            'Pro tip: Take the photo in good light and show your full work 📸✨\n\nI’m excited to see what you made😅\nYou can do this! ⭐💪',
        buttonLabel: 'Submit Again',
        action: 'submission_retry',
      );
    }
  }

  void _emitQuizQuestionStep(FlowStepModel step) {
    if (_quizIndex >= _quizQuestions.length) {
      _runStep('AF-011');
      return;
    }
    final question = _quizQuestions[_quizIndex];
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: step.stepId,
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.quizQuestion,
        data: {
          'questionIndex': _quizIndex,
          'totalQuestions': _quizQuestions.length,
          'question': question.question,
          'options': question.options,
          'answerKey': question.answerKey,
        },
      ),
    );
    _awaitingInput = true;
    notifyListeners();
  }

  void submitQuizAnswer(String optionKey) {
    if (_quizIndex >= _quizQuestions.length || !_awaitingInput) return;
    final question = _quizQuestions[_quizIndex];
    _awaitingInput = false;

    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'AF-QUIZ-QUESTION',
        sender: ClassChatSender.user,
        contentType: ClassChatContentType.quizAnswerEcho,
        text: question.options[optionKey] ?? optionKey,
      ),
    );

    final isCorrect = optionKey == question.answerKey;
    // Right or wrong comes from the key on the phone, at once. The points come
    // later, from the Worker's answer to the whole quiz (R-41, R-91).
    _quizAnswers.add(quizAnswerFor(question, optionKey));
    if (isCorrect) _quizCorrectCount++;

    _quizToast = ClassQuizToast(
      id: ++_quizToastId,
      isCorrect: isCorrect,
      correctAnswer: isCorrect ? null : question.options[question.answerKey],
    );
    notifyListeners();

    _quizIndex++;
    final hasMore = _quizIndex < _quizQuestions.length;
    final autoAdvanceMs = isCorrect ? 1500 : 2500;
    _scheduleAutoAdvance(autoAdvanceMs, () {
      if (hasMore) {
        _runStep('AF-QUIZ-QUESTION');
      } else {
        _runStep('AF-011');
      }
    });
  }

  void _emitQuizSummaryStep(FlowStepModel step) {
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: step.stepId,
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.quizSummary,
        text: _interpolate(step.displayText ?? 'Quiz complete!'),
        data: {'correct': _quizCorrectCount, 'total': _quizQuestions.length},
      ),
    );
    _awaitingInput = false;
    unawaited(_saveQuizThenShowTotals());
  }

  void _showQuizStartCheckpoint({bool replaceThread = false}) {
    if (replaceThread) {
      _messages.clear();
    }
    _pushCheckpoint(
      stepId: 'QUIZ-START',
      image: 'assets/class-screen/lets_begin.png',
      text: "Let’s start the ${_currentUnit.name} quiz🚀🚀🚀",
      buttonLabel: 'Quiz',
      action: 'quiz',
    );
  }

  void _showVideoStartCheckpoint() {
    _pushCheckpoint(
      stepId: 'VIDEO-START',
      image: null,
      text:
          "Today we're going to play with ${_currentUnit.name}.\nWatch a short video, then make your own project.",
      buttonLabel: 'Watch',
      action: 'video',
    );
  }

  void _pushCheckpoint({
    required String stepId,
    required String? image,
    required String text,
    required String buttonLabel,
    required String action,
    String? secondaryLabel,
    String? secondaryAction,
  }) {
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: stepId,
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.checkpoint,
        text: text,
        data: {
          'image': ?image,
          'buttonLabel': buttonLabel,
          'action': action,
          'secondaryLabel': ?secondaryLabel,
          'secondaryAction': ?secondaryAction,
        },
      ),
    );
    _awaitingInput = false;
    notifyListeners();
  }

  void continueCheckpoint(String action) {
    switch (action) {
      case 'video':
        _messages.clear();
        final step = _flow.step('AF-004');
        if (step != null) _emitVideoStep(step);
        return;
      case 'submission':
        _messages.clear();
        _runStep('AF-006');
        return;
      case 'video_reward':
        _messages.clear();
        _runStep('AF-006');
        return;
      case 'share_work':
        _submissionPostponed = false;
        _messages.clear();
        _runStep('AF-006');
        return;
      case 'not_today':
        _leaveForLater();
        return;
      case 'check_feedback':
        unawaited(_recheckFeedback());
        return;
      case 'results_next':
        _askForPoints();
        return;
      case 'results_points':
        unawaited(_revealPoints());
        return;
      case 'results_done':
        unawaited(_finishResults());
        return;
      case 'send_again':
        _sendAgain();
        return;
      case 'submission_retry':
        _messages.clear();
        final step = _flow.step('AF-007');
        if (step != null) _emitAssignmentStep(step);
        return;
      case 'quiz':
        _messages.clear();
        _push(
          ClassChatMessage(
            id: _newId(),
            stepId: 'QUIZ-START-ECHO',
            sender: ClassChatSender.user,
            contentType: ClassChatContentType.text,
            text: 'Quiz',
          ),
        );
        _pushCheckpoint(
          stepId: 'QUIZ-BEGIN',
          image: 'assets/class-screen/lets_begin.png',
          text: '',
          buttonLabel: '',
          action: 'quiz_begin_art',
        );
        _scheduleAutoAdvance(1200, () => _runStep('AF-QUIZ-QUESTION'));
        return;
      case 'save_submission':
        _messages.removeWhere((m) => m.stepId == 'ERROR');
        unawaited(_retrySaveSubmissionThenShowQuiz());
        return;
      case 'send_work':
        _messages.removeWhere((m) => m.stepId == 'ERROR');
        _retrySendWork();
        return;
      case 'save_video':
        _messages.removeWhere((m) => m.stepId == 'ERROR');
        unawaited(_retrySaveVideoThenShowSubmission());
        return;
      case 'save_quiz':
        _messages.removeWhere((m) => m.stepId == 'ERROR');
        unawaited(_saveQuizThenShowTotals());
        return;
      case 'totals':
        _showFinalWinCard();
        return;
      case 'finish':
        unawaited(_completeUnitThenReveal());
        return;
    }
  }

  void _showFinalWinCard() {
    _pushCheckpoint(
      stepId: 'FINAL-WIN',
      image: 'assets/class-screen/you-won.png',
      text:
          'Activity Points    ${_accumulatedVideoPoints + _accumulatedSubmissionPoints} 🪙\nQuiz Points    $_accumulatedQuizPoints 🪙',
      buttonLabel: 'Continue',
      action: 'finish',
    );
  }

  Future<void> _saveQuizThenShowTotals() async {
    final saved = await _saveQuizProgress();
    if (_disposed) return;
    if (!saved) {
      _showProgressSaveRetry(
        'We could not save your quiz result. Please check your connection and retry.',
        action: 'save_quiz',
      );
      return;
    }
    _pushCheckpoint(
      stepId: 'QUIZ-COMPLETE-ART',
      image: 'assets/class-screen/won-champ.png',
      text: '',
      buttonLabel: '',
      action: 'quiz_complete_art',
    );
    _scheduleAutoAdvance(1200, () {
      _pushCheckpoint(
        stepId: 'QUIZ-TOTALS',
        image: null,
        text:
            'Great job Champ!\nDo you want to know your total points collected so far?',
        buttonLabel: 'Yes Yes Yes 😍',
        action: 'totals',
      );
    });
  }

  void _showProgressSaveRetry(String message, {required String action}) {
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'ERROR',
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.errorRetry,
        text: message,
        data: {'action': action},
      ),
    );
    notifyListeners();
  }

  Future<void> _retrySaveSubmissionThenShowQuiz() async {
    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'SAVING',
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.loading,
      ),
    );
    notifyListeners();

    final saved = await _saveSubmissionProgress(_accumulatedSubmissionPoints);
    if (_disposed) return;
    _messages.removeWhere((m) => m.stepId == 'SAVING');

    if (!saved) {
      _showProgressSaveRetry(
        'Still could not save your submission progress. Please check your connection and retry.',
        action: 'save_submission',
      );
      return;
    }

    await _continueToQuizAfterSavedSubmission();
    notifyListeners();
  }

  Future<void> _continueToQuizAfterSavedSubmission() async {
    if (!_submissionRewardShown) {
      _messages.clear();
      _push(
        ClassChatMessage(
          id: _newId(),
          stepId: 'SUBMISSION-REWARD',
          sender: ClassChatSender.bot,
          contentType: ClassChatContentType.submissionReward,
          data: {
            'studentName': studentName,
            'points': _accumulatedSubmissionPoints,
          },
        ),
      );
      _submissionRewardShown = true;
      notifyListeners();
    }
  }

  void continueAfterSubmissionReward() {
    if (!_submissionRewardShown) return;
    _messages.clear();
    // The quiz may be done already (the student postponed the work, R-66).
    if (_quizNotRequired || _quizProgressSaved) {
      unawaited(_completeUnitThenReveal());
      return;
    }
    _showQuizStartCheckpoint();
  }

  Future<void> _retrySaveVideoThenShowSubmission() async {
    final video = _currentVideo;
    if (video == null) return;

    final saved = await _saveVideoProgress();
    if (_disposed) return;
    if (!saved) {
      _showProgressSaveRetry(
        'We still could not save the video checkpoint. Please check your connection and retry.',
        action: 'save_video',
      );
      return;
    }

    _pushCheckpoint(
      stepId: 'VIDEO-CHECKPOINT',
      image: 'assets/class-screen/10Points.png',
      text:
          'Wow! That’s amazing 🤩  $studentName, you just earned $_accumulatedVideoPoints points🪩 for watching the video 🥳🥳🥳\n\nNow it’s time to do the activity submission 🌟',
      buttonLabel: 'Continue',
      action: 'video_reward',
    );
  }

  /// Records the video on the Worker, then on the phone. The points shown are
  /// the ones the Worker gave (R-41). On a failure it returns false and the
  /// student sees the Retry button. The retry sends the same key.
  Future<bool> _saveVideoProgress() async {
    if (_videoProgressSaved) return true;
    final video = _currentVideo;
    if (video == null) return true;
    _videoProgressSaved = true;
    var saved = false;
    try {
      final record = await _stepRecorder.recordVideo(
        unitId: _currentUnit.unitId,
        videoId: video.videoId,
      );
      _accumulatedVideoPoints = record.pointsAwarded;
      _learnerState = await _learnerStateRepository.applyLocalProgress(
        learnerId: learnerId,
        xp: record.pointsAwarded,
        videoIndex: unitIndex + 1,
      );
      final total = record.pointsTotal;
      if (total != null) {
        await _learnerStateRepository.applyServerPoints(learnerId, total);
      }
      saved = true;
    } catch (e) {
      debugPrint('Could not record the video: $e');
      saved = false;
    }
    _videoProgressSaved = saved;
    if (saved) _onProgressSaved?.call();
    return saved;
  }

  Future<bool> _saveSubmissionProgress(int points) async {
    if (_submissionProgressSaved) return true;
    final sentOnly = _feedback != FeedbackStage.valid;
    _submissionProgressSaved = true;
    var saved = false;
    try {
      _learnerState = await _learnerStateRepository.applyLocalProgress(
        learnerId: learnerId,
        xp: points,
        submissionIndex: unitIndex + 1,
        // The work is sent, but not done: only valid feedback finishes the
        // submission step (R-83).
        submissionSentOnly: sentOnly,
      );
      final total = _pendingServerPoints;
      if (total != null) {
        await _learnerStateRepository.applyServerPoints(learnerId, total);
      }
      saved = true;
    } catch (_) {
      saved = false;
    }
    _submissionProgressSaved = saved;
    if (saved) _onProgressSaved?.call();
    return saved;
  }

  /// Sends the quiz to the Worker once, then saves it on the phone. The points
  /// are the ones the Worker gave. On a failure it returns false and the
  /// student sees the Retry button. The retry sends the same key.
  Future<bool> _saveQuizProgress() async {
    if (_quizProgressSaved) return true;
    final quiz = _currentUnit.quiz;
    if (quiz == null) return true;
    _quizProgressSaved = true;
    var saved = false;
    try {
      final record = await _stepRecorder.recordQuiz(
        unitId: _currentUnit.unitId,
        quizId: quiz.quizId,
        answers: List.unmodifiable(_quizAnswers),
      );
      _accumulatedQuizPoints = record.pointsAwarded;
      _learnerState = await _learnerStateRepository.applyLocalProgress(
        learnerId: learnerId,
        xp: record.pointsAwarded,
        quizIndex: unitIndex + 1,
      );
      final total = record.pointsTotal;
      if (total != null) {
        await _learnerStateRepository.applyServerPoints(learnerId, total);
      }
      saved = true;
    } catch (e) {
      debugPrint('Could not record the quiz: $e');
      saved = false;
    }
    _quizProgressSaved = saved;
    if (saved) _onProgressSaved?.call();
    return saved;
  }

  void continueAfterReview() {
    if (!_awaitingContinue) return;
    _awaitingContinue = false;
    unawaited(_completeUnitThenReveal());
  }

  Future<ClassSessionOutcome> _completionOutcome() async {
    await _learnerStateRepository.showHomeCelebration(
      learnerId,
      points: _completedUnitPoints,
    );
    return ClassSessionOutcome.choice;
  }

  Future<void> _completeUnitThenReveal() async {
    if (_hasCompletedUnit) return;

    // The work is sent and the quiz is done: ask the Worker if the feedback is
    // valid yet (R-83).
    if (_videoWatchedThisUnit &&
        (_quizNotRequired || _quizProgressSaved) &&
        _submissionAcceptedThisUnit &&
        !_feedbackAllowsCompletion) {
      await _refreshFeedback();
      if (_disposed) return;
    }

    if (!_hasCompletedRequiredStages) {
      if (shouldAskToShareWork(
        postponed: _submissionPostponed,
        quizDone: _quizProgressSaved,
        workSent: _submissionAcceptedThisUnit,
      )) {
        _askToShareWork();
        return;
      }
      _resumeCurrentStage();
      notifyListeners();
      return;
    }

    _hasCompletedUnit = true;

    _push(
      ClassChatMessage(
        id: _newId(),
        stepId: 'SAVING',
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.loading,
      ),
    );
    notifyListeners();

    try {
      await _learnerStateRepository.markLocalProgressReady(learnerId);
      _completedUnitPoints = _learnerState.pendingProgressXp > 0
          ? _learnerState.pendingProgressXp
          : sessionTotalPoints;

      final submittedState = await _learnerStateRepository.completeUnitLocally(
        learnerId,
      );

      _learnerState = submittedState;

      _messages.clear();

      _outcome = await _completionOutcome();
      _onProgressSaved?.call();
      notifyListeners();
    } catch (_) {
      _hasCompletedUnit = false;
      _messages.removeWhere((m) => m.stepId == 'SAVING');
      _errorMessage = 'Something went wrong saving your progress.';
      _push(
        ClassChatMessage(
          id: _newId(),
          stepId: 'ERROR',
          sender: ClassChatSender.bot,
          contentType: ClassChatContentType.errorRetry,
          text: _errorMessage,
        ),
      );
      notifyListeners();
    }
  }

  bool _hasCompletedUnit = false;

  void retryAfterError() {
    final error = _messages.lastWhere(
      (m) => m.stepId == 'ERROR',
      orElse: () => ClassChatMessage(
        id: _newId(),
        stepId: 'ERROR',
        sender: ClassChatSender.bot,
        contentType: ClassChatContentType.errorRetry,
      ),
    );
    final action = error.data['action'] as String?;
    _messages.removeWhere((m) => m.stepId == 'ERROR');
    _errorMessage = null;
    switch (action) {
      case 'save_video':
        unawaited(_retrySaveVideoThenShowSubmission());
        return;
      case 'save_submission':
        unawaited(_retrySaveSubmissionThenShowQuiz());
        return;
      case 'send_work':
        _retrySendWork();
        return;
      case 'save_quiz':
        unawaited(_saveQuizThenShowTotals());
        return;
    }
    unawaited(_completeUnitThenReveal());
  }

  void _scheduleAutoAdvance(int ms, VoidCallback callback) {
    final timer = Timer(Duration(milliseconds: ms), () {
      if (_disposed) return;
      callback();
    });
    _pendingTimers.add(timer);
  }

  void _push(ClassChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  String _newId() {
    _msgCounter++;
    return 'msg_$_msgCounter';
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    super.dispose();
  }
}
