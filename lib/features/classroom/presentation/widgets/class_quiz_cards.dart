import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/class_chat_message_model.dart';
import 'class_card_shell.dart';
import '../../../../shared/widgets/app_primary_button.dart';

/// A quiz question (Figma M-C21): the question in a card, then each answer as its
/// own full-width row, then Confirm. [awaiting] says the student may answer now.
class ClassQuizQuestionCard extends StatefulWidget {
  const ClassQuizQuestionCard({
    super.key,
    required this.message,
    required this.awaiting,
    required this.onAnswer,
  });

  final ClassChatMessage message;
  final bool awaiting;
  final void Function(String optionKey) onAnswer;

  @override
  State<ClassQuizQuestionCard> createState() => _ClassQuizQuestionCardState();
}

class _ClassQuizQuestionCardState extends State<ClassQuizQuestionCard> {
  String? _selectedKey;
  bool _confirmed = false;

  static const _selected = Color(0xFFE8E8FB);
  static const _selectedBorder = Color(0xFF5B5BD6);
  static const _right = Color(0xFFE4F5EA);
  static const _rightBorder = Color(0xFF2FA866);
  static const _wrong = Color(0xFFFCEFD6);
  static const _wrongBorder = Color(0xFFE8A13B);
  static const _border = Color(0xFFDEDEE3);

  @override
  Widget build(BuildContext context) {
    final questionIndex = widget.message.data['questionIndex'] as int? ?? 0;
    final question = widget.message.data['question'] as String? ?? '';
    final options =
        (widget.message.data['options'] as Map?)?.cast<String, String>() ??
        const {};
    final answerKey = widget.message.data['answerKey'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('quiz-question'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Text(
            context.l10n.classQuizQuestion(questionIndex + 1, question),
            style: GoogleFonts.inter(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
        ),
        for (final option in options.entries) ...[
          const SizedBox(height: 16),
          _option(option.key, option.value, answerKey),
        ],
        const SizedBox(height: 16),
        AppPrimaryButton(
          label: context.l10n.classConfirm,
          tall: true,
          onPressed: (widget.awaiting && _selectedKey != null && !_confirmed)
              ? () {
                  setState(() => _confirmed = true);
                  widget.onAnswer(_selectedKey!);
                }
              : null,
        ),
      ],
    );
  }

  Widget _option(String key, String text, String? answerKey) {
    final selected = _selectedKey == key;
    var fill = Colors.white;
    var border = _border;
    var width = 1.0;
    var color = AppTheme.textColor;
    if (_confirmed) {
      if (key == answerKey) {
        fill = _right;
        border = _rightBorder;
        width = 1.5;
      } else if (selected) {
        fill = _wrong;
        border = _wrongBorder;
        width = 1.5;
      }
    } else if (selected) {
      fill = _selected;
      border = _selectedBorder;
      width = 1.5;
      color = const Color(0xFF3E3EA8);
    }
    return InkWell(
      key: ValueKey('quiz-option-$key'),
      onTap: (widget.awaiting && !_confirmed)
          ? () => setState(() => _selectedKey = key)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: width),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 16, height: 1.5, color: color),
        ),
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
              if (isCorrect)
                const Text('🎉', style: TextStyle(fontSize: 18))
              else
                const Icon(
                  Icons.info_rounded,
                  size: 18,
                  color: Color(0xFFE29A22),
                ),
              const SizedBox(width: 6),
              Text(
                isCorrect
                    ? (earnedPoints != null
                          ? context.l10n.classCorrectPoints(earnedPoints)
                          : context.l10n.classCorrect)
                    : context.l10n.classNotQuite,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (correctOptionText != null) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.classCorrectAnswerIs(correctOptionText),
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
              '${message.text ?? context.l10n.classQuizDone}\n${context.l10n.classQuizScore(correct, total)}',
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
