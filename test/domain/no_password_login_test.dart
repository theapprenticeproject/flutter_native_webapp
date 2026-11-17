import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R-32: v1 signs in with the WhatsApp link only. The phone and password login,
/// the forgot-password flow and the old token handling are gone and must not
/// come back.
final _forbidden = <String, RegExp>{
  'the old auth routes': RegExp(
    r'''['"]/auth/(check-phone|login|forgot-password|reset-password)''',
  ),
  'the old AuthRepository': RegExp(
    r'\bAuthRepository\b|authRepositoryProvider',
  ),
  'the old login screen': RegExp(r'AuthCheckScreen|AuthSessionModel'),
  'the old route name AppRoutes.login': RegExp(r'AppRoutes\.login\b'),
  'the old token handling': RegExp(
    r'saveRefreshedToken|readAdminCode|checkAdminCode|_persistTokenIfPresent',
  ),
  'a password field': RegExp(r'obscureText'),
};

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final entry in _forbidden.entries) {
    test('lib/ has no ${entry.key}', () {
      final found = <String>[];
      for (final f in files) {
        for (final line in f.readAsLinesSync()) {
          if (entry.value.hasMatch(line)) {
            found.add('${f.path}: ${line.trim()}');
          }
        }
      }
      expect(found, isEmpty);
    });
  }

  test('the old login screen file is gone', () {
    expect(
      File('lib/features/auth/presentation/auth_screen.dart').existsSync(),
      isFalse,
    );
    expect(File('lib/domain/auth/auth_repository.dart').existsSync(), isFalse);
  });
}
