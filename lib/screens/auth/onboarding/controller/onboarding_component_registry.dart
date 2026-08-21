import 'package:flutter/widgets.dart';

import '../../../../models/active_profile_model.dart';
import '../../../../models/learner_state_model.dart';
import '../../../../models/program_content/course_index_entry_model.dart';
import '../models/onboarding_flow_step.dart';
import '../widgets/onboarding_chat_widgets.dart';
import '../widgets/onboarding_flow_widgets.dart';

class OnboardingResolvedContent {
  const OnboardingResolvedContent({required this.text, this.content});

  final String text;
  final Widget? content;
}

typedef OnboardingOptionHandler =
    void Function(String selectedValue, String? nextStepId);
typedef OnboardingEditFieldHandler =
    void Function(String value, String label, String? nextStepId);
typedef OnboardingFormHandler =
    void Function(Map<String, dynamic> updates, String nextStepId);

class OnboardingComponentRegistry {
  const OnboardingComponentRegistry();

  OnboardingResolvedContent resolveContent({
    required OnboardingFlowStep step,
    required String currentStepId,
    required String studentName,
    required String studentPhone,
    required String verticalName,
    required String courseName,
    required ActiveProfileModel activeProfile,
    required LearnerStateModel? learnerState,
  }) {
    var text = step.displayText
        .replaceAll('{{name}}', studentName)
        .replaceAll('{{phone}}', studentPhone)
        .replaceAll('{{vertical_display}}', verticalName)
        .replaceAll('{{course_display}}', courseName);

    Widget? content;
    if (text.contains('[confetti]') || currentStepId == 'OF-004') {
      text = text.replaceAll('[confetti]', '').trim();
      content = const OnboardingCelebrationCard();
    }

    if (step.component == 'ProfileVerifyCard') {
      content = OnboardingProfileVerifyCard(
        activeProfile: activeProfile,
        learnerState: learnerState,
        courseName: courseName,
        studentName: studentName,
      );
    }

    if (step.component == 'SkillPassportCard') {
      content = OnboardingSkillPassportCard(
        studentName: studentName,
        points: step.raw['points_awarded'] as int? ?? 500,
      );
    }

    return OnboardingResolvedContent(text: text, content: content);
  }

  Widget? buildInteraction({
    required OnboardingFlowStep step,
    required String currentStepId,
    required ActiveProfileModel activeProfile,
    required String? selectedVerticalId,
    required String? selectedCourseId,
    required List<CourseIndexEntryModel> courseIndex,
    required List<CourseIndexEntryModel> coursesInSelectedVertical,
    required ValueChanged<String> onTrackSelected,
    required ValueChanged<String> onTrackConfirmed,
    required VoidCallback onChangeTrack,
    required ValueChanged<String> onCourseSelected,
    required ValueChanged<String> onCourseConfirmed,
    required OnboardingOptionHandler onProfileVerify,
    required OnboardingEditFieldHandler onEditField,
    required OnboardingOptionHandler onLanguageSelected,
    required OnboardingOptionHandler onOptionSelected,
    required OnboardingFormHandler onFormSubmitted,
  }) {
    switch (step.component) {
      case 'VerticalSelectCard':
        return OnboardingTrackPicker(
          initialSelectedId: selectedVerticalId,
          courseIndex: courseIndex,
          onSelected: onTrackSelected,
          onContinue: onTrackConfirmed,
        );
      case 'CourseSelectCard':
        return OnboardingCoursePicker(
          initialSelectedId: selectedCourseId,
          courses: coursesInSelectedVertical,
          onSelected: onCourseSelected,
          onChangeTrack: onChangeTrack,
          onContinue: onCourseConfirmed,
        );
    }

    if (step.inputMode == 'form') {
      return OnboardingJsonForm(
        step: step.raw,
        activeProfile: activeProfile,
        onSubmit: onFormSubmitted,
      );
    }

    if (step.inputMode != 'buttons_only' && step.inputMode != 'radio') {
      return null;
    }

    final options = step.raw['options'] as List<dynamic>?;
    if (options == null) return null;

    switch (currentStepId) {
      case 'OF-005':
        return OnboardingActionButtons(
          options: options,
          onSelect: onProfileVerify,
        );
      case 'OF-005-EDIT':
        return OnboardingEditFieldPicker(
          options: options,
          onSelect: onEditField,
        );
      case 'OF-005-EDIT-LANG':
        return OnboardingActionButtons(
          options: options,
          onSelect: onLanguageSelected,
        );
      default:
        return OnboardingActionButtons(
          options: options,
          onSelect: onOptionSelected,
        );
    }
  }
}
