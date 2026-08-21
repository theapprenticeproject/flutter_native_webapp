import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/screens/auth/onboarding/models/onboarding_flow_step.dart';

void main() {
  test('parses a component step and its options', () {
    final step = OnboardingFlowStep.fromJson({
      'step_id': 'OF-002',
      'input_mode': 'buttons_only',
      'component': 'VerticalSelectCard',
      'display_text': 'Choose a track',
      'audio_id': 'aud_002',
      'next_step': 'OF-003',
      'options': [
        {'label': 'Science', 'value': 'science', 'next_step': 'OF-003'},
      ],
    });

    expect(step.id, 'OF-002');
    expect(step.component, 'VerticalSelectCard');
    expect(step.audioId, 'aud_002');
    expect(step.options.single.value, 'science');
    expect(step.options.single.nextStepId, 'OF-003');
  });
}
