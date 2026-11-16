import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/core/router/app_routes.dart';
import 'package:tapapp/domain/gallery/gallery_header_provider.dart';
import 'package:tapapp/domain/gallery/gallery_provider.dart';
import 'package:tapapp/domain/gallery/gallery_repository.dart';
import 'package:tapapp/features/gallery/presentation/gallery_screen.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _img(String id, String name) => {
  'submission_id': id,
  'display_name': name,
  'media_type': 'image',
  'url': 'https://r2.example/$id.webp',
};

Future<void> _pump(
  WidgetTester tester, {
  required FakeWorkerAdapter worker,
  bool shared = false,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  tester.view.physicalSize = const Size(420, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  final repo = GalleryRepository(
    HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    ),
  );
  final router = GoRouter(
    initialLocation: AppRoutes.gallery,
    routes: [
      GoRoute(
        path: AppRoutes.gallery,
        builder: (_, _) => const GalleryScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('HOME PAGE')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        galleryRepositoryProvider.overrideWithValue(repo),
        galleryHeaderProvider.overrideWith(
          (ref) async => GalleryHeader(
            activityTitle: 'Glowing LED Card',
            shared: shared,
            ownWorkUrl: null,
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads the grid with initials only', (tester) async {
    final worker = FakeWorkerAdapter(
      (_) => ok({
        'images': [_img('1', 'Durva Sibling'), _img('2', 'Manu Sibling')],
        'truncated': false,
      }),
    );
    await _pump(tester, worker: worker);

    expect(find.text('Glowing LED Card'), findsOneWidget);
    expect(find.text('DS'), findsOneWidget);
    expect(find.text('MS'), findsOneWidget);
    expect(find.textContaining('Durva'), findsNothing, reason: 'initials only');
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('Load more adds the next page', (tester) async {
    var call = 0;
    final worker = FakeWorkerAdapter((_) {
      call++;
      return ok(
        call == 1
            ? {
                'images': [_img('1', 'Asha New')],
                'cursor': 'c1',
                'truncated': true,
              }
            : {
                'images': [_img('2', 'Rahul Mid')],
                'truncated': false,
              },
      );
    });
    await _pump(tester, worker: worker);
    expect(find.text('AN'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('AN'), findsOneWidget);
    expect(find.text('RM'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
    expect(worker.seen.last.query['cursor'], 'c1');
  });

  testWidgets('a tap opens the viewer, which shows the position', (
    tester,
  ) async {
    final worker = FakeWorkerAdapter(
      (_) => ok({
        'images': [_img('1', 'Durva Sibling'), _img('2', 'Manu Sibling')],
        'truncated': false,
      }),
    );
    await _pump(tester, worker: worker);

    await tester.tap(find.text('MS'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2'), findsOneWidget);
    expect(find.text('Want to share your work too?'), findsOneWidget);
  });

  testWidgets('the Worker fails: a plain message and Try again', (
    tester,
  ) async {
    final worker = FakeWorkerAdapter(
      (_) => failure(502, 'UPSTREAM_ERROR', 'R2 list failed: 401'),
    );
    await _pump(tester, worker: worker);

    expect(find.textContaining("couldn't load the Gallery"), findsOneWidget);
    expect(
      find.textContaining('R2'),
      findsNothing,
      reason: 'no technical text',
    );
    expect(find.textContaining('401'), findsNothing);
  });

  testWidgets('Share your work goes to Home', (tester) async {
    final worker = FakeWorkerAdapter(
      (_) => ok({'images': [], 'truncated': false}),
    );
    await _pump(tester, worker: worker);

    expect(find.textContaining('No shared work yet'), findsOneWidget);
    await tester.tap(find.text('Share your work'));
    await tester.pumpAndSettle();
    expect(find.text('HOME PAGE'), findsOneWidget);
  });

  testWidgets('a student who shared sees the tag, not the button', (
    tester,
  ) async {
    final worker = FakeWorkerAdapter(
      (_) => ok({'images': [], 'truncated': false}),
    );
    await _pump(tester, worker: worker, shared: true);
    expect(find.text("You've shared"), findsOneWidget);
    expect(find.text('Share your work'), findsNothing);
  });
}
