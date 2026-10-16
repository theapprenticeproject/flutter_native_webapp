import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class AssetLoadException implements Exception {
  AssetLoadException(this.path, this.cause);
  final String path;
  final Object cause;

  @override
  String toString() => 'AssetLoadException: failed to load "$path" ($cause)';
}

class AssetLoader {
  const AssetLoader();

  Future<Map<String, dynamic>> loadJson(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw AssetLoadException(path, 'expected a JSON object at top level');
    } on AssetLoadException {
      rethrow;
    } catch (e) {
      throw AssetLoadException(path, e);
    }
  }

  Future<dynamic> loadJsonAny(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      return jsonDecode(raw);
    } catch (e) {
      throw AssetLoadException(path, e);
    }
  }

  Future<List<dynamic>> loadJsonList(String path) async {
    final decoded = await loadJsonAny(path);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.values.isNotEmpty) {
      final firstList = decoded.values.firstWhere(
        (v) => v is List,
        orElse: () => null,
      );
      if (firstList is List) return firstList;
    }
    throw AssetLoadException(path, 'expected a JSON array at top level');
  }

  Future<String> loadRawString(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      throw AssetLoadException(path, e);
    }
  }
}
