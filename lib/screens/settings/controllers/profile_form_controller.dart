import 'package:flutter/material.dart';

import '../../../models/active_profile_model.dart';
import '../../../models/learner_state_model.dart';

class ProfileFormController {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final language = TextEditingController();
  final grade = TextEditingController();

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    language.dispose();
    grade.dispose();
  }

  void sync({
    required ActiveProfileModel? activeProfile,
    required LearnerStateModel? learnerState,
  }) {
    final fullName =
        (learnerState?.profile?.studentName ?? activeProfile?.studentName ?? '')
            .trim();
    final parts = fullName.isEmpty
        ? <String>[]
        : fullName.split(RegExp(r'\s+'));

    firstName.text = parts.isNotEmpty ? parts.first : '';
    lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    language.text = learnerState?.profile?.language ?? '';
    grade.text = activeProfile?.grade ?? '';
  }

  String get fullName => [
    firstName.text.trim(),
    lastName.text.trim(),
  ].where((value) => value.isNotEmpty).join(' ');

  String get languageValue => language.text.trim();

  String get gradeValue => grade.text.trim();

  Map<String, dynamic> toUpdates() {
    final updates = <String, dynamic>{};
    if (fullName.isNotEmpty) updates['student_name'] = fullName;
    if (languageValue.isNotEmpty) updates['language'] = languageValue;
    if (gradeValue.isNotEmpty) updates['grade'] = gradeValue;
    return updates;
  }
}
