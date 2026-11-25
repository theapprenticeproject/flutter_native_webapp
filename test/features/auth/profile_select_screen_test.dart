import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/auth/auth_provider.dart';
import 'package:tapapp/domain/auth/redeemed_student.dart';
import 'package:tapapp/domain/program_content/program_content_provider.dart';
import 'package:tapapp/features/auth/presentation/profile_select_screen.dart';

/// QA bugs 1 and 2: the picker must look like the design (M-F1-01): the two
/// logos, the round TAP Buddy picture, "Welcome", "Hi Champ, please select who I
/// will talk to", and one row for each student with the initials, the name,
/// "Class N • subject" and a Select button. No "Hear again": there is no audio
/// in v1.
RedeemedStudent _s(String id, String name, String grade, String course) =>
    RedeemedStudent(
      studentId: id,
      name: name,
      grade: grade,
      points: 0,
      courseId: course,
    );

Future<void> _pump(
  WidgetTester tester, {
  List<RedeemedStudent>? students,
  Map<String, String> courseNames = const {},
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        linkRosterProvider.overrideWith(
          (ref) async =>
              students ??
              [
                _s('S1', 'Aarav Kumar', '5', 'C-SCI'),
                _s('S2', 'Ajay Kumar', '8', 'C-FIN'),
              ],
        ),
        courseNameByIdProvider.overrideWith((ref) async => courseNames),
      ],
      child: const MaterialApp(home: ProfileSelectScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('has the welcome picture and the two lines of the design', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Welcome'), findsOneWidget);
    expect(
      find.text('Hi Champ, please select who I will talk to'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Hear again'), findsNothing);
    expect(find.text("Who's learning today?"), findsNothing);
  });

  testWidgets('one row for each student: initials, name, class and subject', (
    tester,
  ) async {
    await _pump(
      tester,
      courseNames: {'C-SCI': 'Science', 'C-FIN': 'Financial Literacy'},
    );
    expect(find.text('AK'), findsNWidgets(2));
    expect(find.text('Aarav Kumar'), findsOneWidget);
    expect(find.text('Ajay Kumar'), findsOneWidget);
    expect(find.text('Class 5 • Science'), findsOneWidget);
    expect(find.text('Class 8 • Financial Literacy'), findsOneWidget);
    expect(find.text('Select'), findsNWidgets(2));
  });

  testWidgets('a course we do not know shows only the class', (tester) async {
    await _pump(tester);
    expect(find.text('Class 5'), findsOneWidget);
    expect(find.textContaining('•'), findsNothing);
  });

  testWidgets('the rows are a list, not a grid', (tester) async {
    await _pump(tester);
    final a = tester.getTopLeft(find.text('Aarav Kumar'));
    final b = tester.getTopLeft(find.text('Ajay Kumar'));
    expect(b.dx, a.dx, reason: 'same column');
    expect(b.dy, greaterThan(a.dy));
  });

  testWidgets('no student on the phone: says so', (tester) async {
    await _pump(tester, students: const []);
    expect(
      find.text('No student profiles found for this account.'),
      findsOneWidget,
    );
    expect(find.text('Select'), findsNothing);
  });
}
