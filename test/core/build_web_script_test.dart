import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0: `scripts/build_web.sh` must pass a clean WORKER_URL to the build and
/// refuse anything else. DRY_RUN=1 prints the command and does not build.
Future<ProcessResult> _run({String? workerUrl, List<String> args = const []}) {
  return Process.run(
    'bash',
    ['scripts/build_web.sh', ...args],
    environment: {'DRY_RUN': '1', 'WORKER_URL': workerUrl ?? ''},
  );
}

void main() {
  test('without WORKER_URL the build gets no WORKER_URL define', () async {
    final r = await _run();
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('DRY RUN: flutter build web --release'));
    expect(r.stdout, isNot(contains('WORKER_URL')));
  });

  test('the build always loads CanvasKit from our own server', () async {
    final plain = await _run();
    final withUrl = await _run(
      workerUrl: 'https://tapapp-dev.example.workers.dev',
    );
    expect(plain.stdout, contains('--no-web-resources-cdn'));
    expect(withUrl.stdout, contains('--no-web-resources-cdn'));
  });

  test('a valid https URL is passed as a define', () async {
    final r = await _run(workerUrl: 'https://tapapp-dev.example.workers.dev');
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      r.stdout,
      contains(
        '--dart-define=WORKER_URL=https://tapapp-dev.example.workers.dev',
      ),
    );
  });

  test('a trailing slash is removed', () async {
    final r = await _run(workerUrl: 'https://tapapp-dev.example.workers.dev/');
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      r.stdout,
      contains('WORKER_URL=https://tapapp-dev.example.workers.dev '),
    );
  });

  test('http is allowed for localhost, with a port', () async {
    final r = await _run(workerUrl: 'http://localhost:8787');
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      r.stdout,
      contains('--dart-define=WORKER_URL=http://localhost:8787'),
    );
  });

  test('extra arguments still reach flutter build web', () async {
    final r = await _run(args: ['--base-href', '/app/']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('--base-href /app/'));
  });

  group('refuses a bad WORKER_URL', () {
    const bad = {
      'plain http to a real host': 'http://tapapp-dev.example.workers.dev',
      'a path': 'https://tapapp-dev.example.workers.dev/api',
      'a query': 'https://tapapp-dev.example.workers.dev?x=1',
      'no scheme': 'tapapp-dev.example.workers.dev',
      'a space and a command': 'https://a.com; echo hacked',
      'a user name in the URL': 'https://user@tapapp-dev.example.workers.dev',
    };
    for (final entry in bad.entries) {
      test(entry.key, () async {
        final r = await _run(workerUrl: entry.value);
        expect(r.exitCode, 2);
        expect(r.stderr, contains('WORKER_URL must be'));
        expect(r.stdout, isNot(contains('DRY RUN')));
      });
    }
  });
}
