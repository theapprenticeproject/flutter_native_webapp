import 'package:web/web.dart' as web;

/// Removes the link code from the path (`/<code>` becomes `/`). The code is
/// used once; it should not stay in the address bar or the history.
void clearPathFromAddressBar() {
  final loc = web.window.location;
  if (loc.pathname == '/') return;
  web.window.history.replaceState(null, '', '/${loc.search}${loc.hash}');
}
