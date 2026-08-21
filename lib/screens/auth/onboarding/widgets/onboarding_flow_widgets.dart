import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/active_profile_model.dart';
import '../../../../models/learner_state_model.dart';
import '../../../../models/program_content/course_index_entry_model.dart';
import '../models/onboarding_models.dart';

String onboardingCourseThumbnail(String courseId) =>
    'assets/data/courses/thumbnail/$courseId.webp';

class OnboardingTrackPicker extends StatefulWidget {
  const OnboardingTrackPicker({
    required this.initialSelectedId,
    required this.courseIndex,
    required this.onSelected,
    required this.onContinue,
    super.key,
  });

  final String? initialSelectedId;
  final List<CourseIndexEntryModel> courseIndex;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onContinue;

  @override
  State<OnboardingTrackPicker> createState() => _OnboardingTrackPickerState();
}

class _OnboardingTrackPickerState extends State<OnboardingTrackPicker> {
  late String? _selectedId = widget.initialSelectedId;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.94,
        ),
        itemCount: learningTrackOptions.length,
        itemBuilder: (context, index) {
          final track = learningTrackOptions[index];
          final isSelected = _selectedId == track.id;
          return _SelectableCard(
            selected: isSelected,
            onTap: () {
              setState(() => _selectedId = track.id);
              widget.onSelected(track.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.label,
                    style: _textStyle(12, FontWeight.w700, AppTheme.textColor),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    track.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      9,
                      FontWeight.w400,
                      AppTheme.subheadingColor,
                      1.3,
                    ),
                  ),
                  const Spacer(),
                  const _VideoPlaceholder(height: 62),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      _PrimaryButton(
        label: 'Continue',
        enabled: _selectedId != null,
        onPressed: () => widget.onContinue(_selectedId!),
      ),
    ],
  );
}

class OnboardingTrackSnapshot extends StatelessWidget {
  const OnboardingTrackSnapshot({
    required this.selectedId,
    required this.courseIndex,
    super.key,
  });

  final String selectedId;
  final List<CourseIndexEntryModel> courseIndex;

  @override
  Widget build(BuildContext context) {
    final track = learningTrackOptions.firstWhere((v) => v.id == selectedId);
    final availableCount = courseIndex
        .where((course) => course.vertical == track.id)
        .length;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: AppTheme.imageBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.buttonColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(track.emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              const _SelectedIcon(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            track.label,
            style: _textStyle(15, FontWeight.w700, AppTheme.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            track.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              11,
              FontWeight.w400,
              AppTheme.subheadingColor,
              1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$availableCount courses',
            style: _textStyle(10, FontWeight.w600, AppTheme.buttonColor),
          ),
        ],
      ),
    );
  }
}

class OnboardingCoursePicker extends StatefulWidget {
  const OnboardingCoursePicker({
    required this.initialSelectedId,
    required this.courses,
    required this.onSelected,
    required this.onChangeTrack,
    required this.onContinue,
    super.key,
  });

  final String? initialSelectedId;
  final List<CourseIndexEntryModel> courses;
  final ValueChanged<String> onSelected;
  final VoidCallback onChangeTrack;
  final ValueChanged<String> onContinue;

  @override
  State<OnboardingCoursePicker> createState() => _OnboardingCoursePickerState();
}

class _OnboardingCoursePickerState extends State<OnboardingCoursePicker> {
  late String? _selectedId = widget.initialSelectedId;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: widget.courses.length,
        itemBuilder: (context, index) {
          final course = widget.courses[index];
          final isSelected = _selectedId == course.id;
          return _SelectableCard(
            selected: isSelected,
            onTap: () {
              setState(() => _selectedId = course.id);
              widget.onSelected(course.id);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CourseImage(courseId: course.id),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          13,
                          FontWeight.w700,
                          AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.unitsCount} units',
                        style: _textStyle(
                          10,
                          FontWeight.w400,
                          AppTheme.subheadingColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _SecondaryButton(
              label: 'Change track',
              onPressed: widget.onChangeTrack,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PrimaryButton(
              label: 'Continue',
              enabled: _selectedId != null,
              onPressed: () => widget.onContinue(_selectedId!),
            ),
          ),
        ],
      ),
    ],
  );
}

class OnboardingCourseSnapshot extends StatelessWidget {
  const OnboardingCourseSnapshot({required this.course, super.key});

