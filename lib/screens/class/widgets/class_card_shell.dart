import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ClassCardShell extends StatelessWidget {
  const ClassCardShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.classroomMessageSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.classroomMessageSurface),
      ),
      child: child,
    );
  }
}
