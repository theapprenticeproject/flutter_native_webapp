import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/localization/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final language = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'TAP Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(language),
      routerConfig: router,
    );
  }
}