  final CourseIndexEntryModel course;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    clipBehavior: Clip.antiAlias,
    constraints: const BoxConstraints(maxWidth: 220),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.buttonColor, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            _CourseImage(courseId: course.id),
            const _SelectedBadge(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(13, FontWeight.w700, AppTheme.textColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${course.unitsCount} units',
                style: _textStyle(
                  10,
                  FontWeight.w400,
                  AppTheme.subheadingColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class OnboardingEditFieldPicker extends StatelessWidget {
  const OnboardingEditFieldPicker({
    required this.options,
    required this.onSelect,
    super.key,
  });

  final List<dynamic> options;
  final void Function(String value, String label, String? nextStepId) onSelect;

  @override
  Widget build(BuildContext context) {
    final editableOptions = options
        .where(
          (opt) =>
              opt['value'] != 'edit_phone' && opt['value'] != 'edit_academic',
        )
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppTheme.onboardingSurface,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: editableOptions.map((option) {
          final label = option['label']?.toString() ?? '';
          final value = option['value']?.toString() ?? '';
          return OutlinedButton(
            onPressed: () =>
                onSelect(value, label, option['next_step']?.toString()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.buttonColor,
              side: const BorderSide(color: AppTheme.buttonColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: _textStyle(14, FontWeight.w600, AppTheme.buttonColor),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class OnboardingJsonForm extends StatefulWidget {
  const OnboardingJsonForm({
    required this.step,
    required this.activeProfile,
    required this.onSubmit,
    super.key,
  });

  final Map<String, dynamic> step;
  final ActiveProfileModel activeProfile;
  final void Function(Map<String, dynamic> updates, String nextStepId) onSubmit;

  @override
  State<OnboardingJsonForm> createState() => _OnboardingJsonFormState();
}

class _OnboardingJsonFormState extends State<OnboardingJsonForm> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      final key = field['key']?.toString() ?? '';
      _controllers[key] = TextEditingController(text: _prefillFor(key));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get _fields =>
      ((widget.step['form_fields'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((field) => Map<String, dynamic>.from(field))
          .toList(growable: false);

  String _prefillFor(String key) {
    switch (key) {
      case 'class':
        return widget.activeProfile.grade ?? '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    color: AppTheme.onboardingSurface,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in _fields) ...[
          _FormTextField(
            label: field['label']?.toString() ?? field['key']?.toString() ?? '',
            controller: _controllers[field['key']]!,
          ),
          const SizedBox(height: 12),
        ],
        _PrimaryButton(label: 'Save', onPressed: _submit),
      ],
    ),
  );

  void _submit() {
    final updates = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;
      switch (entry.key) {
        case 'class':
          updates['grade'] = value;
          break;
        case 'school':
          updates['school'] = value;
          break;
        case 'subject':
          updates['subject'] = value;
          break;
        default:
          updates[entry.key] = value;
      }
    }
    widget.onSubmit(updates, widget.step['next_step']?.toString() ?? 'OF-005');
  }
}

class OnboardingCelebrationCard extends StatelessWidget {
  const OnboardingCelebrationCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.fieldBackground,
      borderRadius: BorderRadius.circular(24),
    ),
    padding: const EdgeInsets.all(12),
    constraints: const BoxConstraints(maxWidth: 280),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/onboarding/sussess_celebrate.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.celebration,
          size: 120,
          color: AppTheme.buttonColor,
        ),
      ),
    ),
  );
}

class OnboardingSkillPassportCard extends StatelessWidget {
  const OnboardingSkillPassportCard({
    required this.studentName,
    required this.points,
    super.key,
  });

  final String studentName;
  final int points;

  @override
  Widget build(BuildContext context) => Container(
    width: 318,
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
    decoration: BoxDecoration(
      color: AppTheme.fieldBackground,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/onboarding/Skill Passport.png',
              width: 220,
              height: 245,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.workspace_premium_rounded,
                size: 120,
                color: AppTheme.buttonColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Congratulations $studentName!!!🥳',
              textAlign: TextAlign.center,
              style: _textStyle(20, FontWeight.w800, AppTheme.textColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.pointColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: AppTheme.textColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '+$points pts',
                    style: _textStyle(15, FontWeight.w700, AppTheme.textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'You have won $points Joining Bonus Points',
              textAlign: TextAlign.center,
              style: _textStyle(16, FontWeight.w400, AppTheme.textColor),
            ),
            const SizedBox(height: 4),
            Text(
              '🪩🪩😍',
              textAlign: TextAlign.center,
              style: _textStyle(16, FontWeight.w400, AppTheme.textColor),
            ),
            const SizedBox(height: 10),
            Text(
              'You did a great job champion!',
              textAlign: TextAlign.center,
              style: _textStyle(16, FontWeight.w400, AppTheme.textColor),
            ),
          ],
        ),
        const Positioned(
          top: 6,
          right: 0,
          child: Icon(
            Icons.volume_up_rounded,
            size: 18,
            color: AppTheme.buttonColor,
          ),
        ),
      ],
    ),
  );
}

class OnboardingProfileVerifyCard extends StatelessWidget {
  const OnboardingProfileVerifyCard({
    required this.activeProfile,
    required this.learnerState,
    required this.courseName,
    required this.studentName,
    super.key,
  });

  final ActiveProfileModel activeProfile;
  final LearnerStateModel? learnerState;
  final String courseName;
  final String studentName;

  @override
  Widget build(BuildContext context) {
    final profile = learnerState?.profile;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.imageBgColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow('Name', studentName),
          const Divider(height: 16),
          _ProfileRow('Phone', activeProfile.phone, locked: true),
          const Divider(height: 16),
          _ProfileRow('Language', profile?.language ?? '-'),
          const Divider(height: 16),
          _ProfileRow('Course', courseName),
          const Divider(height: 16),
          _ProfileRow('School', profile?.schoolName ?? '-', locked: true),
          const Divider(height: 16),
          _ProfileRow('Grade', activeProfile.grade ?? '-'),
        ],
      ),
    );
  }
}

