class SubmissionReviewModel {
  const SubmissionReviewModel({
    required this.score,
    this.verdict,
    required this.feedback,
    this.smsText,
    required this.strengths,
    required this.improvements,
  });

  final int score;
  final String? verdict;
  final String feedback;
  final String? smsText;
  final List<String> strengths;
  final List<String> improvements;

  bool get passed => verdict == 'pass';

  factory SubmissionReviewModel.fromJson(Map<String, dynamic> json) =>
      SubmissionReviewModel(
        score: (json['score'] as num?)?.toInt() ?? 0,
        verdict: json['verdict'] as String?,
        feedback: json['feedback'] as String? ?? '',
        smsText: json['sms_text'] as String?,
        strengths:
            (json['strengths'] as List?)?.whereType<String>().toList() ??
            const [],
        improvements:
            (json['improvements'] as List?)?.whereType<String>().toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
    'score': score,
    'verdict': verdict,
    'feedback': feedback,
    'sms_text': smsText,
    'strengths': strengths,
    'improvements': improvements,
  };
}
