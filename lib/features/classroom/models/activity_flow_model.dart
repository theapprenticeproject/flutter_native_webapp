class FlowStepModel {
  const FlowStepModel({
    required this.stepId,
    required this.type,
    this.displayText,
    this.voiceText,
    this.nextStep,
    this.autoAdvanceMs,
    this.component,
  });

  final String stepId;
  final String type;
  final String? displayText;
  final String? voiceText;
  final String? nextStep;
  final int? autoAdvanceMs;
  final String? component;

  bool get isStatic => type == 'static';
  bool get isDynamic => type == 'dynamic';

  factory FlowStepModel.fromJson(Map<String, dynamic> json) => FlowStepModel(
    stepId: json['step_id'] as String? ?? '',
    type: json['type'] as String? ?? 'static',
    displayText: json['display_text'] as String?,
    voiceText: json['voice_text'] as String?,
    nextStep: json['next_step'] as String?,
    autoAdvanceMs: (json['auto_advance_ms'] as num?)?.toInt(),
    component: json['component'] as String?,
  );
}

class ActivityFlowModel {
  const ActivityFlowModel({required this.steps});

  final Map<String, FlowStepModel> steps;

  FlowStepModel? step(String stepId) => steps[stepId];

  factory ActivityFlowModel.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    final steps = <String, FlowStepModel>{};
    if (rawSteps is List) {
      for (final raw in rawSteps.whereType<Map>()) {
        final model = FlowStepModel.fromJson(Map<String, dynamic>.from(raw));
        if (model.stepId.isNotEmpty) steps[model.stepId] = model;
      }
    }
    return ActivityFlowModel(steps: steps);
  }
}
