import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 / R-44: a failing call must show a plain message and a Retry button,
/// never technical text such as "Failed to load dashboard: AuthException".
///
/// Data screens show errors with the shared LoadErrorView. It takes its text
/// from describeError() in lib/shared/errors/friendly_error.dart.
const _dataScreens = [
  'lib/features/home/presentation/home_screen.dart',
  'lib/features/passport/presentation/passport_screen.dart',
  'lib/features/classroom/presentation/class_screen.dart',
];

void main() {
  test('Home, Passport and Class show errors with LoadErrorView', () {
    for (final path in _dataScreens) {
      final text = File(path).readAsStringSync();
      expect(
        text.contains('LoadErrorView('),
        isTrue,
        reason: '$path must show failures with LoadErrorView',
      );
    }
  });

  test('no screen puts a raw error value into visible text', () {
    // Matches a string that prints an error value, like 'Failed: $err'.
    // Log lines (debugPrint) and thrown exceptions are not shown to students.
    final rawInText = RegExp(
      r'''['"][^'"\n]*\$\{?(err|error|e|ex|exception)\b''',
    );
    final found = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final line in file.readAsLinesSync()) {
        if (line.contains('debugPrint') || line.contains('throw ')) continue;
        if (rawInText.hasMatch(line)) found.add('${file.path}: ${line.trim()}');
      }
    }
    expect(found, isEmpty, reason: 'raw error text shown to the student');
  });

  test('the old technical dashboard message is gone', () {
    for (final path in _dataScreens) {
      final text = File(path).readAsStringSync();
      expect(text.contains('Failed to load'), isFalse, reason: path);
    }
  });
}
