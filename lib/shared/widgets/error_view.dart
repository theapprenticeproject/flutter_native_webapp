import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorView extends StatefulWidget {
  final String title;
  final String? desktopTitle;
  final String message;
  final String? desktopMessage;
  final String buttonText;
  final String? desktopButtonText;
  final VoidCallback onRetry;
  final String imagePath;

  const ErrorView({
    super.key,
    required this.title,
    this.desktopTitle,
    required this.message,
    this.desktopMessage,
    required this.buttonText,
    this.desktopButtonText,
    required this.onRetry,
    this.imagePath = 'assets/error-screen-assets/sad_girl_error.png',
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  bool _isHovering = false;
  bool _isPressing = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final isDesktop = size.width > 600;

    final displayTitle = isDesktop
        ? (widget.desktopTitle ?? widget.title)
        : widget.title;
    final displayMessage = isDesktop
        ? (widget.desktopMessage ?? widget.message)
        : widget.message;
    final displayButtonText = isDesktop
        ? (widget.desktopButtonText ?? widget.buttonText)
        : widget.buttonText;

    final titleStyle = GoogleFonts.inter(
      fontSize: isDesktop ? 26 : 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1C1C21),
      height: 1.3,
      letterSpacing: -0.005 * (isDesktop ? 26 : 28),
    );

    final messageStyle = GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF6E6E7A),
      height: 1.5,
      letterSpacing: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isDesktop ? 280 : 260,
                  height: isDesktop ? 280 : 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8FB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B5BD6).withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.sentiment_very_dissatisfied_rounded,
                          size: 100,
                          color: Color(0xFF5B5BD6),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                Text(
                  displayTitle,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  displayMessage,
                  style: messageStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 300 : double.infinity,
                  ),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHovering = true),
                    onExit: (_) => setState(() => _isHovering = false),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isPressing = true),
                      onTapUp: (_) => setState(() => _isPressing = false),
                      onTapCancel: () => setState(() => _isPressing = false),
                      onTap: widget.onRetry,
                      child: AnimatedScale(
                        scale: _isPressing
                            ? 0.95
                            : _isHovering
                            ? 1.03
                            : 1.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B5BD6),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5B5BD6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayButtonText,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
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
