import 'app_routes.dart';

/// Where the app should start when the address has a magic-link code in its
/// path (`https://<app-host>/<code>`). WhatsApp template buttons allow a
/// variable only at the end of the URL, so the code cannot sit in the hash.
/// Returns null for every other address (the router then uses its own start).
// shortcut: any single path word without a dot is taken as a code, the Worker
// decides if it is real. Upgrade if the app ever gets other top-level paths.
String? initialLocationFor(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 1 || segments.single.contains('.')) return null;
  return AppRoutes.linkFor(segments.single);
}
