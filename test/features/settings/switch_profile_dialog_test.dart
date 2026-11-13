import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/auth/auth_provider.dart';
import 'package:tapapp/domain/auth/redeemed_student.dart';
import 'package:tapapp/features/settings/presentation/widgets/profile_switcher.dart';

/// R-34: the student switches profile without signing in again. The list is the
/// students saved at login. It needs no phone number and makes no request.
RedeemedStudent _s(String id, String name, String grade) =>
    RedeemedStudent(studentId: id, name: name, grade: grade);

Future<List<RedeemedStudent>> _pump(
  WidgetTester tester, {
  required List<RedeemedStudent> roster,
  String? active,
}) async {
  final picked = <RedeemedStudent>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [linkRosterProvider.overrideWith((ref) async => roster)],
      child: MaterialApp(
        home: Scaffold(
          body: SwitchProfileDialog(
            activeLearnerId: active,
            onProfileSelected: (s) async => picked.add(s),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  testWidgets('lists the students from login and marks the active one', (
    tester,
  ) async {
    await _pump(
      tester,
      roster: [_s('S1', 'Durva', '5'), _s('S2', 'Manu', '8')],
      active: 'S1',
    );
    expect(find.text('Durva'), findsOneWidget);
    expect(find.text('Manu'), findsOneWidget);
    expect(find.text('Selected ✓'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.textContaining('phone'), findsNothing);
  });

  testWidgets('choosing a student passes that student on', (tester) async {
    final picked = await _pump(
      tester,
      roster: [_s('S1', 'Durva', '5'), _s('S2', 'Manu', '8')],
      active: 'S1',
    );
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(picked.single.studentId, 'S2');
  });

  testWidgets('an empty list says so in plain words', (tester) async {
    await _pump(tester, roster: const []);
    expect(find.textContaining('No student profiles'), findsOneWidget);
  });
}
