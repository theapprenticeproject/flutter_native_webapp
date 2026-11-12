import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/assets/data_loader.dart';
import 'package:tapapp/domain/program_content/export_program_content_error_model.dart';
import 'package:tapapp/domain/program_content/program_content_repository.dart';
import 'package:tapapp/domain/reference_data/asset_data_source.dart';

class _FailingLoader implements DataLoader {
  _FailingLoader(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> loadJson({
    required String cacheKey,
    required Future<Map<String, dynamic>> Function() fetch,
    bool forceRefresh = false,
  }) async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAssets implements AssetDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _JsonLoader implements DataLoader {
  _JsonLoader(this.json);

  final Map<String, dynamic> json;

  @override
  Future<Map<String, dynamic>> loadJson({
    required String cacheKey,
    required Future<Map<String, dynamic>> Function() fetch,
    bool forceRefresh = false,
  }) async => json;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a failed course load keeps the underlying error', () async {
    final repository = ProgramContentRepository(
      _FailingLoader(StateError('IndexedDB write failed')),
      _UnusedAssets(),
    );

    await expectLater(
      repository.fetchCourseDetail('C1'),
      throwsA(
        isA<ExportProgramContentErrorModel>()
            .having(
              (e) => e.reason,
              'reason',
              ProgramContentErrorReason.courseNotFound,
            )
            .having((e) => e.cause, 'cause', isA<StateError>())
            .having(
              (e) => e.toString(),
              'toString',
              allOf(contains('C1'), contains('IndexedDB write failed')),
            ),
      ),
    );
  });

  test(
    'content that cannot be parsed is reported as malformed with a cause',
    () async {
      final repository = ProgramContentRepository(
        _JsonLoader({'id': 123}),
        _UnusedAssets(),
      );

      await expectLater(
        repository.fetchCourseDetail('C1'),
        throwsA(
          isA<ExportProgramContentErrorModel>()
              .having(
                (e) => e.reason,
                'reason',
                ProgramContentErrorReason.malformedContent,
              )
              .having((e) => e.cause, 'cause', isNotNull),
        ),
      );
    },
  );

  test('an error without a cause prints as before', () {
    expect(
      ExportProgramContentErrorModel.courseNotFound('C1').toString(),
      'ExportProgramContentErrorModel(courseNotFound: No course found for id "C1")',
    );
  });
}
