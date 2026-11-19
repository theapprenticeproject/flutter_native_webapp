import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/cache_keys.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/domain/program_content/program_content_cache.dart';

/// The course list, the course files and the chat flow files are bundled in the
/// app, but they were also saved in the browser forever. A browser that ran an
/// older build kept the old course list, so a new course was "not in the app"
/// ("This course is not ready"). Saved copies from another build are dropped.
void main() {
  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late LocalCache cache;

  final indexKey = ProgramContentCache.courseIndex('en');
  final detailKey = ProgramContentCache.courseDetail('C1', 'hi');
  final flowKey = CacheKeys.flow('en', 'activity', 'f.json');
  final manifestKey = CacheKeys.flowManifest('en');
  final learnerKey = CacheKeys.learnerState('S1');

  Future<void> seed() async {
    for (final k in [indexKey, detailKey, flowKey, manifestKey, learnerKey]) {
      await cache.setForeverRaw(k, {'v': 1});
    }
  }

  bool has(String k) => cache.getForeverRaw(k) != null;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tap_stale_content_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(values, indexes);
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  test(
    'the first start of a build drops the saved content, not the student\'s',
    () async {
      await seed();
      await cache.dropContentFromOtherBuilds('abc|2026-11-19T10:00Z');
      for (final k in [indexKey, detailKey, flowKey, manifestKey]) {
        expect(has(k), isFalse, reason: k);
      }
      expect(has(learnerKey), isTrue, reason: 'progress must stay');
    },
  );

  test('the same build keeps what it saved', () async {
    await cache.dropContentFromOtherBuilds('abc|T1');
    await seed();
    await cache.dropContentFromOtherBuilds('abc|T1');
    expect(has(indexKey), isTrue);
    expect(has(flowKey), isTrue);
  });

  test('a new build drops it again', () async {
    await cache.dropContentFromOtherBuilds('abc|T1');
    await seed();
    await cache.dropContentFromOtherBuilds('abc|T2');
    expect(has(indexKey), isFalse);
    expect(has(learnerKey), isTrue);
  });

  test(
    'a build with no stamp (not made by build_web.sh) always drops it',
    () async {
      await cache.dropContentFromOtherBuilds('unknown|unknown');
      await seed();
      await cache.dropContentFromOtherBuilds('unknown|unknown');
      expect(has(indexKey), isFalse);
    },
  );

  test('the dropped prefixes match the keys the repositories use', () {
    for (final key in [indexKey, detailKey, flowKey, manifestKey]) {
      expect(
        CacheKeys.bundledContentPrefixes.any(key.startsWith),
        isTrue,
        reason: key,
      );
    }
    expect(
      CacheKeys.bundledContentPrefixes.any(learnerKey.startsWith),
      isFalse,
    );
  });
}
