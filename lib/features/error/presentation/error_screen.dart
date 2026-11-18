import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/error_view.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: context.l10n.errorPageTitle,
      message: context.l10n.errorPageMessage,
      buttonText: context.l10n.errorPageButton,

      desktopTitle: context.l10n.errorPageDesktopTitle,
      desktopMessage: context.l10n.errorPageDesktopMessage,
      desktopButtonText: context.l10n.errorPageDesktopButton,

      onRetry: () {
        context.go(AppRoutes.splash);
      },
    );
  }
}
