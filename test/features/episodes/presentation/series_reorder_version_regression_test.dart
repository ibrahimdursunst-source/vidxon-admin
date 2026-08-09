import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_reorder_page.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';

import '../../content/content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  Future<void> openReorder(WidgetTester tester) async {
    await tester.tap(find.text('Sıralamayı Düzenle'));
    await settle(tester);
    expect(find.text('Bölüm Sıralaması'), findsOneWidget);
  }

  Future<void> dragAndSave(WidgetTester tester) async {
    await tester.longPress(find.byIcon(Icons.drag_handle).first);
    await settle(tester);
    await tester.drag(
      find.byIcon(Icons.drag_handle).first,
      const Offset(0, 80),
    );
    await settle(tester);
    await tester.tap(find.text('Sıralamayı Kaydet'));
    await settle(tester);
  }

  group('Series reorder version regression', () {
    testWidgets('syncs canonical series version before opening reorder', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(episodes);
      final seriesRepository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 44),
      );

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: SeriesEpisodesPage(
            seriesId: testSeriesId,
            seriesTitle: 'Test Dizi',
            initialSeries: testSeries(contentVersion: 29),
            episodeRepository: episodeRepository,
            seriesRepository: seriesRepository,
            mutationRepository: mutationRepository,
          ),
        ),
      );
      await settle(tester);

      expect(seriesRepository.fetchByIdCalls, greaterThan(0));

      await openReorder(tester);
      await dragAndSave(tester);

      expect(mutationRepository.reorderCalls, 1);
      expect(mutationRepository.lastReorderExpectedVersion, 44);
    });

    testWidgets('sequential reorders from episode list use updated version', (
      tester,
    ) async {
      var currentVersion = 29;
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(episodes);
      final seriesRepository = FakeSeriesRepository((_) async {
        return testSeries(contentVersion: currentVersion);
      });

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: SeriesEpisodesPage(
            seriesId: testSeriesId,
            seriesTitle: 'Test Dizi',
            initialSeries: testSeries(contentVersion: 29),
            episodeRepository: episodeRepository,
            seriesRepository: seriesRepository,
            mutationRepository: mutationRepository,
          ),
        ),
      );
      await settle(tester);

      await openReorder(tester);
      await dragAndSave(tester);
      expect(mutationRepository.lastReorderExpectedVersion, 29);

      currentVersion = 30;
      await openReorder(tester);
      await dragAndSave(tester);
      expect(mutationRepository.reorderCalls, 2);
      expect(mutationRepository.lastReorderExpectedVersion, 30);
    });

    testWidgets('40001 conflict is not retried automatically', (tester) async {
      final mutationRepository = TrackingSeriesMutationRepository(
        reorderConflictForExpectedVersions: {29},
      );
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeReorderPage(
            seriesId: testSeriesId,
            episodes: episodes,
            expectedSeriesVersion: 29,
            mutationRepository: mutationRepository,
            seriesRepository: FakeSeriesRepository(
              (_) async => testSeries(contentVersion: 44),
            ),
            episodeRepository: FakeEpisodeRepository(episodes),
          ),
        ),
      );
      await settle(tester);
      await dragAndSave(tester);

      expect(mutationRepository.reorderCalls, 1);
      expect(find.text('Bölüm Sıralaması'), findsOneWidget);
    });
  });
}
