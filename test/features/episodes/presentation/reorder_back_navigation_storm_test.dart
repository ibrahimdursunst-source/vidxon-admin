import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<void> pumpEpisodesHost(
    WidgetTester tester, {
    required TrackingSeriesMutationRepository mutationRepository,
    required FakeEpisodeRepository episodeRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (context) => SeriesEpisodesPage(
                          seriesId: testSeriesId,
                          seriesTitle: 'Test Dizi',
                          initialSeries: testSeries(contentVersion: 29),
                          episodeRepository: episodeRepository,
                          mutationRepository: mutationRepository,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Episodes'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Open Episodes'));
    await settle(tester);
  }

  group('Reorder back navigation storm regression', () {
    testWidgets('open → reorder → save → back keeps reorder RPC count at 1', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotContentVersion: 30,
      );

      await pumpEpisodesHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );

      await tester.tap(find.text('Sıralamayı Düzenle'));
      await settle(tester);
      await dragAndSave(tester);

      expect(mutationRepository.reorderCalls, 1);
      expect(find.text('Bölümler'), findsOneWidget);

      await tester.pageBack();
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(mutationRepository.reorderCalls, 1);
    });

    testWidgets('back is blocked while save is in flight and completes once', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository()
        ..reorderDelay = Completer<void>();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotContentVersion: 29,
      );

      await pumpEpisodesHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );

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
      await tester.pump();

      expect(mutationRepository.reorderCalls, 1);
      expect(find.text('Bölüm Sıralaması'), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      expect(find.text('Bölüm Sıralaması'), findsOneWidget);

      mutationRepository.reorderDelay!.complete();
      await settle(tester);

      expect(mutationRepository.reorderCalls, 1);
      expect(find.text('Bölümler'), findsOneWidget);

      await tester.pageBack();
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(mutationRepository.reorderCalls, 1);
    });

    testWidgets('double tap on reorder opens only one reorder route', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotContentVersion: 29,
      );

      await pumpEpisodesHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );

      await tester.tap(find.text('Sıralamayı Düzenle'));
      await tester.pump();
      await tester.tap(find.text('Sıralamayı Düzenle'));
      await settle(tester);

      expect(find.text('Bölüm Sıralaması'), findsOneWidget);
      expect(mutationRepository.reorderCalls, 0);
    });

    testWidgets('enter episodes and back without reorder sends zero RPCs', (
      tester,
    ) async {
      final mutationRepository = TrackingSeriesMutationRepository();
      final episodes = [
        testEpisode(id: testEpisodeId1, episodeNumber: 1, title: 'Bir'),
        testEpisode(id: testEpisodeId2, episodeNumber: 2, title: 'İki'),
      ];
      final episodeRepository = FakeEpisodeRepository(
        episodes,
        reorderSnapshotContentVersion: 29,
      );

      await pumpEpisodesHost(
        tester,
        mutationRepository: mutationRepository,
        episodeRepository: episodeRepository,
      );

      await tester.pageBack();
      await settle(tester);
      await tester.pumpAndSettle();

      expect(mutationRepository.reorderCalls, 0);
    });
  });
}
