import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';

import '../../content/content_test_helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  while (tester.takeException() != null) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('SeriesEpisodesPage lifecycle confirm', () {
    Future<void> pumpEpisodes(
      WidgetTester tester,
      FakeEpisodeRepository repository, {
      bool parentSeriesArchived = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeriesEpisodesPage(
            seriesId: testSeriesId,
            seriesTitle: 'Test Dizi',
            episodeRepository: repository,
            isSeriesArchived: parentSeriesArchived,
          ),
        ),
      );
      await _settle(tester);
    }

    Future<void> openEpisodeMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await _settle(tester);
    }

    testWidgets('cancel publish does not call repository', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      ]);

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);
      await tester.tap(find.text('Yayınla'));
      await _settle(tester);
      await tester.tap(find.text('Vazgeç'));
      await _settle(tester);

      expect(repository.publishCalls, 0);
    });

    testWidgets('confirm publish calls repository once', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
          contentVersion: 2,
        ),
      ]);

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);
      await tester.tap(find.text('Yayınla'));
      await _settle(tester);
      await tester.tap(find.text('Yayınla', skipOffstage: false).last);
      await _settle(tester);

      expect(repository.publishCalls, 1);
      expect(repository.lastPublishExpectedVersion, 2);
    });

    testWidgets('processing video hides publish action', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.processing,
        ),
      ]);

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);

      expect(find.text('Yayınla'), findsNothing);
      expect(repository.publishCalls, 0);
    });

    testWidgets('no video hides publish action', (tester) async {
      final repository = FakeEpisodeRepository([testEpisode()]);

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);

      expect(find.text('Yayınla'), findsNothing);
    });

    testWidgets('archived episode shows only restore', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(isArchived: true, streamUid: 'stream-1'),
      ]);

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);

      expect(find.text('Geri Yükle'), findsOneWidget);
      expect(find.text('Yayınla'), findsNothing);
    });

    testWidgets('archived parent hides publish action', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      ]);

      await pumpEpisodes(tester, repository, parentSeriesArchived: true);
      await openEpisodeMenu(tester);

      expect(find.text('Yayınla'), findsNothing);
    });

    testWidgets('publish conflict reloads episode without success toast', (
      tester,
    ) async {
      final repository =
          FakeEpisodeRepository([
              testEpisode(
                id: testEpisodeId1,
                streamUid: 'stream-1',
                streamStatus: CloudflareStreamStatus.ready,
                contentVersion: 2,
                title: 'Before',
              ),
            ])
            ..publishError = const ContentException(
              message: ContentErrorMapper.conflictMessage,
              kind: ContentFailureKind.conflict,
              isConflict: true,
            );

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);
      await tester.tap(find.text('Yayınla'));
      await _settle(tester);
      await tester.tap(find.text('Yayınla', skipOffstage: false).last);
      await _settle(tester);

      expect(repository.publishCalls, 1);
      expect(repository.fetchByIdCalls, greaterThanOrEqualTo(1));
      expect(find.text('Bölüm yayınlandı.'), findsNothing);
    });

    testWidgets('publish busy blocks double submit', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      ])..publishDelay = Completer<void>();

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);
      await tester.tap(find.text('Yayınla'));
      await _settle(tester);
      await tester.tap(find.text('Yayınla', skipOffstage: false).last);
      await tester.pump();

      expect(repository.publishCalls, 1);

      repository.publishDelay!.complete();
      await _settle(tester);

      expect(repository.publishCalls, 1);
    });

    testWidgets('restore does not auto publish episode', (tester) async {
      final repository = FakeEpisodeRepository([
        testEpisode(isArchived: true, streamUid: 'stream-1'),
      ]);

      await pumpEpisodes(tester, repository);
      await openEpisodeMenu(tester);
      await tester.tap(find.text('Geri Yükle'));
      await _settle(tester);
      await tester.tap(find.text('Geri Yükle', skipOffstage: false).last);
      await _settle(tester);

      expect(repository.restoreCalls, 1);
      expect(find.text('Yayında'), findsNothing);
    });
  });
}
