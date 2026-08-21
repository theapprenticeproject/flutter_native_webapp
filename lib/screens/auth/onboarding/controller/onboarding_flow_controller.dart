import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/active_profile_model.dart';
import '../../../../models/learner_state_model.dart';
import '../../../../models/program_content/course_index_entry_model.dart';
import 'onboarding_component_registry.dart';
import 'onboarding_session_service.dart';
import '../models/onboarding_flow_step.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_flow_widgets.dart';

class OnboardingFlowController extends ChangeNotifier {
  OnboardingFlowController({
    required this.ref,
    required this.onGoHome,
    required this.onError,
  });

  final WidgetRef ref;
  final VoidCallback onGoHome;
  final ValueChanged<String> onError;
  final _componentRegistry = const OnboardingComponentRegistry();
  final messages = <OnboardingMessage>[];
  final scrollController = ScrollController();
  final inputController = TextEditingController();
  final inputFocusNode = FocusNode();

  Map<String, OnboardingFlowStep> _allSteps = {};
  ActiveProfileModel? _activeProfile;
  LearnerStateModel? _learnerState;
  OnboardingSessionService? _sessionService;
  List<CourseIndexEntryModel> _courseIndex = [];
  String _currentStepId = 'OF-001';
  final Map<String, dynamic> _pendingProfileUpdates = {};
  String? _selectedVerticalId;
  String? _selectedCourseId;
  bool _disposed = false;

  bool isLoading = true;
  String? loadError;
  bool isVoiceMuted = false;
  bool isBotTyping = false;
  bool showTextInput = false;
  String textInputHint = 'Type here...';
  Widget? currentInteraction;

  bool get inputEnabled => _currentStepId != 'OF-005-EDIT-PHONE';
  String get studentName =>
      _learnerState?.profile?.studentName ??
      _activeProfile?.studentName ??
      'there';

  Future<void> bootstrap() async {
    try {
      final data = await OnboardingSessionService.load(ref);
      _activeProfile = data.activeProfile;
      _learnerState = data.learnerState;
      _sessionService = data.sessionService;
      _courseIndex = data.courseIndex;
      _allSteps = data.steps;
      _selectedCourseId = data.learnerState.enrollment?.course;
      _selectedVerticalId = _verticalIdForCourse(_selectedCourseId);
      isLoading = false;
      loadError = null;
      notifyListeners();
      _executeStep();
    } on OnboardingSessionException catch (e) {
      _setLoadError(e.message);
    } catch (e) {
      debugPrint('Error bootstrapping onboarding: $e');
      _setLoadError('Something went wrong loading your profile.');
    }
  }

  void retry() {
    isLoading = true;
    loadError = null;
    notifyListeners();
    bootstrap();
  }

  void toggleVoice() {
    isVoiceMuted = !isVoiceMuted;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    scrollController.dispose();
    inputController.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  void _setLoadError(String message) {
    loadError = message;
    isLoading = false;
    notifyListeners();
  }

  void _executeStep() {
    final step = _allSteps[_currentStepId];
    if (step == null) return;

    isBotTyping = true;
    currentInteraction = null;
    showTextInput = false;
    notifyListeners();

    Timer(const Duration(milliseconds: 350), () {
      if (_disposed) return;
      isBotTyping = false;
      notifyListeners();
      _processStep(step);
      _scrollToBottom();
    });
  }

  void _processStep(OnboardingFlowStep step) {
    final activeProfile = _activeProfile;
    if (activeProfile == null) return;

    final resolved = _componentRegistry.resolveContent(
      step: step,
      currentStepId: _currentStepId,
      studentName: studentName,
      studentPhone: activeProfile.phone,
      verticalName: learningTrackLabel(_selectedVerticalId),
      courseName: _courseName(_selectedCourseId),
      activeProfile: activeProfile,
      learnerState: _learnerState,
    );
    _addBotMessage(resolved, step.audioId != null);

    if (step.inputMode == 'free_text') {
      showTextInput = true;
      textInputHint = _fieldHintFor(_currentStepId);
      notifyListeners();
      return;
    }

    final interaction = _componentRegistry.buildInteraction(
      step: step,
      currentStepId: _currentStepId,
      activeProfile: activeProfile,
      selectedVerticalId: _selectedVerticalId,
      selectedCourseId: _selectedCourseId,
      courseIndex: _courseIndex,
      coursesInSelectedVertical: _coursesInSelectedVertical,
      onTrackSelected: (id) {
        _selectedVerticalId = id;
        notifyListeners();
      },
      onTrackConfirmed: _confirmVerticalSelection,
      onChangeTrack: _changeTrack,
      onCourseSelected: (id) {
        _selectedCourseId = id;
        notifyListeners();
      },
      onCourseConfirmed: _confirmCourseSelection,
      onProfileVerify: _handleProfileVerifySelection,
      onEditField: _handleEditFieldSelection,
      onLanguageSelected: _handleLanguageSelection,
      onOptionSelected: (selectedValue, nextStepId) =>
          _handleOptionSelection(step, selectedValue, nextStepId),
      onFormSubmitted: _handleFormSubmit,
    );

    if (interaction != null) {
      currentInteraction = interaction;
      notifyListeners();
      return;
    }

    if (step.inputMode == 'static') {
      _continueTo(step.nextStepId);
      if (step.nextStepId == null && step.nextFlow == 'activity_flow') {
        _completeOnboarding().then((_) => onGoHome());
      }
    }
  }

  void submitText() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    if (_currentStepId == 'OF-005-EDIT-PHONE') {
      inputController.clear();
      return;
    }

    inputController.clear();
    _addUserMessage(text);

    final step = _allSteps[_currentStepId];
    if (step == null) return;

    if (_currentStepId == 'OF-005-EDIT-NAME') {
      _pendingProfileUpdates['student_name'] = text;
      _currentStepId = step.nextStepId ?? 'OF-005';
      _commitProfileUpdates();
      return;
    }
    _continueTo(step.nextStepId);
  }

