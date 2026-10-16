
class LearnerArchetype {
  LearnerArchetype._();

  static const String dormant = 'dormant';
  static const String fenceSitter = 'fence_sitter';
  static const String irregularSubmitter = 'irregular_submitter';
  static const String submitter = 'submitter';

  static const List<String> ladder = [
    dormant,
    fenceSitter,
    irregularSubmitter,
    submitter,
  ];

  static bool isValid(String value) => ladder.contains(value);

  static String normalize(String? value) =>
      isValid(value ?? '') ? value! : dormant;
}
