import 'package:flutter/services.dart' show rootBundle;

class RevealAssetResolver {
  RevealAssetResolver._();

  static const String _basePath = 'assets/reveal';
  static const String _fallbackAsset = '$_basePath/1.webp';

  static Future<String> resolve(int unitIndex) async {
    final candidate = '$_basePath/${unitIndex + 1}.webp';
    final exists = await _assetExists(candidate);
    return exists ? candidate : _fallbackAsset;
  }

  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
