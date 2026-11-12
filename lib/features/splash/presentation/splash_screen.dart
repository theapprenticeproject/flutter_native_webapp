import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

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

              const Spacer(flex: 2),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to TAP!',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 34 : 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C21),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Brought to you by MCD Delhi',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E6E7A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  Container(
                    width: isDesktop ? 280 : 220,
                    height: isDesktop ? 280 : 220,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/splash-screen/tap-buddy-loader.gif',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.cloud_download,
                            size: 100,
                            color: Color(0xFF5B5BD6),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: 160,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE8E8FB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF5B5BD6),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Govt. of Delhi x TAP Initiative',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E6E7A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
