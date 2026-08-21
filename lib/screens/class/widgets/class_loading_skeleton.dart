import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ClassLoadingSkeleton extends StatelessWidget {
  const ClassLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.appBackground,
      child: Column(
        children: [
          const _SkeletonHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showRail = constraints.maxWidth >= 760;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1060),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(24, 24, 24, 28),
                                child: _ChatSkeletonCard(),
                              ),
                            ),
                          ),
                        ),
                        if (showRail)
                          const SizedBox(
                            width: 230,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 24, 20, 24),
                              child: _RevealRailSkeleton(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const _InputSkeleton(),
        ],
      ),
    );
  }
}

class _SkeletonHeader extends StatelessWidget {
  const _SkeletonHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const _CircleSkeleton(size: 40),
          const SizedBox(width: 22),
          const Expanded(child: _BarSkeleton(height: 24)),
          const SizedBox(width: 48),
          const _BarSkeleton(width: 64, height: 28),
          const SizedBox(width: 14),
          const _BarSkeleton(width: 128, height: 28),
          const SizedBox(width: 14),
          const _BarSkeleton(width: 92, height: 28),
        ],
      ),
    );
  }
}

class _ChatSkeletonCard extends StatelessWidget {
  const _ChatSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      color: AppTheme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BarSkeleton(width: 320, height: 32),
          SizedBox(height: 12),
          _BarSkeleton(width: double.infinity, height: 168),
          SizedBox(height: 14),
          _BarSkeleton(width: double.infinity, height: 32),
          SizedBox(height: 12),
          _BarSkeleton(width: double.infinity, height: 32),
          SizedBox(height: 12),
          _BarSkeleton(width: double.infinity, height: 32),
          SizedBox(height: 12),
          _BarSkeleton(width: double.infinity, height: 32),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: _BarSkeleton(
              width: 300,
              height: 32,
              color: AppTheme.successBubble,
            ),
          ),
          SizedBox(height: 12),
          _BarSkeleton(width: double.infinity, height: 32),
        ],
      ),
    );
  }
}

class _RevealRailSkeleton extends StatelessWidget {
  const _RevealRailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: AppTheme.cardBackground,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BarSkeleton(width: 120, height: 22),
          SizedBox(height: 12),
          _BarSkeleton(width: double.infinity, height: 82),
          SizedBox(height: 14),
          _BarSkeleton(width: double.infinity, height: 138),
        ],
      ),
    );
  }
}

class _InputSkeleton extends StatelessWidget {
  const _InputSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Row(
            children: const [
              Expanded(child: _BarSkeleton(height: 34)),
              SizedBox(width: 10),
              _CircleSkeleton(size: 38, color: AppTheme.buttonColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarSkeleton extends StatelessWidget {
  const _BarSkeleton({
    this.width,
    required this.height,
    this.color = AppTheme.fieldBackground,
  });

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
    );
  }
}

class _CircleSkeleton extends StatelessWidget {
  const _CircleSkeleton({
    required this.size,
    this.color = AppTheme.fieldBackground,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
