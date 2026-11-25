import '../../../shared/text/first_name.dart';
import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../domain/profile/profile_provider.dart';
import '../../../shared/widgets/app_primary_button.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  void _goHome() {
    widget.onDone?.call();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final activeProfileAsync = ref.watch(activeProfileProvider);
    final studentName = firstName(
      activeProfileAsync.valueOrNull?.studentName,
      fallback: context.l10n.welcomeThere,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/gov-logo.png',
                    height: isDesktop ? 64 : 54,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                  Image.asset(
                    'assets/logos/tap_logo.png',
                    height: isDesktop ? 48 : 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ],
              ),

              const Spacer(),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: isDesktop ? 300 : 240,
                      height: isDesktop ? 300 : 240,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8FB),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Image.asset(
                          'assets/onboarding/hello_welcome.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                size: 100,
                                color: Color(0xFF5B5BD6),
                              ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // One heading with both lines, as in the design (M-F1-04).
                  Text(
                    context.l10n.welcomeHeading(studentName),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C21),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: isDesktop ? 320 : double.infinity,
                    child: AppPrimaryButton(
                      label: context.l10n.buttonContinue,
                      onPressed: _goHome,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
