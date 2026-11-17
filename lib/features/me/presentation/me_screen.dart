import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/auth/auth_provider.dart';
import '../../../domain/auth/redeemed_student.dart';
import '../../../domain/learner/learner_state_provider.dart';
import '../../../domain/learning_progress/home_dashboard_provider.dart';
import '../../../domain/me/me_provider.dart';
import '../../../domain/me/my_projects.dart';
import '../../../domain/profile/profile_provider.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_nav.dart';
import '../../../shared/widgets/load_error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/profile_switcher.dart';
import '../skill_tags.dart';
import 'me_view.dart';

/// The Me tab (R-7). It replaces the old Passport and Profile screens.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    RedeemedStudent student,
  ) async {
    try {
      final repository = await ref.read(magicLinkRepositoryProvider.future);
      await repository.switchStudent(student.studentId);
      ref.invalidate(activeProfileProvider);
      ref.invalidate(learnerStateDataProvider(student.studentId));
      ref.invalidate(learningDashboardProvider);
      ref.invalidate(meDataProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      // The new student's activity is on Home.
      context.go(AppRoutes.home);
    } catch (e) {
      debugPrint('Failed to switch profile: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not switch profile. Please try again.'),
        ),
      );
    }
  }

  void _showSwitchDialog(BuildContext context, WidgetRef ref, String? active) {
    showDialog<void>(
      context: context,
      barrierColor: AppTheme.subtleShadow.withValues(alpha: 0.48),
      builder: (_) => SwitchProfileDialog(
        activeLearnerId: active,
        onProfileSelected: (s) => _switchTo(context, ref, s),
      ),
    );
  }

  void _showProject(BuildContext context, MyProject project) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.unitName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                project.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.subheadingColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                project.detail,
                style: GoogleFonts.inter(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meDataProvider);
    final activeId = ref.watch(activeProfileProvider).value?.learnerId;

    return AppNav(
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: async.when(
          loading: () => const LoadingView(),
          error: (err, _) => LoadErrorView(
            error: err,
            onRetry: () => ref.invalidate(meDataProvider),
          ),
          data: (data) => SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppHeader(
                  title: 'Me',
                  studentName: data.studentName,
                  subtitle: 'Have a look at your progress',
                  points: data.points,
                  showStudentSummary: true,
                ),
                Expanded(
                  child: MeView(
                    studentName: data.studentName,
                    grade: data.grade,
                    school: data.school,
                    points: data.points,
                    level: data.level,
                    projects: data.projects,
                    tags: skillTags,
                    onSwitchProfile: () =>
                        _showSwitchDialog(context, ref, activeId),
                    onSettings: () => context.go(AppRoutes.profile),
                    onOpenProject: (p) => _showProject(context, p),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
