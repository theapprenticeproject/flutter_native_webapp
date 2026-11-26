import 'package:flutter/material.dart';
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

  /// The same screen with the video open. It gives the phone Back button a step
  /// to go back to: the Watch start screen.
  static const String classroomVideo = '/classroom?step=video';
  static const String me = '/me';
  static const String gallery = '/gallery';
  static const String profile = '/profile';
  static const String error = '/error';

  /// The magic link from WhatsApp carries a code: `/l/<code>`.
  static const String link = '/l/:code';
  static String linkFor(String code) => '/l/$code';

  /// A route's page. It needs its own key: without one, the Navigator treats
  /// the next page as the same page with new content, and a dialog or sheet
  /// opened above the old screen stays on top of the new one (the phone Back
  /// button left "Submission Help" over Home, and then a gray page).
  ///
  /// Every screen sits in a [SelectionArea]. Flutter draws text on a canvas, so
  /// the browser cannot select it. The area lets a student, a parent or a
  /// tester press and hold to select text and copy it, across several widgets.
  static Page<void> page(GoRouterState state, Widget child) =>
      NoTransitionPage<void>(
        key: state.pageKey,
        child: SelectionArea(child: child),
      );
}
