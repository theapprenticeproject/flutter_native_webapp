import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'profile_surface.dart';

class AboutTapView extends StatelessWidget {
  const AboutTapView({
    required this.data,
    required this.loading,
    required this.failed,
    required this.onRetry,
    super.key,
  });

  final Map<String, dynamic>? data;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return ProfileWhiteCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load this section.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.subheadingColor,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    final aboutData = data;
    if (loading || aboutData == null) {
      return const ProfileSkeleton();
    }

    final mission = aboutData['mission'] as Map<String, dynamic>? ?? const {};
    final problem = aboutData['problem'] as Map<String, dynamic>? ?? const {};
    final solution = aboutData['solution'] as Map<String, dynamic>? ?? const {};

    return ProfileWhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AboutPair(
            text: _AboutTextBlock(
              title: mission['title'] as String? ?? '',
              body: _asParagraphs(mission['body']),
            ),
            imagePath: mission['image'] as String? ?? '',
            imageFirst: false,
          ),
          const SizedBox(height: 34),
          _AboutPair(
            text: _AboutTextBlock(
              title: problem['title'] as String? ?? '',
              body: _asParagraphs(problem['body']),
              source: problem['source'] as String?,
            ),
            imagePath: problem['image'] as String? ?? '',
            imageFirst: true,
          ),
          const SizedBox(height: 34),
          _AboutPair(
            text: _AboutTextBlock(
              title: solution['title'] as String? ?? '',
              body: _asParagraphs(solution['body']),
            ),
            imagePath: solution['image'] as String? ?? '',
            imageFirst: false,
          ),
        ],
      ),
    );
  }

  static List<String> _asParagraphs(Object? value) {
    if (value is List) return value.whereType<String>().toList();
    if (value is String) return [value];
    return const [];
  }
}

class _AboutPair extends StatelessWidget {
  const _AboutPair({
    required this.text,
    required this.imagePath,
    required this.imageFirst,
  });

  final _AboutTextBlock text;
  final String imagePath;
  final bool imageFirst;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final image = _AboutImage(path: imagePath);

        if (narrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: imageFirst
                ? [image, const SizedBox(height: 18), text]
                : [text, const SizedBox(height: 18), image],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: imageFirst
              ? [
                  Expanded(child: image),
                  const SizedBox(width: 24),
                  Expanded(child: text),
                ]
              : [
                  Expanded(child: text),
                  const SizedBox(width: 24),
                  Expanded(child: image),
                ],
        );
      },
    );
  }
}

class _AboutTextBlock extends StatelessWidget {
  const _AboutTextBlock({required this.title, required this.body, this.source});

  final String title;
  final List<String> body;
  final String? source;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 14),
        for (final paragraph in body) ...[
          Text(
            paragraph,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppTheme.subheadingColor,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (source != null)
          Text(
            source!,
            style: GoogleFonts.inter(
              fontSize: 9,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppTheme.subheadingColor,
            ),
          ),
      ],
    );
  }
}

class _AboutImage extends StatelessWidget {
  const _AboutImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
