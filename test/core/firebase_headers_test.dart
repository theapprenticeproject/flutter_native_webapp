import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Firebase Hosting lets a browser reuse a file for an hour unless told
/// otherwise. A phone (the WhatsApp browser) then kept running the OLD app after
/// a deploy. The files that decide which version runs must be asked for again
/// every time (`no-cache` is "check with the server first", not "never store").
const _entryFiles = [
  '/index.html',
  '/flutter_bootstrap.js',
  '/flutter_service_worker.js',
  '/main.dart.js',
  '/version.json',
  '/manifest.json',
  // The course files and the picture files are under assets/. Their names carry
  // no version, so a changed file would be served stale for an hour otherwise.
  '/assets/**',
];

void main() {
  final config =
      jsonDecode(File('firebase.json').readAsStringSync())
          as Map<String, dynamic>;
  final headers = [
    for (final h in (config['hosting'] as Map)['headers'] as List? ?? const [])
      h as Map<String, dynamic>,
  ];

  String? cacheControl(String path) {
    for (final h in headers) {
      if (h['source'] != path) continue;
      for (final kv in h['headers'] as List) {
        if ((kv as Map)['key'] == 'Cache-Control') return kv['value'] as String;
      }
    }
    return null;
  }

  for (final path in _entryFiles) {
    test('$path is checked with the server on every load', () {
      expect(cacheControl(path), 'no-cache');
    });
  }

  test('the page rewrite is still there', () {
    final rewrites = (config['hosting'] as Map)['rewrites'] as List;
    expect((rewrites.single as Map)['destination'], '/index.html');
  });
}
