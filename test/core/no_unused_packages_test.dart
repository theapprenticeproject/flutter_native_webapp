import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 / GP5: these packages were in pubspec.yaml but nothing used them. They
/// make the build slower and pull in more code to keep up to date. Add one back
/// only together with the code that uses it.
const _removed = [
  'cupertino_icons',
  'shared_preferences',
  'isar',
  'isar_flutter_libs',
  'isar_generator',
  'path_provider',
  'riverpod_annotation',
  'riverpod_generator',
  'build_runner',
  'url_launcher',
];

void main() {
  final pubspec = File('pubspec.yaml').readAsLinesSync();

  for (final name in _removed) {
    test('pubspec.yaml does not list $name', () {
      final listed = pubspec.any((l) => RegExp('^\\s+$name:').hasMatch(l));
      expect(listed, isFalse, reason: '$name is unused (GP5)');
    });
  }

  test('every package that pubspec.yaml lists is used by lib/ or test/', () {
    // Packages that need no import: the SDK, lints and the test tooling.
    const noImportNeeded = {'flutter', 'flutter_test', 'flutter_lints'};
    final sources = [
      ...Directory('lib').listSync(recursive: true),
      ...Directory('test').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.dart'));
    final text = sources.map((f) => f.readAsStringSync()).join('\n');

    final unused = <String>[];
    var inDependencies = false;
    for (final line in pubspec) {
      if (RegExp(r'^\S').hasMatch(line)) {
        inDependencies =
            line.startsWith('dependencies:') ||
            line.startsWith('dev_dependencies:');
        continue;
      }
      if (!inDependencies) continue;
      final m = RegExp(r'^  ([a-z_0-9]+):').firstMatch(line);
      if (m == null) continue;
      final name = m.group(1)!;
      if (noImportNeeded.contains(name)) continue;
      if (!text.contains('package:$name/')) unused.add(name);
    }
    expect(unused, isEmpty, reason: 'listed but never imported: $unused');
  });
}
