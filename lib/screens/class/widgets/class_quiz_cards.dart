import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/class_chat_message_model.dart';
import '../../../providers/class_chat_controller.dart';
import 'class_card_shell.dart';

class ClassQuizQuestionCard extends StatefulWidget {
  const ClassQuizQuestionCard({
    super.key,
    required this.message,
    required this.controller,
  });

  final ClassChatMessage message;
  final ClassChatController controller;

  @override
  State<ClassQuizQuestionCard> createState() => _ClassQuizQuestionCardState();
}

class _ClassQuizQuestionCardState extends State<ClassQuizQuestionCard> {
  String? _selectedKey;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final questionIndex = widget.message.data['questionIndex'] as int? ?? 0;
    final totalQuestions = widget.message.data['totalQuestions'] as int? ?? 0;
    final question = widget.message.data['question'] as String? ?? '';
    final options =
        (widget.message.data['options'] as Map?)?.cast<String, String>() ??
        const {};
    final answerKey = widget.message.data['answerKey'] as String?;
    final optionEntries = options.entries.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${questionIndex + 1}. $question',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Question ${questionIndex + 1} of $totalQuestions',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.imagePlaceholder,
            ),
          ),
          const SizedBox(height: 14),
          ...optionEntries.map((option) {
            final selected = _selectedKey == option.key;
            final isCorrectOption =
                answerKey != null && option.key == answerKey;

            Color fillColor = Colors.white;
            Color borderColor = AppTheme.borderColor;
            Color textColor = AppTheme.textColor;

            if (_confirmed) {
              if (isCorrectOption) {
                fillColor = AppTheme.buttonColor;
                borderColor = AppTheme.buttonColor;
                textColor = Colors.white;
              } else if (selected) {
                fillColor = const Color(0xFFFBECEA);
                borderColor = const Color(0xFFD98F86);
                textColor = AppTheme.dangerText;
              }
            } else if (selected) {
              borderColor = AppTheme.buttonColor;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: (widget.controller.isAwaitingInput && !_confirmed)
                    ? () => setState(() => _selectedKey = option.key)
                    : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: borderColor,
                      width: selected || (_confirmed && isCorrectOption)
                          ? 1.8
                          : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (_confirmed && isCorrectOption)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      if (_confirmed && selected && !isCorrectOption)
                        const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: AppTheme.dangerText,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  (widget.controller.isAwaitingInput &&
                      _selectedKey != null &&
                      !_confirmed)
                  ? () {
                      setState(() => _confirmed = true);
                      widget.controller.submitQuizAnswer(_selectedKey!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.mutedLavender,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassQuizFeedbackCard extends StatelessWidget {
  const ClassQuizFeedbackCard({required this.message, super.key});

  final ClassChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isCorrect = message.data['isCorrect'] as bool? ?? false;
    final explanation = message.data['explanation'] as String?;
    final correctOptionText = message.data['correctOptionText'] as String?;
    final earnedPoints = message.data['earnedPoints'] as int?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFE7F7EE) : const Color(0xFFFFF1E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 18,
                color: isCorrect
                    ? AppTheme.streakColor
                    : const Color(0xFFE29A22),
              ),
              const SizedBox(width: 6),
              Text(
                isCorrect
                    ? (earnedPoints != null
                          ? 'Correct! +$earnedPoints points'
                          : 'Correct!')
                    : 'Not quite',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (!isCorrect && correctOptionText != null) ...[
            const SizedBox(height: 8),
            Text(
              'Correct answer: $correctOptionText',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4A55),
              ),
            ),
          ],
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF4A4A55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ClassQuizSummaryCard extends StatelessWidget {
  const ClassQuizSummaryCard({required this.message, super.key});

  final ClassChatMessage message;

  @override
  Widget build(BuildContext context) {
    final correct = message.data['correct'] as int? ?? 0;
    final total = message.data['total'] as int? ?? 0;

    return ClassCardShell(
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFF4AC38),
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${message.text ?? 'Quiz done!'}\nYou got $correct out of $total correct.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
