import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/assets/data_loader.dart';
import 'package:tapapp/core/constants/app_constants.dart';
import 'package:tapapp/domain/profile/active_profile_model.dart';
import 'package:tapapp/domain/profile/profile_provider.dart';
import 'package:tapapp/domain/profile/student_language_provider.dart';
import 'package:tapapp/domain/program_content/program_content_provider.dart';
import 'package:tapapp/domain/program_content/program_content_repository.dart';
import 'package:tapapp/domain/reference_data/asset_data_source.dart';

class _KeyCatcher implements DataLoader {
  final keys = <String>[];

  @override
  Future<Map<String, dynamic>> loadJson({
    required String cacheKey,
    required Future<Map<String, dynamic>> Function() fetch,
    bool forceRefresh = false,
  }) async {
    keys.add(cacheKey);
    throw StateError('stop here');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAssets implements AssetDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ActiveProfileModel _profile(String? language) => ActiveProfileModel(
  phone: '',
  learnerId: 'S1',
  studentName: 'Asha',
  language: language,
);

void main() {
  test('the Worker may send a code or the name of the language', () {
    expect(AppConstants.languageCodeFor('hi'), 'hi');
    expect(AppConstants.languageCodeFor('Hindi'), 'hi');
    expect(AppConstants.languageCodeFor(' KANNADA '), 'kn');
    expect(AppConstants.languageCodeFor('en'), 'en');
  });

  test('no language, or one the app does not have, is English', () {
    expect(AppConstants.languageCodeFor(null), 'en');
    expect(AppConstants.languageCodeFor(''), 'en');
    expect(AppConstants.languageCodeFor('Tamil'), 'en');
  });

  test('the profile keeps the language across a restart', () {
    final back = ActiveProfileModel.fromJson(_profile('mr').toJson());
    expect(back.language, 'mr');
  });

  Future<ProviderContainer> signedIn(String? language) async {
    final container = ProviderContainer(
      overrides: [
        activeProfileProvider.overrideWith(
          (ref) async => language == 'none' ? null : _profile(language),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(activeProfileProvider.future);
    return container;
  }

  test('the app language is the signed-in student\'s language', () async {
    expect((await signedIn('Hindi')).read(studentLanguageProvider), 'hi');
    expect((await signedIn('pa')).read(studentLanguageProvider), 'pa');
    expect((await signedIn(null)).read(studentLanguageProvider), 'en');
    expect((await signedIn('none')).read(studentLanguageProvider), 'en');
  });

  test('the course is loaded in the student\'s language', () async {
    final loader = _KeyCatcher();
    final container = ProviderContainer(
      overrides: [
        activeProfileProvider.overrideWith((ref) async => _profile('kn')),
        programContentRepositoryProvider.overrideWith(
          (ref) async => ProgramContentRepository(loader, _UnusedAssets()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(activeProfileProvider.future);

    await expectLater(
      container.read(courseDetailDataProvider('C1').future),
      throwsA(anything),
    );
    expect(loader.keys.single, contains(':kn:'));
  });
}