class OnboardingCompletionDialog extends StatelessWidget {
  const OnboardingCompletionDialog({
    required this.studentName,
    required this.courseName,
    required this.onStartLearning,
    super.key,
  });

  final String studentName;
  final String courseName;
  final VoidCallback onStartLearning;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Text(
      'Setup Complete!',
      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: AppTheme.buttonColor, size: 80),
        const SizedBox(height: 16),
        Text(
          '$studentName is now successfully enrolled in $courseName!',
          style: _textStyle(15, FontWeight.w400, AppTheme.subheadingColor),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      TextButton(
        onPressed: onStartLearning,
        child: Text(
          'Start Learning',
          style: _textStyle(16, FontWeight.bold, AppTheme.buttonColor),
        ),
      ),
    ],
  );
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? AppTheme.imageBgColor : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppTheme.buttonColor : AppTheme.imageBgColor,
          width: selected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.subtleShadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          if (selected) const _SelectedBadge(),
        ],
      ),
    ),
  );
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.5,
    child: Image.asset(
      onboardingCourseThumbnail(courseId),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppTheme.fieldBackground,
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: AppTheme.imagePlaceholder,
            size: 28,
          ),
        ),
      ),
    ),
  );
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppTheme.mediaPlaceholder,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Center(
      child: Icon(
        Icons.play_circle_fill_rounded,
        size: 24,
        color: AppTheme.buttonColor,
      ),
    ),
  );
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) =>
      const Positioned(top: 8, right: 8, child: _SelectedIcon());
}

class _SelectedIcon extends StatelessWidget {
  const _SelectedIcon();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.check_circle_rounded,
    color: AppTheme.streakColor,
    size: 20,
  );
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.imageBgColor),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _textStyle(13, FontWeight.w400, AppTheme.subheadingColor),
        border: InputBorder.none,
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.label, this.value, {this.locked = false});

  final String label;
  final String value;
  final bool locked;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: _textStyle(14, FontWeight.w500, AppTheme.subheadingColor),
      ),
      Row(
        children: [
          Text(
            value,
            style: _textStyle(14, FontWeight.w700, AppTheme.textColor),
          ),
          if (locked) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppTheme.subheadingColor,
            ),
          ],
        ],
      ),
    ],
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.buttonColor,
        foregroundColor: AppTheme.cardBackground,
        disabledBackgroundColor: AppTheme.disabledButton,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: _textStyle(13, FontWeight.w600, AppTheme.cardBackground),
      ),
    ),
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.buttonColor,
        side: const BorderSide(color: AppTheme.buttonColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: _textStyle(13, FontWeight.w600, AppTheme.buttonColor),
      ),
    ),
  );
}

TextStyle _textStyle(
  double fontSize,
  FontWeight weight,
  Color color, [
  double? height,
]) => GoogleFonts.inter(
  fontSize: fontSize,
  fontWeight: weight,
  color: color,
  height: height,
);
