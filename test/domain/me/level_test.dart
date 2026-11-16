import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/me/level.dart';

/// R-87, R-41: the level comes from the points and the Worker's tiers. The
/// names and limits are not hardcoded in the app.
const _tiers = [
  (id: 'bronze', min: 0),
  (id: 'silver', min: 1000),
  (id: 'gold', min: 5000),
  (id: 'platinum', min: 10000),
];

void main() {
  test('120 points: Bronze Buddy, 120 of 1000 to Silver', () {
    final l = levelProgress(120, _tiers)!;
    expect(l.name, 'Bronze Buddy');
    expect(l.label, '120 / 1000');
    expect(l.fraction, closeTo(0.12, 0.0001));
    expect(l.nextName, 'Silver Buddy');
  });

  test('the first point of a tier belongs to that tier', () {
    expect(levelProgress(999, _tiers)!.name, 'Bronze Buddy');
    expect(levelProgress(1000, _tiers)!.name, 'Silver Buddy');
  });

  test('progress is counted inside the tier', () {
    final l = levelProgress(3000, _tiers)!;
    expect(l.name, 'Silver Buddy');
    expect(l.label, '3000 / 5000');
    expect(l.fraction, closeTo(0.5, 0.0001), reason: '2000 of the 4000 span');
  });

  test('the top tier has no next level and a full bar', () {
    final l = levelProgress(12000, _tiers)!;
    expect(l.name, 'Platinum Buddy');
    expect(l.nextName, isNull);
    expect(l.fraction, 1.0);
    expect(l.label, '12000');
  });

  test('tiers given in any order work', () {
    final l = levelProgress(1500, _tiers.reversed.toList())!;
    expect(l.name, 'Silver Buddy');
  });

  test('no tiers (the Worker could not be reached): no level to show', () {
    expect(levelProgress(120, const []), isNull);
  });

  test('negative points are treated as 0', () {
    expect(levelProgress(-5, _tiers)!.label, '0 / 1000');
  });
}
