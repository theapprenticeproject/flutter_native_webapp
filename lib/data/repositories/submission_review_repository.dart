import '../../core/cache/cache_keys.dart';
import '../../core/cache/local_cache.dart';
import '../../models/submission_review_model.dart';
import '../remote/api_endpoints.dart';
import '../remote/http_client.dart';

class SubmissionReviewRepository {
  SubmissionReviewRepository(this._http, this._localCache);

  final HttpClient _http;
  final LocalCache _localCache;

  Future<Map<String, dynamic>> reviewSubmission({
    required String phone,
    required String learnerId,
    required String submissionText,
    String? question,
    String? expectedAnswer,
    String? rubric,
  }) async {
    final key = CacheKeys.submissionReview(
      learnerId,
      question ?? '',
      submissionText,
    );

    final cachedRaw = _localCache.getForeverRaw(key);
    if (cachedRaw != null) {
      return {
        'success': true,
        'learner_id': learnerId,
        'review': cachedRaw,
        'from_cache': true,
      };
    }

    final data = await _http.post(
      ApiEndpoints.submissionReview,
      body: {
        'phone': phone,
        'learner_id': learnerId,
        'submission_text': submissionText,
        'question': ?question,
        'expected_answer': ?expectedAnswer,
        'rubric': ?rubric,
      },
    );

    final review = data['review'];
    if (data['success'] == true && review is Map) {
      final model = SubmissionReviewModel.fromJson(
        Map<String, dynamic>.from(review),
      );
      await _localCache.setForeverRaw(key, model.toJson());
    }
    return data;
  }
}
