import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/router/link_entry.dart';

void main() {
  // The WhatsApp template button URL is https://<app-host>/{{1}}, so the code
  // arrives as the path. The hash form /#/l/<code> keeps working.
  test('a code in the path opens the link screen', () {
    expect(
      initialLocationFor(Uri.parse('https://app.example/AbC123xy')),
      '/l/AbC123xy',
    );
    expect(
      initialLocationFor(Uri.parse('https://app.example/AbC123xy/')),
      '/l/AbC123xy',
    );
  });

  test('the hash form is left to the router', () {
    expect(
      initialLocationFor(Uri.parse('https://app.example/#/l/AbC123xy')),
      isNull,
    );
    expect(
      initialLocationFor(Uri.parse('http://localhost:8080/#/l/AbC123xy')),
      isNull,
    );
  });

  test('no code, files and other paths are ignored', () {
    for (final url in [
      'https://app.example/',
      'https://app.example',
      'https://app.example/index.html',
      'https://app.example/a/b',
      'https://app.example/#/gallery',
    ]) {
      expect(initialLocationFor(Uri.parse(url)), isNull, reason: url);
    }
  });
}
