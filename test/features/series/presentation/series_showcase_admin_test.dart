import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/media/data/image_upload_repository.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';
import 'package:vidxon_admin/features/series/presentation/series_create_page.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';

import '../../content/content_test_helpers.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  while (tester.takeException() != null) {}
}

Finder _showcaseSwitch() => find.widgetWithText(SwitchListTile, 'Vitrinde Göster');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('SeriesCreatePage showcase', () {
    Future<void> pumpCreate(
      WidgetTester tester, {
      required FakeSeriesMutationRepository mutationRepository,
      FakeImageUploadRepository? imageUploadRepository,
      bool withLandscape = false,
      void Function(AdminSeries created)? onSuccess,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeriesCreatePage(
              onCancel: () {},
              onSuccess: onSuccess ?? (_) {},
              seriesMutationRepository: mutationRepository,
              imageUploadRepository:
                  imageUploadRepository ?? FakeImageUploadRepository(),
              categoryRepository: FakeCategoryRepository(),
              initialPosterForTesting: testPosterFile(),
              initialShowcaseLandscapeForTesting:
                  withLandscape ? testPosterFile() : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Yeni Dizi');
      await tester.enterText(find.byType(TextFormField).at(2), 'yeni-dizi');
      tester.takeException();
    }

    testWidgets('showcase defaults off and create does not call showcase RPC', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(title: 'Yeni Dizi', contentVersion: 1);

      await pumpCreate(tester, mutationRepository: mutationRepository);

      final tile = tester.widget<SwitchListTile>(_showcaseSwitch());
      expect(tile.value, isFalse);
      expect(find.text('Yatay Vitrin Görseli'), findsOneWidget);
      expect(
        find.text(
          'Önerilen: 1920×1080 px (16:9). Minimum: 1280×720 px. Bu görsel ana sayfa vitrini ve dizi detayının üst bölümünde kullanılır.',
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Diziyi Oluştur'));
      await tester.tap(find.text('Diziyi Oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(mutationRepository.createCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 0);
    });

    testWidgets('enable without landscape is blocked before create', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries();

      await pumpCreate(tester, mutationRepository: mutationRepository);
      await tester.ensureVisible(_showcaseSwitch());
      await tester.tap(_showcaseSwitch());
      await tester.pump();

      await tester.ensureVisible(find.text('Diziyi Oluştur'));
      await tester.tap(find.text('Diziyi Oluştur'));
      await tester.pump();

      expect(mutationRepository.createCalls, 0);
      expect(mutationRepository.setShowcaseCalls, 0);
      expect(
        find.text('Vitrinde göstermek için yatay vitrin görseli yükleyin.'),
        findsOneWidget,
      );
    });

    testWidgets('create uploads landscape after real series id with current version', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(
          title: 'Yeni Dizi',
          contentVersion: 1,
          posterPath: 'posters/test/poster.png',
        );
      final imageUploadRepository = FakeImageUploadRepository();
      AdminSeries? created;

      await pumpCreate(
        tester,
        mutationRepository: mutationRepository,
        imageUploadRepository: imageUploadRepository,
        withLandscape: true,
        onSuccess: (result) => created = result,
      );

      await tester.ensureVisible(find.text('Diziyi Oluştur'));
      await tester.tap(find.text('Diziyi Oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(mutationRepository.createCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 1);
      expect(mutationRepository.lastShowcaseExpectedVersion, 1);
      expect(mutationRepository.lastShowcaseEnabled, isFalse);
      expect(imageUploadRepository.lastPurpose, 'series_poster_replacement');
      expect(imageUploadRepository.lastSeriesId, testSeriesId);
      expect(
        mutationRepository.lastShowcasePath,
        startsWith('posters/series/$testSeriesId/'),
      );
      expect(created, isNotNull);
      expect(created!.posterPath, isNot(created!.showcaseLandscapePath));
      expect(created!.posterPath, 'posters/test/poster.png');
    });

    testWidgets(
      'portrait upload transport error stops before create and is not a showcase RPC failure',
      (tester) async {
        final mutationRepository = FakeSeriesMutationRepository()
          ..createResult = testSeries();
        final imageUploadRepository = FakeImageUploadRepository()
          ..requestError = Exception('Failed to fetch');

        await pumpCreate(
          tester,
          mutationRepository: mutationRepository,
          imageUploadRepository: imageUploadRepository,
          withLandscape: true,
        );

        await tester.ensureVisible(find.text('Diziyi Oluştur'));
        await tester.tap(find.text('Diziyi Oluştur'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(mutationRepository.createCalls, 0);
        expect(mutationRepository.setShowcaseCalls, 0);
        expect(
          find.text('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('create success then landscape upload failure still returns the series', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(
          title: 'Yeni Dizi',
          contentVersion: 1,
          posterPath: 'posters/test/poster.png',
        );
      final imageUploadRepository = FakeImageUploadRepository()
        ..replacementRequestError = ImageUploadException(
          'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
        );
      AdminSeries? created;

      await pumpCreate(
        tester,
        mutationRepository: mutationRepository,
        imageUploadRepository: imageUploadRepository,
        withLandscape: true,
        onSuccess: (result) => created = result,
      );

      await tester.ensureVisible(find.text('Diziyi Oluştur'));
      await tester.tap(find.text('Diziyi Oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(mutationRepository.createCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 0);
      expect(created, isNotNull);
      expect(created!.id, testSeriesId);
      expect(created!.contentVersion, 1);
      expect(created!.showcaseLandscapePath, isNull);
      expect(created!.isShowcase, isFalse);
      expect(
        find.text(
          'Dizi oluşturuldu. Yatay vitrin görselini dizi detayından tekrar yükleyin.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Poster zaten yüklendi'),
        findsNothing,
      );
      expect(find.text('Diziyi Oluştur'), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(mutationRepository.createCalls, 1);
    });

    testWidgets('create success then showcase RPC failure still returns the series', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..createResult = testSeries(
          title: 'Yeni Dizi',
          contentVersion: 1,
          posterPath: 'posters/test/poster.png',
        )
        ..setShowcaseError = const ContentException(
          message: 'Vitrinde göstermek için yatay vitrin görseli yükleyin.',
          kind: ContentFailureKind.validation,
        );
      AdminSeries? created;

      await pumpCreate(
        tester,
        mutationRepository: mutationRepository,
        withLandscape: true,
        onSuccess: (result) => created = result,
      );

      await tester.ensureVisible(find.text('Diziyi Oluştur'));
      await tester.tap(find.text('Diziyi Oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(mutationRepository.createCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 1);
      expect(mutationRepository.lastShowcaseExpectedVersion, 1);
      expect(created, isNotNull);
      expect(created!.id, testSeriesId);
      expect(created!.contentVersion, 1);
      expect(created!.posterPath, 'posters/test/poster.png');
      expect(created!.showcaseLandscapePath, isNull);
      expect(
        find.textContaining('Poster zaten yüklendi'),
        findsNothing,
      );
      expect(find.text('Diziyi Oluştur'), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(mutationRepository.createCalls, 1);
    });
  });

  group('SeriesDetailPage showcase', () {
    Future<void> pumpDetail(
      WidgetTester tester, {
      required FakeSeriesRepository seriesRepository,
      FakeSeriesMutationRepository? mutationRepository,
      FakeImageUploadRepository? imageUploadRepository,
      bool withLandscapePicker = false,
    }) async {
      await tester.pumpWidget(
        _wrap(
          SeriesDetailPage(
            seriesId: testSeriesId,
            seriesRepository: seriesRepository,
            mutationRepository:
                mutationRepository ?? FakeSeriesMutationRepository(),
            categoryRepository: FakeCategoryRepository(),
            imageUploadRepository:
                imageUploadRepository ?? FakeImageUploadRepository(),
            initialShowcaseLandscapeForTesting:
                withLandscapePicker ? testPosterFile() : null,
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('loads current landscape and showcase state', (tester) async {
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          posterPath: 'posters/series/$testSeriesId/portrait.png',
          showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
          isShowcase: true,
        ),
      );

      await pumpDetail(tester, seriesRepository: repository);

      expect(find.text('Yatay Vitrin Görseli'), findsOneWidget);
      expect(
        find.text(
          'Önerilen: 1920×1080 px (16:9). Minimum: 1280×720 px. Bu görsel ana sayfa vitrini ve dizi detayının üst bölümünde kullanılır.',
        ),
        findsOneWidget,
      );
      expect(find.text('Poster'), findsOneWidget);
      final tile = tester.widget<SwitchListTile>(_showcaseSwitch());
      expect(tile.value, isTrue);
    });

    testWidgets('landscape replace does not change poster path or call poster RPC', (
      tester,
    ) async {
      const posterPath = 'posters/series/$testSeriesId/portrait.png';
      final mutationRepository = FakeSeriesMutationRepository();
      final imageUploadRepository = FakeImageUploadRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          contentVersion: 4,
          posterPath: posterPath,
          showcaseLandscapePath: 'posters/series/$testSeriesId/old-land.png',
        ),
      );

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
        imageUploadRepository: imageUploadRepository,
        withLandscapePicker: true,
      );

      await tester.ensureVisible(_showcaseSwitch());
      await tester.tap(_showcaseSwitch());
      await tester.pump();

      await tester.ensureVisible(find.text('Yatay görseli değiştir'));
      await tester.tap(find.text('Yatay görseli değiştir'));
      await _settle(tester);

      expect(mutationRepository.replacePosterCalls, 0);
      expect(mutationRepository.updateCalls, 0);
      expect(mutationRepository.setShowcaseCalls, 1);
      expect(mutationRepository.lastShowcaseExpectedVersion, 4);
      expect(mutationRepository.lastShowcaseEnabled, isFalse);
      expect(
        mutationRepository.lastShowcasePath,
        startsWith('posters/series/$testSeriesId/'),
      );
      expect(mutationRepository.lastShowcasePath, isNot(posterPath));
      expect(imageUploadRepository.lastPurpose, 'series_poster_replacement');
    });

    testWidgets('poster replace does not call showcase RPC', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          contentVersion: 4,
          posterPath: 'posters/series/$testSeriesId/portrait.png',
          showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          SeriesDetailPage(
            seriesId: testSeriesId,
            seriesRepository: repository,
            mutationRepository: mutationRepository,
            categoryRepository: FakeCategoryRepository(),
            imageUploadRepository: FakeImageUploadRepository(),
            initialPosterForTesting: testPosterFile(),
          ),
        ),
      );
      await _settle(tester);

      await tester.ensureVisible(find.text('Posteri Değiştir'));
      await tester.tap(find.text('Posteri Değiştir'));
      await _settle(tester);

      expect(mutationRepository.replacePosterCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 0);
    });

    testWidgets('save enable without landscape is blocked', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 2),
      );

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await tester.ensureVisible(_showcaseSwitch());
      await tester.tap(_showcaseSwitch());
      await tester.pump();
      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await tester.pump();

      expect(mutationRepository.updateCalls, 0);
      expect(mutationRepository.setShowcaseCalls, 0);
      expect(
        find.text('Vitrinde göstermek için yatay vitrin görseli yükleyin.'),
        findsOneWidget,
      );
    });

    testWidgets('disable keeps landscape path and uses version after metadata save', (
      tester,
    ) async {
      const land = 'posters/series/$testSeriesId/land.webp';
      final mutationRepository = FakeSeriesMutationRepository()
        ..setShowcaseResult = SeriesShowcaseResult(
          seriesId: testSeriesId,
          isShowcase: false,
          showcaseLandscapePath: land,
          contentVersion: 4,
          updatedAt: DateTime.utc(2026, 8, 1, 12),
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          contentVersion: 2,
          showcaseLandscapePath: land,
          isShowcase: true,
        ),
      );

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await tester.ensureVisible(_showcaseSwitch());
      await tester.tap(_showcaseSwitch());
      await tester.pump();
      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await _settle(tester);

      expect(mutationRepository.updateCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 1);
      expect(mutationRepository.lastShowcaseExpectedVersion, 3);
      expect(mutationRepository.lastUpdateInput!.expectedContentVersion, 2);
      expect(mutationRepository.lastShowcaseEnabled, isFalse);
      expect(mutationRepository.lastShowcasePath, isNull);
    });

    testWidgets('stale showcase version is mapped without leaking backend text', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..setShowcaseError = const ContentException(
          message: ContentErrorMapper.conflictMessage,
          kind: ContentFailureKind.conflict,
          isConflict: true,
        );
      var fetches = 0;
      final repository = FakeSeriesRepository((_) async {
        fetches += 1;
        return testSeries(
          title: fetches == 1 ? 'Once' : 'Reloaded',
          contentVersion: fetches == 1 ? 2 : 4,
          showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
          isShowcase: false,
        );
      });

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await tester.ensureVisible(_showcaseSwitch());
      await tester.tap(_showcaseSwitch());
      await tester.pump();
      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await _settle(tester);

      expect(mutationRepository.updateCalls, 1);
      expect(mutationRepository.setShowcaseCalls, 1);
      expect(find.text('Reloaded'), findsWidgets);
      expect(find.textContaining('SQLSTATE'), findsNothing);
      expect(find.textContaining('P0001'), findsNothing);
    });

    testWidgets('metadata success then landscape upload failure keeps N+1', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final imageUploadRepository = FakeImageUploadRepository()
        ..replacementRequestError = ImageUploadException(
          'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          contentVersion: 2,
          posterPath: 'posters/series/$testSeriesId/portrait.png',
          showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
        ),
      );

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
        imageUploadRepository: imageUploadRepository,
        withLandscapePicker: true,
      );

      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await _settle(tester);

      expect(mutationRepository.updateCalls, 1);
      expect(mutationRepository.lastUpdateInput!.expectedContentVersion, 2);
      expect(mutationRepository.setShowcaseCalls, 0);
      expect(mutationRepository.replacePosterCalls, 0);

      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await _settle(tester);

      expect(mutationRepository.updateCalls, 2);
      expect(mutationRepository.lastUpdateInput!.expectedContentVersion, 3);
      expect(mutationRepository.setShowcaseCalls, 0);
    });

    testWidgets('metadata success then showcase failure retries with N+1 not stale N', (
      tester,
    ) async {
      const land = 'posters/series/$testSeriesId/land.webp';
      final mutationRepository = FakeSeriesMutationRepository()
        ..setShowcaseError = const ContentException(
          message: 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
          kind: ContentFailureKind.unknown,
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          contentVersion: 2,
          posterPath: 'posters/series/$testSeriesId/portrait.png',
          showcaseLandscapePath: land,
          isShowcase: false,
        ),
      );

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await tester.ensureVisible(_showcaseSwitch());
      await tester.tap(_showcaseSwitch());
      await tester.pump();
      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await _settle(tester);

      expect(mutationRepository.updateCalls, 1);
      expect(mutationRepository.lastUpdateInput!.expectedContentVersion, 2);
      expect(mutationRepository.lastShowcaseExpectedVersion, 3);

      await tester.ensureVisible(find.text('Değişiklikleri Kaydet'));
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await _settle(tester);

      expect(mutationRepository.updateCalls, 2);
      expect(mutationRepository.lastUpdateInput!.expectedContentVersion, 3);
      expect(mutationRepository.lastShowcaseExpectedVersion, 4);
      expect(mutationRepository.replacePosterCalls, 0);
    });

    testWidgets('independent landscape replace uses persisted showcase flag and version', (
      tester,
    ) async {
      const posterPath = 'posters/series/$testSeriesId/portrait.png';
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(
          contentVersion: 4,
          posterPath: posterPath,
          showcaseLandscapePath: 'posters/series/$testSeriesId/old-land.png',
          isShowcase: true,
        ),
      );

      await pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
        withLandscapePicker: true,
      );

      await tester.ensureVisible(find.text('Yatay görseli değiştir'));
      await tester.tap(find.text('Yatay görseli değiştir'));
      await _settle(tester);

      expect(mutationRepository.setShowcaseCalls, 1);
      expect(mutationRepository.lastShowcaseExpectedVersion, 4);
      expect(mutationRepository.lastShowcaseEnabled, isTrue);
      expect(mutationRepository.replacePosterCalls, 0);
    });
  });
}
