import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/auth/auth_provider.dart';
import '../../../domain/auth/redeemed_student.dart';
import '../../../domain/learner/learner_state_provider.dart';
import '../../../domain/learning_progress/home_dashboard_provider.dart';
import '../../../domain/me/me_provider.dart';
import '../../../domain/me/my_projects.dart';
import '../../../domain/profile/profile_provider.dart';
import '../../../shared/widgets/app_nav.dart';
import '../../../shared/widgets/load_error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/profile_switcher.dart';
import 'me_view.dart';
import 'project_page.dart';
import 'project_sheet.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.switchProfileFailed)));
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

  /// The sheet of a project (design M-ME-01). "See my work" opens its page.
  void _showProject(BuildContext context, MyProject project) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => ProjectSheet(
        project: project,
        onClose: () => Navigator.of(sheet).pop(),
        onSeeWork: () {
          Navigator.of(sheet).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProjectPage(
                project: project,
                // Send again starts from the activity card on Home.
                onSendAgain: () => context.go(AppRoutes.home),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meDataProvider);
    final activeId = ref.watch(activeProfileProvider).valueOrNull?.learnerId;

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
                Expanded(
                  child: MeView(
                    studentName: data.studentName,
                    grade: data.grade,
                    school: data.school,
                    subject: data.subject,
                    points: data.points,
                    level: data.level,
                    projects: data.projects,
                    onSwitchProfile: () =>
                        _showSwitchDialog(context, ref, activeId),
                    onSettings: () => context.go(AppRoutes.profile),
                    onStartActivity: () => context.go(AppRoutes.home),
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
