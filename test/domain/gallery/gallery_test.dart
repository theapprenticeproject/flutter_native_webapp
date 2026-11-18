import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/gallery/gallery_models.dart';
import 'package:tapapp/domain/gallery/gallery_notifier.dart';
import 'package:tapapp/domain/gallery/gallery_repository.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _img(String id, String name, {String type = 'image'}) => {
  'submission_id': id,
  'display_name': name,
  'media_type': type,
  'url': 'https://r2.example/$id.webp?sig=1',
};

Map<String, dynamic> _page(
  List<Map<String, dynamic>> images, {
  String? cursor,
  bool truncated = false,
  String token = 'scope-1',
}) => {
  'images': images,
  'cursor': cursor,
  'truncated': truncated,
  'scope_cache_token': token,
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  GalleryRepository repoFor(FakeWorkerAdapter adapter) => GalleryRepository(
    HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = adapter,
    ),
  );

  group('initials only (R-85)', () {
    test('two words: the first letter of each', () {
      expect(initialsOf('Durva Sibling'), 'DS');
    });

    test('one word: one letter', () {
      expect(initialsOf('Asha'), 'A');
    });

    test('more than two words: first and last', () {
      expect(initialsOf('Mary Anne Smith'), 'MS');
    });

    test('lower case and extra spaces are handled', () {
      expect(initialsOf('  priya   shah '), 'PS');
    });

    test('Hindi names work too', () {
      expect(initialsOf('आशा शर्मा'), 'आश');
    });

    test('empty gives a question mark', () {
      expect(initialsOf(''), '?');
      expect(initialsOf('   '), '?');
    });

    test('the item never exposes the full name for display', () {
      final item = GalleryItem.fromJson(_img('1', 'Durva Sibling'));
      expect(item.initials, 'DS');
    });
  });

  group('GalleryItem', () {
    test(
      'no submission_id: the id comes from the picture address, not empty',
      () {
        final json = {
          'display_name': 'Durva',
          'media_type': 'image',
          'url':
              'https://r2.example/tapapp/A/ST1/p6apu4sxdj-1.png?X-Amz-Signature=abc',
        };
        final a = GalleryItem.fromJson(json);
        final b = GalleryItem.fromJson({
          ...json,
          'url':
              'https://r2.example/tapapp/A/ST2/zzz-1.png?X-Amz-Signature=def',
        });
        expect(a.submissionId, isNotEmpty);
        expect(a.submissionId, isNot(b.submissionId));
        expect(
          a.submissionId,
          isNot(contains('X-Amz')),
          reason: 'the signature changes every time, the id must not',
        );
      },
    );

    test('reads an image and a video', () {
      expect(GalleryItem.fromJson(_img('1', 'A B')).isVideo, isFalse);
      expect(
        GalleryItem.fromJson(_img('2', 'A B', type: 'video')).isVideo,
        isTrue,
      );
    });

    test('a missing media type is an image', () {
      final json = _img('1', 'A B')..remove('media_type');
      expect(GalleryItem.fromJson(json).isVideo, isFalse);
    });
  });

  group('repository', () {
    test('asks for a small page and reads the items and the cursor', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok(
          _page(
            [_img('1', 'A B'), _img('2', 'C D')],
            cursor: 'c1',
            truncated: true,
          ),
        ),
      );
      final page = await repoFor(adapter).page();

      final call = adapter.seen.single;
      expect(call.method, 'GET');
      expect(call.path, '/gallery');
      expect(page.items.map((i) => i.submissionId), ['1', '2']);
      expect(page.cursor, 'c1');
      expect(page.hasMore, isTrue);
    });

    test(
      'the next page sends the cursor and the scope token from before',
      () async {
        var n = 0;
        final adapter = FakeWorkerAdapter((_) {
          n++;
          return ok(
            _page(
              [_img('$n', 'A B')],
              cursor: 'c$n',
              truncated: n < 2,
              token: 'tok-$n',
            ),
          );
        });
        final repo = repoFor(adapter);
        await repo.page();
        await repo.page(cursor: 'c1');
        await repo.page(cursor: 'c2');

        expect(adapter.seen[0].path, '/gallery');
        expect(adapter.seen[0].query.containsKey('cursor'), isFalse);
        expect(adapter.seen[0].query['limit'], GalleryRepository.pageSize);
        expect(adapter.seen[1].query['cursor'], 'c1');
        expect(adapter.seen[1].query['scope_cache_token'], 'tok-1');
        expect(
          adapter.seen[2].query['scope_cache_token'],
          'tok-2',
          reason: 'always the newest token',
        );
      },
    );

    test('nothing shared yet: an empty page, no more', () async {
      final adapter = FakeWorkerAdapter((_) => ok(_page([])));
      final page = await repoFor(adapter).page();
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('the Worker error is thrown with its code', () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(502, 'UPSTREAM_ERROR', 'R2 list failed'),
      );
      await expectLater(
        repoFor(adapter).page(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'UPSTREAM_ERROR'),
        ),
      );
    });
  });

  group('notifier', () {
    test('first load fills the grid', () async {
      final adapter = FakeWorkerAdapter((_) => ok(_page([_img('1', 'A B')])));
      final n = GalleryNotifier(repoFor(adapter));
      await n.load();
      expect(n.state.items, hasLength(1));
      expect(n.state.loading, isFalse);
      expect(n.state.failed, isFalse);
    });

    test(
      'load more adds to the end, and never shows the same work twice',
      () async {
        var call = 0;
        final adapter = FakeWorkerAdapter((_) {
          call++;
          return call == 1
              ? ok(
                  _page(
                    [_img('1', 'A B'), _img('2', 'C D')],
                    cursor: 'c1',
                    truncated: true,
                  ),
                )
              : ok(_page([_img('2', 'C D'), _img('3', 'E F')]));
        });
        final n = GalleryNotifier(repoFor(adapter));
        await n.load();
        expect(n.state.hasMore, isTrue);

        await n.loadMore();

        expect(n.state.items.map((i) => i.submissionId), ['1', '2', '3']);
        expect(n.state.hasMore, isFalse);
      },
    );

    test('a failed first load is a failure, and retrying works', () async {
      var fail = true;
      final adapter = FakeWorkerAdapter(
        (_) => fail
            ? failure(502, 'UPSTREAM_ERROR', 'x')
            : ok(_page([_img('1', 'A B')])),
      );
      final n = GalleryNotifier(repoFor(adapter));
      await n.load();
      expect(n.state.failed, isTrue);
      expect(n.state.items, isEmpty);

      fail = false;
      await n.load();
      expect(n.state.failed, isFalse);
      expect(n.state.items, hasLength(1));
    });

    test('a failed load more keeps what is already shown', () async {
      var call = 0;
      final adapter = FakeWorkerAdapter((_) {
        call++;
        return call == 1
            ? ok(_page([_img('1', 'A B')], cursor: 'c1', truncated: true))
            : failure(502, 'UPSTREAM_ERROR', 'x');
      });
      final n = GalleryNotifier(repoFor(adapter));
      await n.load();
      await n.loadMore();
      expect(n.state.items, hasLength(1));
      expect(n.state.moreFailed, isTrue);
    });

    test('load more does nothing while one is running', () async {
      var calls = 0;
      final adapter = FakeWorkerAdapter((_) {
        calls++;
        return ok(_page([_img('$calls', 'A B')], cursor: 'c', truncated: true));
      });
      final n = GalleryNotifier(repoFor(adapter));
      await n.load();
      await Future.wait([n.loadMore(), n.loadMore()]);
      expect(calls, 2, reason: 'the first load, and one load more');
    });
  });
}
