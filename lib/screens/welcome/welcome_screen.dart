import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/router.dart';
import '../../providers/profile_provider.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  static const Duration _minimumHold = Duration(seconds: 5);

  Timer? _autoAdvanceTimer;
  bool _minimumHoldElapsed = false;
  bool _userTappedContinue = false;

  @override
  void initState() {
    super.initState();
    _autoAdvanceTimer = Timer(_minimumHold, () {
      if (!mounted) return;
      setState(() => _minimumHoldElapsed = true);

      if (_userTappedContinue) _goHome();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _goHome() {
    widget.onDone?.call();
    if (mounted) context.go(AppRoutes.home);
  }

  void _handleContinuePressed() {
    _userTappedContinue = true;

    if (_minimumHoldElapsed) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final activeProfileAsync = ref.watch(activeProfileProvider);
    final studentName = activeProfileAsync.value?.studentName ?? 'there';

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

                  Text(
                    'Welcome Back, $studentName!',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 32 : 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C21),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you ready for a New Year?',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E6E7A),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: isDesktop ? 320 : double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _minimumHoldElapsed
                          ? _handleContinuePressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5BD6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBDC3C7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
