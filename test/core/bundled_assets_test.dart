import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// M0 / AP7 / AP8: fonts are bundled, the splash image is small, and the app
/// never downloads a font while it runs.
///
/// google_fonts looks for a bundled file named `Family-Variant.ttf` in the
/// asset manifest before it tries the network.
const _fontFiles = {
  'Inter-Regular.ttf',
  'Inter-Medium.ttf',
  'Inter-SemiBold.ttf',
  'Inter-Bold.ttf',
  'Inter-ExtraBold.ttf',
  'Inter-Black.ttf',
  'Inter-Italic.ttf',
};

/// FontWeight value (as written in code) -> the bundled file that serves it.
const _weightToFile = {
  'FontWeight.w400': 'Inter-Regular.ttf',
  'FontWeight.normal': 'Inter-Regular.ttf',
  'FontWeight.w500': 'Inter-Medium.ttf',
  'FontWeight.w600': 'Inter-SemiBold.ttf',
  'FontWeight.w700': 'Inter-Bold.ttf',
  'FontWeight.bold': 'Inter-Bold.ttf',
  'FontWeight.w800': 'Inter-ExtraBold.ttf',
  'FontWeight.w900': 'Inter-Black.ttf',
};

Iterable<File> _dartFilesInLib() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  group('bundled fonts', () {
    test('every Inter file is in assets/google_fonts and is not empty', () {
      for (final name in _fontFiles) {
        final file = File('assets/google_fonts/$name');
        expect(file.existsSync(), isTrue, reason: '$name is missing');
        expect(
          file.lengthSync(),
          greaterThan(100 * 1024),
          reason: '$name looks too small to be a font',
        );
      }
    });

    test('the font licence is kept next to the fonts', () {
      expect(
        File('assets/google_fonts/Inter-LICENSE.txt').existsSync(),
        isTrue,
      );
    });

    test('pubspec.yaml lists the font folder as an asset', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/google_fonts/'));
    });

    test('code only uses weights and styles that we have a file for', () {
      final weightPattern = RegExp(r'FontWeight\.(\w+)');
      final unknown = <String>{};
      for (final file in _dartFilesInLib()) {
        for (final m in weightPattern.allMatches(file.readAsStringSync())) {
          final value = m.group(0)!;
          if (!_weightToFile.containsKey(value)) {
            unknown.add('$value in ${file.path}');
          }
        }
      }
      expect(
        unknown,
        isEmpty,
        reason: 'Add a bundled file for these weights, or stop using them',
      );
    });

    test('code only uses the Inter family from google_fonts', () {
      final pattern = RegExp(r'GoogleFonts\.(\w+)');
      final other = <String>{};
      for (final file in _dartFilesInLib()) {
        for (final m in pattern.allMatches(file.readAsStringSync())) {
          final member = m.group(1)!;
          // `config` is the settings object, `pendingFonts` is a helper.
          if (member != 'inter' && member != 'config') {
            other.add('GoogleFonts.$member in ${file.path}');
          }
        }
      }
      expect(
        other,
        isEmpty,
        reason: 'Only Inter is bundled. Other families would be downloaded',
      );
    });

    test('main.dart turns runtime font downloads off', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('GoogleFonts.config.allowRuntimeFetching = false'));
    });

    // google_fonts reads the app's asset list to find a bundled font. This
    // test reads the same list, from the real build of the assets.
    testWidgets('every Inter file is in the app asset list', (tester) async {
      final manifest = await tester.runAsync(
        () => AssetManifest.loadFromAssetBundle(rootBundle),
      );
      final assets = manifest!.listAssets();
      for (final name in _fontFiles) {
        expect(
          assets,
          contains('assets/google_fonts/$name'),
          reason: '$name is not in the asset list. Check pubspec.yaml',
        );
      }
    });
  });

  group('splash screen', () {
    test('the loader image is small', () {
      final dir = Directory('assets/splash-screen');
      for (final file in dir.listSync().whereType<File>()) {
        expect(
          file.lengthSync(),
          lessThan(300 * 1024),
          reason: '${file.path} is too big for the first screen',
        );
      }
    });

    test('the splash screen points at a file that exists', () {
      final source = File(
        'lib/features/splash/presentation/splash_screen.dart',
      ).readAsStringSync();
      final paths = RegExp(
        r"'(assets/splash-screen/[^']+)'",
      ).allMatches(source).map((m) => m.group(1)!);
      expect(paths, isNotEmpty);
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      }
    });
  });
}
