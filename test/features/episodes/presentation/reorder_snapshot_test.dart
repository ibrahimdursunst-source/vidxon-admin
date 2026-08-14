import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
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

  group('Reorder snapshot model', () {
    testWidgets('snapshot load failure blocks reorder navigation', (tester) async {
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotError: const ContentException(
          message: 'Snapshot failed',
          kind: ContentFailureKind.serverError,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: SeriesEpisodesPage(
            seriesId: testSeriesId,
            seriesTitle: 'Test Dizi',
            episodeRepository: episodeRepository,
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Sıralamayı Düzenle'));
      await settle(tester);

      expect(episodeRepository.loadReorderSnapshotCalls, 1);
      expect(episodeRepository.fetchListCalls, 1);
      expect(find.text('Bölüm Sıralaması'), findsNothing);
      expect(find.text('Snapshot failed'), findsOneWidget);
    });

    testWidgets('uses single snapshot RPC result at save time', (tester) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotContentVersion: 51,
      );

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: SeriesEpisodesPage(
            seriesId: testSeriesId,
            seriesTitle: 'Test Dizi',
            initialSeries: testSeries(contentVersion: 3),
            episodeRepository: episodeRepository,
            mutationRepository: mutationRepository,
          ),
        ),
      );
      await settle(tester);
      final listFetchCallsBeforeOpen = episodeRepository.fetchListCalls;

      await tester.tap(find.text('Sıralamayı Düzenle'));
      await settle(tester);
      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await settle(tester);
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await settle(tester);
      await tester.tap(find.text('Sıralamayı Kaydet'));
      await settle(tester);

      expect(episodeRepository.loadReorderSnapshotCalls, 1);
      expect(episodeRepository.fetchListCalls, listFetchCallsBeforeOpen + 1);
      expect(mutationRepository.reorderCalls, 1);
      expect(mutationRepository.lastReorderExpectedVersion, 51);
    });

    testWidgets('conflict reloads snapshot without replaying save', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository(
        reorderConflictForExpectedVersions: {29},
      );
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotContentVersion: 44,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeReorderPage(
            seriesId: testSeriesId,
            episodes: episodes,
            expectedSeriesVersion: 29,
            mutationRepository: mutationRepository,
            episodeRepository: episodeRepository,
          ),
        ),
      );
      await settle(tester);

      await tester.longPress(find.byIcon(Icons.drag_handle).first);
      await settle(tester);
      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 80),
      );
      await settle(tester);
      await tester.tap(find.text('Sıralamayı Kaydet'));
      await settle(tester);

      expect(mutationRepository.reorderCalls, 1);
      expect(episodeRepository.loadReorderSnapshotCalls, 1);
      expect(find.text('Bölüm Sıralaması'), findsOneWidget);
      expect(
        find.text(ContentErrorMapper.reorderConflictReconciledMessage),
        findsOneWidget,
      );
    });
  });
}
