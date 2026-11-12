// Checks lib/ against the dependency rules in
// documentation/architecture-tenets.md.
//
// Usage (from the repo root):
//   dart run scripts/check_architecture.dart [path/to/lib]
//
// Exits 1 if any rule is broken. Only the target layers (core, domain, shared,
// features) are checked, so files not yet migrated are reported but never fail.
import 'dart:io';

const packageName = 'tapapp';
const targetLayers = {'core', 'domain', 'shared', 'features', 'app'};

/// Layers each layer may import. Anything else is a violation.
const allowedImports = {
  'core': {'core'},
  'domain': {'core', 'domain'},
  'shared': {'core', 'domain', 'shared'},
  'features': {'core', 'domain', 'shared', 'features'},
  // The composition root wires everything together; nothing imports it.
  'app': {'core', 'domain', 'shared', 'features', 'app'},
};

/// Tenet 2: core/ and domain/ are UI-free.
const uiFreeLayers = {'core', 'domain'};
final uiImport = RegExp(
  r'^package:flutter/(material|widgets|cupertino|rendering|painting)\.dart$',
);

/// Tenet 6: presentation code does no I/O itself.
final ioImport = RegExp(
  r'^package:(dio|hive_ce|hive_ce_flutter|flutter_secure_storage|http)/',
);

/// Documented exceptions: files under `prefix` may also do `allows`.
const exceptions = [
  // Route constants and theme are Flutter by nature (Page, ThemeData).
  (prefix: 'core/router/', allows: 'flutter-ui'),
  (prefix: 'core/theme/', allows: 'flutter-ui'),
];

final importPattern = RegExp(
  r"(?:import|export|part)\s+'([^']+)'|if\s*\([^)]*\)\s*'([^']+)'",
);

class Violation {
  Violation(this.file, this.rule, this.detail);
  final String file;
  final String rule;
  final String detail;
}

void main(List<String> args) {
  final libDir = Directory(args.isEmpty ? 'lib' : args.first);
  if (!libDir.existsSync()) {
    stderr.writeln('No such directory: ${libDir.path}');
    exit(2);
  }
  final root = libDir.absolute.path;

  final violations = <Violation>[];
  final legacy = <String, int>{};

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final rel = _relative(root, file.absolute.path);
    final layer = _layerOf(rel);
    if (layer == null) continue; // main.dart, app.dart
    if (!targetLayers.contains(layer)) {
      legacy[layer] = (legacy[layer] ?? 0) + 1;
      continue;
    }

    final source = file.readAsStringSync();
    for (final m in importPattern.allMatches(source)) {
      final uri = m.group(1) ?? m.group(2)!;
      _check(rel, layer, uri, violations);
    }
  }

  _report(violations, legacy);
  exit(violations.isEmpty ? 0 : 1);
}

void _check(String rel, String layer, String uri, List<Violation> out) {
  // Tenet 2: no widget toolkit in core/ or domain/.
  if (uiFreeLayers.contains(layer) &&
      uiImport.hasMatch(uri) &&
      !_hasException(rel, 'flutter-ui')) {
    out.add(Violation(rel, 'T2 no-ui-in-$layer', uri));
  }

  // Tenet 6: presentation does no I/O.
  if (layer == 'features' &&
      rel.contains('/presentation/') &&
      (ioImport.hasMatch(uri) || _isCoreIo(_resolve(rel, uri)))) {
    out.add(Violation(rel, 'T6 presentation-does-io', uri));
  }

  final target = _resolve(rel, uri);
  if (target == null) return;
  final targetLayer = _layerOf(target);
  if (targetLayer == null || !targetLayers.contains(targetLayer)) return;

  // Tenet 3: a feature never imports another feature.
  if (layer == 'features' && targetLayer == 'features') {
    if (_featureOf(rel) != _featureOf(target)) {
      if (!_hasException(rel, 'features')) {
        out.add(Violation(
          rel,
          'T3 feature-imports-feature',
          '${_featureOf(rel)} -> ${_featureOf(target)} ($uri)',
        ));
      }
    }
    return;
  }

  // Tenet 2: dependencies point one way.
  if (!allowedImports[layer]!.contains(targetLayer) &&
      !_hasException(rel, targetLayer)) {
    out.add(Violation(rel, 'T2 wrong-direction', '$layer -> $targetLayer ($uri)'));
  }
}

bool _isCoreIo(String? target) =>
    target != null &&
    (target.startsWith('core/cache/') ||
        target.startsWith('core/network/') ||
        target.startsWith('core/storage/'));

bool _hasException(String rel, String what) =>
    exceptions.any((e) => rel.startsWith(e.prefix) && e.allows == what);

/// Returns the lib-relative path an import points at, or null for non-project
/// imports (dart:, other packages).
String? _resolve(String fromRel, String uri) {
  if (uri.startsWith('package:$packageName/')) {
    return uri.substring('package:$packageName/'.length);
  }
  if (uri.contains(':')) return null;
  final parts = fromRel.split('/')..removeLast();
  for (final seg in uri.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.') {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

String? _layerOf(String rel) => rel.contains('/') ? rel.split('/').first : null;

String _featureOf(String rel) => rel.split('/').length > 1 ? rel.split('/')[1] : '';

String _relative(String root, String path) =>
    path.substring(root.length + 1).replaceAll(r'\', '/');

void _report(List<Violation> violations, Map<String, int> legacy) {
  if (legacy.isNotEmpty) {
    final total = legacy.values.fold<int>(0, (a, b) => a + b);
    stdout.writeln('Not yet migrated ($total files, unchecked):');
    for (final e in legacy.entries.toList()..sort((a, b) => b.value - a.value)) {
      stdout.writeln('  ${e.key.padRight(14)} ${e.value}');
    }
    stdout.writeln();
  }
  if (violations.isEmpty) {
    stdout.writeln('Architecture check passed.');
    return;
  }
  stdout.writeln('${violations.length} architecture violation(s):');
  for (final v in violations) {
    stdout.writeln('  [${v.rule}] lib/${v.file}');
    stdout.writeln('      ${v.detail}');
  }
  stdout.writeln('\nSee documentation/architecture-tenets.md');
}
