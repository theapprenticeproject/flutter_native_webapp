class OnboardingFlowStep {
  const OnboardingFlowStep({
    required this.id,
    required this.inputMode,
    required this.displayText,
    this.component,
    this.audioId,
    this.nextStepId,
    this.nextFlow,
    this.options = const [],
    this.raw = const {},
  });

  factory OnboardingFlowStep.fromJson(Map<String, dynamic> json) {
    return OnboardingFlowStep(
      id: json['step_id'] as String,
      inputMode: json['input_mode'] as String? ?? 'static',
      displayText: json['display_text'] as String? ?? '',
      component: json['component'] as String?,
      audioId: json['audio_id'] as String?,
      nextStepId: json['next_step'] as String?,
      nextFlow: json['next_flow'] as String?,
      options: ((json['options'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(OnboardingOption.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }

  final String id;
  final String inputMode;
  final String displayText;
  final String? component;
  final String? audioId;
  final String? nextStepId;
  final String? nextFlow;
  final List<OnboardingOption> options;

  final Map<String, dynamic> raw;
}

class OnboardingOption {
  const OnboardingOption({
    required this.label,
    required this.value,
    this.nextStepId,
    this.nextFlow,
  });

  factory OnboardingOption.fromJson(Map<String, dynamic> json) =>
      OnboardingOption(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        nextStepId: json['next_step'] as String?,
        nextFlow: json['next_flow'] as String?,
      );

  final String label;
  final String value;
  final String? nextStepId;
  final String? nextFlow;
}
