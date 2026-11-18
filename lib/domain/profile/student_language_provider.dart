import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import 'profile_provider.dart';

/// The language of the signed-in student (the Worker's `language`). It sets the
/// app text, the chat and the course content. English when nobody is signed in
/// or the language is not one the app has.
final studentLanguageProvider = Provider<String>(
  (ref) => AppConstants.languageCodeFor(
    ref.watch(activeProfileProvider).value?.language,
  ),
);
