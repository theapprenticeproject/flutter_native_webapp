import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/auth/auth_provider.dart';
import '../../../domain/auth/redeemed_student.dart';
import '../../../domain/profile/profile_provider.dart';
import '../../../domain/program_content/program_content_provider.dart';

class ProfileSelectScreen extends ConsumerStatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  ConsumerState<ProfileSelectScreen> createState() =>
      _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends ConsumerState<ProfileSelectScreen> {
  String? _selectingStudentId;
  String? _errorText;

  Future<void> _selectProfile(RedeemedStudent student) async {
    setState(() {
      _selectingStudentId = student.studentId;
      _errorText = null;
    });

    try {
      final repository = await ref.read(magicLinkRepositoryProvider.future);
      await repository.switchStudent(student.studentId);
      ref.invalidate(activeProfileProvider);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      debugPrint('Could not pick a student: $e');
      if (!mounted) return;
      setState(() {
        _selectingStudentId = null;
        _errorText = context.l10n.profileLoadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(linkRosterProvider);
    final courseNames = ref.watch(courseNameByIdProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The two logos, as in the design (M-F1-01).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logos/gov-logo.png',
                        height: 54,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      Image.asset(
                        'assets/logos/tap_logo.png',
                        height: 38,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8FB),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/onboarding/hello_welcome.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          size: 80,
                          color: Color(0xFF5B5BD6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.profileWelcome,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C21),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.profilePickPrompt,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E6E7A),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_errorText != null) ...[
                    _ErrorBanner(text: _errorText!),
                    const SizedBox(height: 16),
                  ],
                  profilesAsync.when(
                    data: (profiles) => _buildRows(profiles, courseNames),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) =>
                        _ErrorBanner(text: context.l10n.profilesLoadFailed),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRows(
    List<RedeemedStudent> profiles,
    Map<String, String> courseNames,
  ) {
    if (profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            context.l10n.profilesNone,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.subheadingColor,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final profile in profiles) ...[
          _StudentRow(
            profile: profile,
            subject: courseNames[profile.courseId],
            isLoading: _selectingStudentId == profile.studentId,
            onSelect: _selectingStudentId == null
                ? () => _selectProfile(profile)
                : null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// One student: initials, name, "Class N • subject" and a Select button.
class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.profile,
    required this.subject,
    required this.onSelect,
    required this.isLoading,
  });

  final RedeemedStudent profile;
  final String? subject;
  final VoidCallback? onSelect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (profile.grade.isNotEmpty) context.l10n.profileClass(profile.grade),
      if (subject != null && subject!.isNotEmpty) subject!,
    ].join(' • ');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDADAE3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8E8FB),
            child: Text(
              _initials(profile.name),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5B5BD6),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty
                      ? context.l10n.profileStudent
                      : profile.name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C21),
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E6E7A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  onPressed: onSelect,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1C1C21),
                    side: const BorderSide(color: Color(0xFFDADAE3)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    context.l10n.profileSelect,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD34B40),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD34B40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
