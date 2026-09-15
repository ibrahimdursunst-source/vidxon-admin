import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/categories/domain/admin_category.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';

import '../../content/content_test_helpers.dart';

const _testCategory = AdminCategory(
  id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
  name: 'Drama',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  test('new series editor save uses only the atomic translations RPC', () {
    final detail = File(
      'lib/features/series/presentation/series_detail_page.dart',
    ).readAsStringSync();
    final create = File(
      'lib/features/series/presentation/series_create_page.dart',
    ).readAsStringSync();

    expect(detail.contains('updateSeriesWithTranslations('), isTrue);
    expect(detail.contains('upsertSeriesTranslations('), isFalse);
    expect(create.contains('createSeriesWithTranslations('), isTrue);
    expect(create.contains('upsertSeriesTranslations('), isFalse);
    expect(create.contains('createSeriesWithPartner('), isFalse);
  });

  testWidgets('failed atomic save does not show success snackbar', (
    tester,
  ) async {
    final mutationRepository = FakeSeriesMutationRepository()
      ..updateError = const ContentException(
        message: 'Çeviri dili geçersiz.',
        kind: ContentFailureKind.validation,
      );
    final repository = FakeSeriesRepository(
      (_) async => testSeries(contentVersion: 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeriesDetailPage(
            seriesId: testSeriesId,
            seriesRepository: repository,
            mutationRepository: mutationRepository,
            categoryRepository: FakeCategoryRepository(const [_testCategory]),
            imageUploadRepository: FakeImageUploadRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException();

    final save = find.text('Değişiklikleri Kaydet');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    tester.takeException();

    expect(mutationRepository.updateCalls, 1);
    expect(find.text('Dizi güncellendi.'), findsNothing);
    expect(find.text('Çeviri dili geçersiz.'), findsWidgets);
  });

  testWidgets('successful atomic save updates local content_version', (
    tester,
  ) async {
    final mutationRepository = FakeSeriesMutationRepository()
      ..updateResult = SeriesUpdateResult(
        seriesId: testSeriesId,
        title: 'Test Dizi',
        synopsis: 'Synopsis',
        slug: 'test-dizi',
        status: 'ongoing',
        isPublished: false,
        posterPath: '',
        contentVersion: 3,
        updatedAt: DateTime.utc(2026, 8, 1, 12),
        isArchived: false,
        originalLocale: 'tr',
      );
    final repository = FakeSeriesRepository(
      (_) async => testSeries(contentVersion: 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeriesDetailPage(
            seriesId: testSeriesId,
            seriesRepository: repository,
            mutationRepository: mutationRepository,
            categoryRepository: FakeCategoryRepository(const [_testCategory]),
            imageUploadRepository: FakeImageUploadRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException();

    final save = find.text('Değişiklikleri Kaydet');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    tester.takeException();

    expect(mutationRepository.updateCalls, 1);
    expect(
      mutationRepository.lastUpdateInput?.expectedContentVersion,
      2,
    );
    expect(find.text('Dizi güncellendi.'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(SeriesDetailPage)),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Değişiklikleri Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    tester.takeException();

    expect(mutationRepository.updateCalls, 2);
    expect(
      mutationRepository.lastUpdateInput?.expectedContentVersion,
      3,
    );
  });

  test('parseRpcRow treats ok=false and missing row as failure', () {
    expect(parseRpcRow({'ok': false, 'content_version': 4}), isNull);
    expect(parseRpcRow(null), isNull);
    expect(parseRpcRow('not-a-map'), isNull);
  });

  test('series update result requires content_version before success', () {
    expect(
      () => SeriesUpdateResult.fromMap({
        'ok': true,
        'series_id': testSeriesId,
        'title': 'Test Dizi',
        'updated_at': '2026-08-01T12:00:00.000Z',
      }),
      throwsFormatException,
    );
    expect(
      () => requireContentVersion(null),
      throwsFormatException,
    );
    expect(requireContentVersion(7), 7);
    final parsed = SeriesUpdateResult.fromMap({
      'ok': true,
      'series_id': testSeriesId,
      'title': 'Test Dizi',
      'synopsis': 'Synopsis',
      'slug': 'test-dizi',
      'status': 'ongoing',
      'is_published': false,
      'poster_path': '',
      'content_version': 3,
      'updated_at': '2026-08-01T12:00:00.000Z',
      'is_archived': false,
    });
    expect(parsed.contentVersion, 3);
    expect(parsed.seriesId, testSeriesId);
  });

  testWidgets('malformed atomic result does not show success snackbar', (
    tester,
  ) async {
    final mutationRepository = FakeSeriesMutationRepository()
      ..updateError = const ContentException(
        message: 'Sunucu yanıtı geçersiz.',
        kind: ContentFailureKind.serverError,
      );
    final repository = FakeSeriesRepository(
      (_) async => testSeries(contentVersion: 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeriesDetailPage(
            seriesId: testSeriesId,
            seriesRepository: repository,
            mutationRepository: mutationRepository,
            categoryRepository: FakeCategoryRepository(const [_testCategory]),
            imageUploadRepository: FakeImageUploadRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException();

    final save = find.text('Değişiklikleri Kaydet');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.text('Dizi güncellendi.'), findsNothing);
    expect(find.text('Sunucu yanıtı geçersiz.'), findsWidgets);
  });
}
