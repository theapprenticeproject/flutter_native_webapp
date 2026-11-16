import '../../core/network/http_client.dart';
import 'gallery_models.dart';

/// Reads `GET /gallery`: valid work from other students, from the copies in R2
/// (R-88). The order is random and a small page comes at a time (R-85).
class GalleryRepository {
  GalleryRepository(this._http);

  final HttpClient _http;

  /// The Worker gives a token that saves its profile lookup. We send back the
  /// newest one we got, like a refreshed token.
  String? _scopeToken;

  /// shortcut: 8 works a page (R-85 says 5 to 10, "to be decided").
  static const pageSize = 8;

  Future<GalleryPage> page({String? cursor}) async {
    final data = await _http.getApi(
      '/gallery',
      query: {
        'limit': pageSize,
        'cursor': ?cursor,
        'scope_cache_token': ?_scopeToken,
      },
    );
    _scopeToken = (data['scope_cache_token'] as String?) ?? _scopeToken;

    final items = [
      for (final raw in (data['images'] as List? ?? const []))
        if (raw is Map) GalleryItem.fromJson(Map<String, dynamic>.from(raw)),
    ];
    return GalleryPage(
      items: items,
      cursor: data['truncated'] == true ? data['cursor'] as String? : null,
    );
  }
}
