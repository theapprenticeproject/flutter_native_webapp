import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5BD6)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? context.l10n.loadingDefault,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E6E7A),
            ),
          ),
        ],
      ),
    );
  }
}
