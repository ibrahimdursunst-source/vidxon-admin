import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_preview_dialog.dart';

import '../../content/content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('EpisodePreviewDialog lifecycle', () {
    Future<FakeEpisodePreviewRepository> openDialog(
      WidgetTester tester, {
      required AdminEpisode episode,
      required String videoSource,
    }) async {
      final repository = FakeEpisodePreviewRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  showEpisodePreviewDialog(
                    context: context,
                    episode: episode,
                    videoSource: videoSource,
                    repository: repository,
                  );
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      return repository;
    }

    testWidgets('requests preview url with episodeId and videoSource only', (
      tester,
    ) async {
      final repository = await openDialog(
        tester,
        episode: testEpisode(
          id: testEpisodeId1,
          streamStatus: CloudflareStreamStatus.ready,
        ),
        videoSource: 'active',
      );
      await tester.pumpAndSettle();

      expect(repository.callCount, 1);
      expect(repository.lastEpisodeId, testEpisodeId1);
      expect(repository.lastVideoSource, 'active');
    });

    testWidgets('closing dialog clears player and reopen requests new url', (
      tester,
    ) async {
      final repository = FakeEpisodePreviewRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  showEpisodePreviewDialog(
                    context: context,
                    episode: testEpisode(
                      streamStatus: CloudflareStreamStatus.ready,
                    ),
                    videoSource: 'active',
                    repository: repository,
                  );
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();
      expect(repository.callCount, 1);

      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      expect(repository.callCount, 2);
    });

    testWidgets('processing pending video does not call repository', (
      tester,
    ) async {
      final repository = await openDialog(
        tester,
        episode: testEpisode(
          pendingStatus: CloudflareStreamStatus.processing,
        ),
        videoSource: 'pending',
      );
      await tester.pumpAndSettle();

      expect(repository.callCount, 0);
      expect(
        find.text('Bekleyen video henüz önizlemeye hazır değil.'),
        findsOneWidget,
      );
    });

    testWidgets('pending ready sends pending videoSource', (tester) async {
      final repository = await openDialog(
        tester,
        episode: testEpisode(
          pendingStatus: CloudflareStreamStatus.ready,
        ),
        videoSource: 'pending',
      );
      await tester.pumpAndSettle();

      expect(repository.callCount, 1);
      expect(repository.lastVideoSource, 'pending');
    });
  });
}
