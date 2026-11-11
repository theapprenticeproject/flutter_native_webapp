import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../domain/auth/auth_provider.dart';
import '../errors/friendly_error.dart';
import 'error_view.dart';

/// Shows a failed load with a plain message and a button that fits the cause
/// (R-44). Retry runs [onRetry]. When a retry cannot help (the session ended),
/// the button signs the student out and opens the login screen.
class LoadErrorView extends ConsumerWidget {
  const LoadErrorView({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendly = describeError(error);
    return ErrorView(
      title: friendly.title,
      message: friendly.message,
      buttonText: friendly.buttonText,
      onRetry: friendly.action == ErrorAction.retry
          ? onRetry
          : () async {
              final auth = await ref.read(authRepositoryProvider.future);
              await auth.logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
    );
  }
}
