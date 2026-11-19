import '../program_content/course_detail_model.dart';
import 'progress_repository.dart';

/// The answer to send for one question, from the option the student chose.
///
/// The bundled content keys the options "1", "2", "3", and the Worker wants
/// that same number as text in `selected_key` ("each answer needs a question_id
/// and a numeric selected_key"). Throws a [StateError] when the question has no
/// id or the key is not a number from 1 up, because such an answer cannot be
/// scored.
QuizAnswer quizAnswerFor(CourseQuizQuestionModel question, String optionKey) {
  if (question.questionId.isEmpty || (int.tryParse(optionKey) ?? 0) < 1) {
    throw StateError(
      'This answer cannot be sent (question "${question.questionId}", '
      'key "$optionKey").',
    );
  }
  return QuizAnswer(questionId: question.questionId, selectedKey: optionKey);
}