  void _addBotMessage(OnboardingResolvedContent resolved, bool hasVoice) {
    if (resolved.text.isEmpty && resolved.content == null) return;

    final parts = resolved.text.isEmpty ? const [''] : resolved.text.split('|');
    for (var i = 0; i < parts.length; i++) {
      final text = parts[i].trim();
      if (text.isEmpty && resolved.content == null) continue;
      messages.add(
        OnboardingMessage(
          isBot: true,
          text: text,
          content: i == parts.length - 1 ? resolved.content : null,
          hasVoice: hasVoice,
        ),
      );
    }
    notifyListeners();
  }

  void _addUserMessage(String text) {
    messages.add(OnboardingMessage(isBot: false, text: text));
    notifyListeners();
    _scrollToBottom();
  }

  void _confirmVerticalSelection(String selectedId) {
    messages.add(
      OnboardingMessage(
        isBot: true,
        text: '',
        content: OnboardingTrackSnapshot(
          selectedId: selectedId,
          courseIndex: _courseIndex,
        ),
      ),
    );
    _selectedVerticalId = selectedId;
    currentInteraction = null;
    _addUserMessage(learningTrackLabel(selectedId));
    _currentStepId = 'OF-002-COURSE';
    _executeStep();
  }

  void _changeTrack() {
    _addUserMessage('Change track');
    _selectedVerticalId = null;
    _selectedCourseId = null;
    _currentStepId = 'OF-002';
    _executeStep();
  }

  void _confirmCourseSelection(String selectedCourseId) {
    final course = _courseById(selectedCourseId);
    if (course != null) {
      messages.add(
        OnboardingMessage(
          isBot: true,
          text: '',
          content: OnboardingCourseSnapshot(course: course),
        ),
      );
    }
    _selectedCourseId = selectedCourseId;
    currentInteraction = null;
    _addUserMessage(_courseName(selectedCourseId));
    _currentStepId = 'OF-003';
    _executeStep();
  }

  Future<void> _enrollInCourse(String courseId) async {
    final service = _sessionService;
    final activeProfile = _activeProfile;
    if (service == null || activeProfile == null) return;
    try {
      _learnerState = await service.enrollInCourse(
        ref: ref,
        activeProfile: activeProfile,
        courseId: courseId,
      );
      _selectedCourseId = courseId;
      notifyListeners();
    } catch (e) {
      debugPrint('Enroll failed: $e');
      onError('Could not save your course selection. Please try again.');
    }
  }

