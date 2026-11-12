import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/onboarding_flow_step.dart';

class OnboardingFlowRepository {
  const OnboardingFlowRepository();

  static const _assetPath =
      'assets/flows/en/onboarding/student_onboarding.json';

  Future<Map<String, OnboardingFlowStep>> load() async {
    final source = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final steps = (decoded['steps'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(OnboardingFlowStep.fromJson);
    return {for (final step in steps) step.id: step};
  }
}
