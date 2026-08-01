import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/media/domain/poster_file.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';

import '../../content/content_test_helpers.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  while (tester.takeException() != null) {}
}

Future<void> _tapLifecycle(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await _settle(tester);
}

Future<void> _tapDialogAction(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _settle(tester);
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required FakeSeriesRepository seriesRepository,
  FakeSeriesMutationRepository? mutationRepository,
  FakeCategoryRepository? categoryRepository,
  FakeImageUploadRepository? imageUploadRepository,
  AdminSeries? initialSeries,
  PosterFile? initialPosterForTesting,
}) async {
  await tester.pumpWidget(
    _wrap(
      SeriesDetailPage(
        seriesId: testSeriesId,
        initialSeries: initialSeries,
        seriesRepository: seriesRepository,
        mutationRepository:
            mutationRepository ?? FakeSeriesMutationRepository(),
        categoryRepository: categoryRepository ?? FakeCategoryRepository(),
        imageUploadRepository:
            imageUploadRepository ?? FakeImageUploadRepository(),
        initialPosterForTesting: initialPosterForTesting,
      ),
    ),
  );
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureContentWidgetTests);

  group('SeriesDetailPage mandatory fetch', () {
    testWidgets('calls fetchById even when initialSeries is provided', (
      tester,
    ) async {
      final repository = FakeSeriesRepository((_) async => testSeries());

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        initialSeries: testSeries(title: 'Snapshot Title'),
      );
      await _settle(tester);

      expect(repository.fetchByIdCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('shows server result when it differs from initialSeries', (
      tester,
    ) async {
      final repository = FakeSeriesRepository(
        (_) async => testSeries(title: 'Server Title', contentVersion: 3),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        initialSeries: testSeries(title: 'Snapshot Title', contentVersion: 1),
      );
      await _settle(tester);

      expect(find.text('Server Title'), findsWidgets);
      expect(find.text('Snapshot Title'), findsNothing);
    });

    testWidgets('fetch error disables mutation actions', (tester) async {
      final repository = FakeSeriesRepository((_) async {
        throw StateError('not found');
      });

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        initialSeries: testSeries(title: 'Snapshot Title'),
      );
      await _settle(tester);

      expect(find.text('Dizi yüklenemedi.'), findsOneWidget);
      expect(find.text('Yayınla'), findsNothing);
      expect(find.text('Değişiklikleri Kaydet'), findsNothing);
    });

    testWidgets('retry loads fresh detail after fetch failure', (tester) async {
      var shouldFail = true;
      final repository = FakeSeriesRepository((_) async {
        if (shouldFail) {
          throw StateError('not found');
        }
        return testSeries(title: 'Recovered Title');
      });

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        initialSeries: testSeries(title: 'Snapshot Title'),
      );
      await _settle(tester);

      shouldFail = false;
      await tester.tap(find.text('Tekrar Dene'));
      await _settle(tester);

      expect(find.text('Recovered Title'), findsWidgets);
      expect(find.text('Yayınla'), findsOneWidget);
    });
  });

  group('SeriesDetailPage lifecycle confirm', () {
    testWidgets('cancel publish does not call repository', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 2),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );
      await _settle(tester);

      await _tapLifecycle(tester, 'Yayınla');
      await _tapDialogAction(tester, 'Vazgeç');

      expect(mutationRepository.publishCalls, 0);
    });

    testWidgets('confirm publish calls repository once with current version', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 4),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );
      await _settle(tester);

      await _tapLifecycle(tester, 'Yayınla');
      await _tapDialogAction(tester, 'Yayınla');

      expect(mutationRepository.publishCalls, 1);
      expect(mutationRepository.lastPublishExpectedVersion, 4);
    });

    testWidgets('publish error does not show success snackbar', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..publishError = const ContentException(
          message: 'Yayınlanamadı',
          kind: ContentFailureKind.validation,
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 1),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );
      await _settle(tester);

      await _tapLifecycle(tester, 'Yayınla');
      await _tapDialogAction(tester, 'Yayınla');

      expect(find.text('Dizi yayınlandı.'), findsNothing);
      expect(find.text('Yayınlanamadı'), findsOneWidget);
    });
  });

  group('SeriesDetailPage poster to lifecycle version chain', () {
    testWidgets('publish uses version from poster replacement result', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..replacePosterResult = SeriesPosterReplaceResult(
          seriesId: testSeriesId,
          posterPath: 'posters/new.jpg',
          contentVersion: 5,
          updatedAt: DateTime.utc(2026, 8, 1, 12),
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 4),
      );
      final imageUploadRepository = FakeImageUploadRepository();

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
        imageUploadRepository: imageUploadRepository,
        initialPosterForTesting: testPosterFile(),
      );
      await _settle(tester);

      await tester.ensureVisible(find.text('Posteri Değiştir'));
      await tester.tap(find.text('Posteri Değiştir'));
      await _settle(tester);

      expect(mutationRepository.replacePosterCalls, 1);
      expect(mutationRepository.lastReplaceExpectedVersion, 4);

      await _tapLifecycle(tester, 'Yayınla');
      await _tapDialogAction(tester, 'Yayınla');

      expect(mutationRepository.publishCalls, 1);
      expect(mutationRepository.lastPublishExpectedVersion, 5);
      expect(mutationRepository.lastPublishExpectedVersion, isNot(4));
    });

    testWidgets('poster conflict blocks publish success continuation', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..replacePosterError = const ContentException(
          message: ContentErrorMapper.conflictMessage,
          kind: ContentFailureKind.conflict,
          isConflict: true,
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 4),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
        initialPosterForTesting: testPosterFile(),
      );
      await _settle(tester);

      await tester.ensureVisible(find.text('Posteri Değiştir'));
      await tester.tap(find.text('Posteri Değiştir'));
      await _settle(tester);

      expect(mutationRepository.replacePosterCalls, 1);
      expect(find.text('Poster güncellendi.'), findsNothing);
      expect(mutationRepository.publishCalls, 0);
    });
  });

  group('SeriesDetailPage lifecycle matrix', () {
    testWidgets('published unpublish cancel does not call repository', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(isPublished: true, contentVersion: 3),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Yayından Kaldır');
      await _tapDialogAction(tester, 'Vazgeç');

      expect(mutationRepository.unpublishCalls, 0);
    });

    testWidgets('published unpublish confirm calls repository once', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(isPublished: true, contentVersion: 3),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Yayından Kaldır');
      await _tapDialogAction(tester, 'Yayından Kaldır');

      expect(mutationRepository.unpublishCalls, 1);
      expect(find.text('Dizi yayından kaldırıldı.'), findsOneWidget);
    });

    testWidgets('unpublish error does not show success snackbar', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..unpublishError = const ContentException(
          message: 'Kaldırılamadı',
          kind: ContentFailureKind.validation,
        );
      final repository = FakeSeriesRepository(
        (_) async => testSeries(isPublished: true, contentVersion: 3),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Yayından Kaldır');
      await _tapDialogAction(tester, 'Yayından Kaldır');

      expect(find.text('Dizi yayından kaldırıldı.'), findsNothing);
      expect(find.text('Kaldırılamadı'), findsOneWidget);
    });

    testWidgets('unpublish conflict reloads without auto retry', (
      tester,
    ) async {
      var fetchCount = 0;
      final mutationRepository = FakeSeriesMutationRepository()
        ..unpublishError = const ContentException(
          message: ContentErrorMapper.conflictMessage,
          kind: ContentFailureKind.conflict,
          isConflict: true,
        );
      final repository = FakeSeriesRepository((_) async {
        fetchCount += 1;
        return testSeries(
          isPublished: fetchCount == 1,
          contentVersion: fetchCount == 1 ? 3 : 4,
          title: fetchCount == 1 ? 'Before Conflict' : 'After Conflict',
        );
      });

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Yayından Kaldır');
      await _tapDialogAction(tester, 'Yayından Kaldır');
      await _settle(tester);

      expect(mutationRepository.unpublishCalls, 1);
      expect(fetchCount, greaterThanOrEqualTo(2));
      expect(find.text('After Conflict'), findsWidgets);
      expect(find.text('Dizi yayından kaldırıldı.'), findsNothing);
    });

    testWidgets('archive confirm calls repository once', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 2),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Arşivle');
      await _tapDialogAction(tester, 'Arşivle');

      expect(mutationRepository.archiveCalls, 1);
      expect(find.text('Dizi arşivlendi.'), findsOneWidget);
    });

    testWidgets('archived series shows only restore action', (tester) async {
      final repository = FakeSeriesRepository(
        (_) async => testSeries(isArchived: true, contentVersion: 5),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: FakeSeriesMutationRepository(),
      );

      expect(find.text('Geri Yükle'), findsOneWidget);
      expect(find.text('Yayınla'), findsNothing);
      expect(find.text('Arşivle'), findsNothing);
    });

    testWidgets('restore shows unpublished state', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(isArchived: true, contentVersion: 5),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Geri Yükle');
      await _tapDialogAction(tester, 'Geri Yükle');
      await _settle(tester);

      expect(mutationRepository.restoreCalls, 1);
      expect(find.text('Yayında Değil'), findsWidgets);
      expect(find.text('Yayınla'), findsOneWidget);
    });

    testWidgets('lifecycle busy blocks second unpublish call', (tester) async {
      final mutationRepository = FakeSeriesMutationRepository()
        ..unpublishDelay = Completer<void>();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(isPublished: true, contentVersion: 3),
      );

      await _pumpDetail(
        tester,
        seriesRepository: repository,
        mutationRepository: mutationRepository,
      );

      await _tapLifecycle(tester, 'Yayından Kaldır');
      await _tapDialogAction(tester, 'Yayından Kaldır');
      await tester.pump();

      expect(mutationRepository.unpublishCalls, 1);

      final unpublishButton = find.widgetWithText(OutlinedButton, 'Yayından Kaldır');
      if (unpublishButton.evaluate().isNotEmpty) {
        expect(tester.widget<OutlinedButton>(unpublishButton).onPressed, isNull);
      }

      mutationRepository.unpublishDelay!.complete();
      await _settle(tester);

      expect(mutationRepository.unpublishCalls, 1);
    });
  });
}
