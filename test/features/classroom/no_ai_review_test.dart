import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 / D0: the prototype AI review of submissions is gone. Work will go
/// through `submit_artwork` and the existing feedback pipeline (R-27, R-89).
/// This test fails if any part of the AI review comes back into `lib/`.
///
/// `ClassChatContentType.submissionReview` (the pass or fail card) is not part
/// of the AI review, so it is not on this list.
final _aiReviewPieces = <String, RegExp>{
  'the review repository': RegExp(r'SubmissionReviewRepository'),
  'the review model': RegExp(r'SubmissionReviewModel'),
  'the review provider': RegExp(r'submissionReviewRepositoryProvider'),
  'the review file or import': RegExp(r'submission_review'),
  'the review endpoint': RegExp(r'/submission-review'),
  'the review call': RegExp(r'reviewSubmission\('),
  'the "needs AI review" rule': RegExp(r'requiresAiReview'),
  'the "reviewing" chat bubble': RegExp(r'submissionReviewing'),
  'the review cache key': RegExp(r'static String submissionReview\('),
  'any Groq mention': RegExp(r'groq', caseSensitive: false),
};

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final entry in _aiReviewPieces.entries) {
    test('lib/ has no ${entry.key}', () {
      final found = <String>[];
      for (final file in dartFiles) {
        if (entry.value.hasMatch(file.path) ||
            entry.value.hasMatch(file.readAsStringSync())) {
          found.add(file.path);
        }
      }
      expect(found, isEmpty, reason: 'Still found in: $found');
    });
  }
}