  Future<void> _commitProfileUpdates() async {
    final service = _sessionService;
    final activeProfile = _activeProfile;
    if (service == null ||
        activeProfile == null ||
        _pendingProfileUpdates.isEmpty) {
      _executeStep();
      return;
    }
    final updates = Map<String, dynamic>.from(_pendingProfileUpdates);
    _pendingProfileUpdates.clear();
    try {
      final result = await service.commitProfileUpdates(
        ref: ref,
        activeProfile: activeProfile,
        updates: updates,
      );
      _learnerState = result.learnerState;
      _activeProfile = result.activeProfile ?? activeProfile;
      notifyListeners();
    } catch (e) {
      debugPrint('Profile update failed: $e');
      onError('Could not save that change. Please try again.');
    }
    _executeStep();
  }

  Future<void> _completeOnboarding() async {
    final service = _sessionService;
    final activeProfile = _activeProfile;
    if (service == null || activeProfile == null) return;
    try {
      final result = await service.completeOnboarding(
        ref: ref,
        activeProfile: activeProfile,
        courseId: _selectedCourseId,
      );
      _activeProfile = result.activeProfile;
      _learnerState = result.learnerState;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark onboarding complete: $e');
    }
  }

  void _handleProfileVerifySelection(String selectedValue, String? nextStepId) {
    final step = _allSteps[_currentStepId];
    _addUserMessage(_labelFor(step?.raw['options'] ?? const [], selectedValue));
    if (selectedValue == 'confirm') {
      _enrollInCourse(_selectedCourseId ?? '').then((_) {
        _currentStepId = nextStepId ?? 'OF-006';
        _executeStep();
      });
      return;
    }
    _currentStepId = nextStepId ?? 'OF-005-EDIT';
    _executeStep();
  }

  void _handleLanguageSelection(String selectedValue, String? nextStepId) {
    final step = _allSteps[_currentStepId];
    _addUserMessage(_labelFor(step?.raw['options'] ?? const [], selectedValue));
    _pendingProfileUpdates['language'] = selectedValue;
    _currentStepId = nextStepId ?? 'OF-005';
    _commitProfileUpdates();
  }

  void _handleOptionSelection(
    OnboardingFlowStep step,
    String selectedValue,
    String? nextStepId,
  ) {
    final options = (step.raw['options'] as List<dynamic>?) ?? const [];
    final selectedOption = options.firstWhere(
      (opt) => opt['value'] == selectedValue,
      orElse: () => {'label': selectedValue},
    );
    _addUserMessage(selectedOption['label'] ?? selectedValue);

    if (selectedOption.containsKey('next_flow')) {
      _completeOnboarding().then((_) => onGoHome());
      return;
    }

    if (selectedValue == 'repick') {
      _selectedVerticalId = null;
      _selectedCourseId = null;
    }
    _continueTo(nextStepId ?? step.nextStepId);
  }

  void _handleEditFieldSelection(
    String value,
    String label,
    String? nextStepId,
  ) {
    _addUserMessage(label);
    _currentStepId =
        nextStepId ??
        switch (value) {
          'edit_name' => 'OF-005-EDIT-NAME',
          'edit_language' => 'OF-005-EDIT-LANG',
          _ => 'OF-005-EDIT-ACADEMIC',
        };
    _executeStep();
  }

  void _handleFormSubmit(Map<String, dynamic> updates, String nextStepId) {
    _addUserMessage('Updated details');
    _pendingProfileUpdates.addAll(updates);
    _currentStepId = nextStepId;
    _commitProfileUpdates();
  }

  void _continueTo(String? stepId) {
    if (stepId == null) return;
    _currentStepId = stepId;
    _executeStep();
  }

  String? _verticalIdForCourse(String? courseId) =>
      _courseById(courseId)?.vertical;

  List<CourseIndexEntryModel> get _coursesInSelectedVertical {
    if (_selectedVerticalId == null) return const [];
    return _courseIndex
        .where((c) => c.vertical == _selectedVerticalId)
        .toList();
  }

  CourseIndexEntryModel? _courseById(String? courseId) {
    if (courseId == null) return null;
    final match = _courseIndex.where((course) => course.id == courseId);
    return match.isEmpty ? null : match.first;
  }

  String _courseName(String? courseId) =>
      _courseById(courseId)?.name ?? courseId ?? '';

  String _fieldHintFor(String stepId) => switch (stepId) {
    'OF-005-EDIT-NAME' => 'Type the correct name...',
    'OF-005-EDIT-PHONE' => 'Phone number cannot be changed',
    _ => 'Type your answer...',
  };

  String _labelFor(List<dynamic> options, String value) {
    final match = options.firstWhere(
      (opt) => opt['value'] == value,
      orElse: () => {'label': value},
    );
    return match['label']?.toString() ?? value;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
