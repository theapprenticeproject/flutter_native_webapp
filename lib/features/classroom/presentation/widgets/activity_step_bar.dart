import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/l10n.dart';
import '../../models/activity_step.dart';

/// The step bar under the header: 1 Watch, 2 Make, 3 Quiz, 4 Results (design
/// M-C03, M-C05 and M-C21). A done step has a check, the current one is filled,
/// the others are grey.
class ActivityStepBar extends StatelessWidget {
  const ActivityStepBar({super.key, required this.state});

  final ActivityStepBarState state;

  static const _purple = Color(0xFF5B5BD6);
  static const _grey = Color(0xFFD0D0DA);
  static const _greyText = Color(0xFF8A8A98);

  String _label(BuildContext context, ActivityStep step) => switch (step) {
    ActivityStep.watch => context.l10n.classStepWatch,
    ActivityStep.make => context.l10n.classStepMake,
    ActivityStep.quiz => context.l10n.classStepQuiz,
    ActivityStep.results => context.l10n.classStepResults,
  };

  @override
  Widget build(BuildContext context) {
    final steps = ActivityStep.values;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7EF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _node(context, steps[i], i + 1),
            if (i < steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 13, left: 4, right: 4),
                  child: Container(
                    height: 2,
                    color: state.done.contains(steps[i]) ? _purple : _grey,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _node(BuildContext context, ActivityStep step, int number) {
    final done = state.done.contains(step);
    final current = state.current == step;
    final kind = done ? 'done' : (current ? 'current' : 'todo');
    return Column(
      key: ValueKey('step-${step.name}-$kind'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (done || current) ? _purple : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: (done || current) ? _purple : _grey,
              width: 1.5,
            ),
            boxShadow: current
                ? const [BoxShadow(color: Color(0xFFD9D9F7), spreadRadius: 3)]
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '$number',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: current ? Colors.white : _greyText,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          _label(context, step),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: (done || current) ? _purple : _greyText,
          ),
        ),
      ],
    );
  }
}
