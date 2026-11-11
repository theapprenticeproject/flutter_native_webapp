import '../../core/network/http_client.dart';
import 'progress_models.dart';

export 'progress_models.dart';

/// One answer of a quiz. [selectedKey] is the letter the Worker scores
/// (`a`, `b`, ...). Answers go in question order.
class QuizAnswer {
  const QuizAnswer({required this.questionId, required this.selectedKey});

  final String questionId;
  final String selectedKey;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_key': selectedKey,
  };
}

/// The v1 Worker's progress routes. The Worker owns the points and the caps
/// (video 5 and quiz 3 events per unit, 2 submission attempts), so the app
/// shows what the Worker returns and does not count points itself (R-41).
///
/// Every write takes an `idempotencyKey` (see `newIdempotencyKey`). A write
/// that hits a cap throws an `ApiException` with the code `CONFLICT`.
class ProgressRepository {
  ProgressRepository(this._http);

  final HttpClient _http;

  Future<ProgressResult> submitVideo({
    required String unitId,
    required bool watched,
    required String idempotencyKey,
  }) async => ProgressResult.fromJson(
    await _http.postApi(
      '/progress/submit_video',
      body: {
        'unit_id': unitId,
        'watched': watched,
        'idempotency_key': idempotencyKey,
      },
    ),
  );

  Future<ProgressResult> submitQuiz({
    required String unitId,
    required List<QuizAnswer> answers,
    required String idempotencyKey,
  }) async {
    if (answers.isEmpty) {
      throw ArgumentError('A quiz needs at least one answer.');
    }
    return ProgressResult.fromJson(
      await _http.postApi(
        '/progress/submit_quiz',
        body: {
          'unit_id': unitId,
          'answers': [for (final a in answers) a.toJson()],
          'idempotency_key': idempotencyKey,
        },
      ),
    );
  }

  /// Asks if anything changed since [lastUpdated] (epoch seconds).
  Future<SyncResult> sync({required int lastUpdated}) async =>
      SyncResult.fromJson(
        await _http.postApi(
          '/progress/sync',
          body: {'last_updated': lastUpdated},
        ),
      );

  Future<LastSubmissionResult> lastSubmission({
    required int lastUpdated,
  }) async => LastSubmissionResult.fromJson(
    await _http.postApi(
      '/progress/last_submission',
      body: {'last_updated': lastUpdated},
    ),
  );

  Future<StudentProfile> getProfile() async =>
      StudentProfile.fromJson(await _http.postApi('/profile/get_profile'));

  Future<AppConfig> appConfig() async =>
      AppConfig.fromJson(await _http.getApi('/app/config'));
}
