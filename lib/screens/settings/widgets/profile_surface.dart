import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileWhiteCard extends StatelessWidget {
  const ProfileWhiteCard({
    required this.child,
    required this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileWhiteCard(
      padding: EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(width: 70, height: 18),
          SizedBox(height: 22),
          _SkeletonBar(width: double.infinity, height: 34),
          SizedBox(height: 14),
          _SkeletonBar(width: 220, height: 82),
          SizedBox(height: 14),
          _SkeletonBar(width: 160, height: 64),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.fieldBackground,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
