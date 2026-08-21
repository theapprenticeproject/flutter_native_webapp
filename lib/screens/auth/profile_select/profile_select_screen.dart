import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/active_profile_model.dart';
import '../../../models/profile_summary_model.dart';
import '../../../providers/profile_provider.dart';

class ProfileSelectScreen extends ConsumerStatefulWidget {
  const ProfileSelectScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<ProfileSelectScreen> createState() =>
      _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends ConsumerState<ProfileSelectScreen> {
  String? _selectingLearnerId;
  String? _errorText;

  Future<void> _selectProfile(ProfileSummaryModel profile) async {
    setState(() {
      _selectingLearnerId = profile.learnerId;
      _errorText = null;
    });

    try {
      final repository = await ref.read(profileRepositoryProvider.future);

      final learnerState = await repository.selectProfile(
        phone: widget.phone,
        learnerId: profile.learnerId,
      );
      final onboardingCompleted = repository.isOnboardingCompleted(
        profile.learnerId,
        fallback: profile.onboardingCompleted,
      );

      await setActiveProfile(
        ref,
        ActiveProfileModel(
          phone: widget.phone,
          learnerId: profile.learnerId,
          studentName: learnerState.profile?.studentName ?? profile.studentName,
          grade: profile.grade,
          division: profile.division,
          avatar: profile.avatar,
          onboardingCompleted: onboardingCompleted,
        ),
      );

      if (!mounted) return;
      context.go(onboardingCompleted ? AppRoutes.home : AppRoutes.onboarding);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectingLearnerId = null;
        _errorText = 'Could not load that profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(
      profilesPageDataProvider(ProfilesPageRequest(phone: widget.phone)),
    );

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 0 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 560 : 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Who\'s learning today?',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 26 : 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a student profile to continue.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.subheadingColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorText != null) ...[
                        _ErrorBanner(text: _errorText!),
                        const SizedBox(height: 16),
                      ],
                      profilesAsync.when(
                        data: (profiles) =>
                            _buildProfileGrid(profiles, isDesktop),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => _ErrorBanner(
                          text: 'Could not load profiles. Please try again.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileGrid(List<ProfileSummaryModel> profiles, bool isDesktop) {
    if (profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'No student profiles found for this account.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.subheadingColor,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final isSelecting = _selectingLearnerId == profile.learnerId;
        return _ProfileCard(
          profile: profile,
          isLoading: isSelecting,
          onTap: _selectingLearnerId == null
              ? () => _selectProfile(profile)
              : null,
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.isLoading,
  });

  final ProfileSummaryModel profile;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFE8E8FB),
                  child: Text(
                    _initials(profile.studentName),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5B5BD6),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                children: [
                  Text(
                    profile.studentName.isEmpty
                        ? 'Student'
                        : profile.studentName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (profile.grade != null) 'Grade ${profile.grade}',
                      if (profile.division != null) profile.division,
                    ].join(' · '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
