import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/error/error_screen.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/auth/profile_select/profile_select_screen.dart';
import '../../screens/auth/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/class/class_screen.dart';
import '../../screens/passport/passport_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/welcome/welcome_screen.dart';
import '../../providers/profile_provider.dart';

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

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _sub = _ref.listen<AsyncValue<dynamic>>(activeProfileProvider, (
      previous,
      next,
    ) {
      if (next.hasValue || next.hasError) {
        hasResolvedOnce = true;
      }
      notifyListeners();
    }, fireImmediately: false);

    final current = _ref.read(activeProfileProvider);
    if (current.hasValue || current.hasError) {
      hasResolvedOnce = true;
    }
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _sub;

  bool hasResolvedOnce = false;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

const Set<String> _authOnlyRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.onboarding,
  AppRoutes.profileSelect,
};

const Set<String> _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.onboarding,
  AppRoutes.profileSelect,
  AppRoutes.error,
};

final _welcomeGateProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final activeProfileAsync = ref.read(activeProfileProvider);
      final target = state.matchedLocation;

      if (activeProfileAsync.isLoading &&
          !activeProfileAsync.hasValue &&
          !refreshListenable.hasResolvedOnce) {
        return target == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (activeProfileAsync.isLoading && !activeProfileAsync.hasValue) {
        return null;
      }

      if (activeProfileAsync.hasError) {
        return _publicRoutes.contains(target) && target != AppRoutes.splash
            ? null
            : AppRoutes.login;
      }

      final profile = activeProfileAsync.value;
      final loggedIn = profile != null;
      final onboarded = loggedIn && (profile.onboardingCompleted == true);

      if (!loggedIn) {
        if (target != AppRoutes.splash && _publicRoutes.contains(target)) {
          return null;
        }
        return AppRoutes.login;
      }

      if (!onboarded) {
        if (target == AppRoutes.onboarding || target == AppRoutes.error) {
          return null;
        }
        return AppRoutes.onboarding;
      }

      final welcomeShown = ref.read(_welcomeGateProvider);
      if (!welcomeShown) {
        if (target == AppRoutes.welcome) return null;
        if (_authOnlyRoutes.contains(target) || target == AppRoutes.home) {
          return AppRoutes.welcome;
        }
        return null;
      }

      if (_authOnlyRoutes.contains(target) || target == AppRoutes.welcome) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => AppRoutes.page(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            AppRoutes.page(const AuthCheckScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            AppRoutes.page(const ConversationalOnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.profileSelect,
        pageBuilder: (context, state) => AppRoutes.page(
          ProfileSelectScreen(phone: state.uri.queryParameters['phone'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => AppRoutes.page(
          WelcomeBackScreen(
            onDone: () => ref.read(_welcomeGateProvider.notifier).state = true,
          ),
        ),
      ),

      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => AppRoutes.page(const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.classroom,
        pageBuilder: (context, state) => AppRoutes.page(const ClassScreen()),
      ),
      GoRoute(
        path: AppRoutes.passport,
        pageBuilder: (context, state) => AppRoutes.page(const PassportScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => AppRoutes.page(const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.error,
        pageBuilder: (context, state) => AppRoutes.page(const ErrorScreen()),
      ),
    ],
  );
});
