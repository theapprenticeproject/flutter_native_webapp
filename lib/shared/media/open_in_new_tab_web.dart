import 'package:web/web.dart' as web;

/// Opens a link in a new browser tab. The Gallery uses it to play a video,
/// because the app has no video player yet.
void openInNewTab(String url) {
  web.window.open(url, '_blank');
}
