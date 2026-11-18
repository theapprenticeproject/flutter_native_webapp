import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';

  /// Shown when there is no sign-in: "open the link TAP sent on WhatsApp".
  static const String openLink = '/open-link';
  static const String profileSelect = '/profile-select';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String classroom = '/classroom';
  static const String me = '/me';
  static const String gallery = '/gallery';
  static const String profile = '/profile';
  static const String error = '/error';

  /// The magic link from WhatsApp carries a code: `/l/<code>`.
  static const String link = '/l/:code';
  static String linkFor(String code) => '/l/$code';

  static Page<void> page(Widget child) => NoTransitionPage<void>(child: child);
}
