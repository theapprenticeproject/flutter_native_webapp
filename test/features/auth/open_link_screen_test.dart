import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/auth/presentation/open_link_screen.dart';

/// v1 has no password login (R-32). A student with no session is told to open
/// the link TAP sent on WhatsApp. There is nothing to type.
void main() {
  testWidgets('tells the student to open the WhatsApp link', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OpenLinkScreen()));
    await tester.pump();
    expect(find.textContaining('WhatsApp'), findsWidgets);
    expect(find.textContaining('link'), findsWidgets);
  });

  testWidgets('has no form: no text field, no password, no sign-in button', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OpenLinkScreen()));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    for (final word in [
      'Password',
      'password',
      'Log in',
      'Login',
      'Sign in',
      'OTP',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });
}
