import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/constants/build_info.dart';

void main() {
  test('label lists build time, commit, Flutter version and engine', () {
    final label = BuildInfo.label;

    expect(label, startsWith('Build '));
    expect(label, contains('Flutter '));
    expect(label, contains('engine '));
  });
}
