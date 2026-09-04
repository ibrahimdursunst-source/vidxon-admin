import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/data/episode_media_tracks_repository.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/domain/episode_media_tracks.dart';
import 'package:vidxon_admin/features/episodes/presentation/episode_media_tracks_page.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';

import '../../content/content_test_helpers.dart';

class _FakeMediaTracksRepository extends EpisodeMediaTracksRepository {
  _FakeMediaTracksRepository(this.snapshot) : super(client: null);

  final EpisodeMediaTracksSnapshot snapshot;
  int listCount = 0;

  @override
  Future<EpisodeMediaTracksSnapshot> listTracks(String episodeId) async {
    listCount += 1;
    return snapshot;
  }
}

void main() {
  testWidgets('EpisodeMediaTracksPage smoke renders sections', (tester) async {
    final episode = AdminEpisode.fromMap({
      'id': testEpisodeId1,
      'series_id': testSeriesId,
      'episode_number': 1,
      'title': 'Bölüm 1',
      'synopsis': '',
      'cloudflare_stream_status': 'ready',
      'duration_seconds': 120,
      'original_audio_locale': 'tr',
      'is_free': true,
      'coin_price': 0,
      'is_published': false,
      'is_archived': false,
      'content_version': 2,
      'total_views': 0,
    });

    final repository = _FakeMediaTracksRepository(
      const EpisodeMediaTracksSnapshot(
        originalAudioLocale: 'tr',
        audioTracks: [],
        subtitleTracks: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EpisodeMediaTracksPage(
          episode: episode,
          seriesTitle: 'Test Dizisi',
          repository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ses / Altyazı'), findsOneWidget);
    expect(find.text('Orijinal ses dili'), findsOneWidget);
    expect(find.text('Dublajlar'), findsOneWidget);
    expect(find.text('Altyazılar'), findsOneWidget);
    expect(find.text('Henüz dublaj yok.'), findsOneWidget);
    expect(find.text('Henüz altyazı yok.'), findsOneWidget);
    expect(repository.listCount, 1);
  });

  test('menu shows Ses / Altyazı when stream is ready', () {
    final labels = episodeMenuLabels(
      testEpisode(streamStatus: CloudflareStreamStatus.ready),
    );
    expect(labels, contains('Ses / Altyazı'));
  });

  test('menu hides Ses / Altyazı when stream is not ready', () {
    final labels = episodeMenuLabels(testEpisode());
    expect(labels, isNot(contains('Ses / Altyazı')));
  });
}
