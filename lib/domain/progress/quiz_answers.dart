import '../program_content/course_detail_model.dart';
import 'progress_repository.dart';

/// The answer to send for one question, from the option the student chose.
///
/// The bundled content keys the options "1", "2", "3". The Worker scores the
/// letters "a", "b", "c" (`selected_key`). Throws a [StateError] when the
/// question has no id or the key is not a number from 1 to 26, because such an
/// answer cannot be scored.
QuizAnswer quizAnswerFor(CourseQuizQuestionModel question, String optionKey) {
  final letter = CourseQuizQuestionModel.letterForOptionKey(optionKey);
  if (question.questionId.isEmpty || letter.isEmpty) {
    throw StateError(
      'This answer cannot be sent (question "${question.questionId}", '
      'key "$optionKey").',
    );
  }
  return QuizAnswer(questionId: question.questionId, selectedKey: letter);
}
