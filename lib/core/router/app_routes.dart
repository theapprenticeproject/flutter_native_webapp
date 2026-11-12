import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String profileSelect = '/profile-select';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String classroom = '/classroom';
  static const String passport = '/passport';
  static const String profile = '/profile';
  static const String error = '/error';

  static Page<void> page(Widget child) => NoTransitionPage<void>(child: child);
}
