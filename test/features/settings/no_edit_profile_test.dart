import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R-74: Edit profile is later. v1 shows the profile data and has no form to
/// save it (the save needed a phone number the new login does not have).
void main() {
  test('the Settings profile page has no Edit button', () {
    final text = File(
      'lib/features/settings/presentation/widgets/profile_details_view.dart',
    ).readAsStringSync();
    expect(text.contains("'Edit Info'"), isFalse);
  });

  test('Me has no Edit profile, Sign out or theme switch (R-74, R-35, R-73)', () {
    final text = File(
      'lib/features/me/presentation/me_view.dart',
    ).readAsStringSync();
    // Whole words only: `AppTheme` is the colour set, not a theme switch.
    for (final word in [
      'Edit profile',
      'Sign out',
      'Log out',
      'Dark mode',
      'Light mode',
    ]) {
      expect(text.contains(word), isFalse, reason: word);
    }
    expect(RegExp(r'(?<![A-Za-z])Theme\b').hasMatch(text), isFalse);
  });
}
