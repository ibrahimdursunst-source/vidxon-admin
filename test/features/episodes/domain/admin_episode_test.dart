import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';

void main() {
  group('AdminEpisode.fromMap', () {
    test('parses full episode row', () {
      final episode = AdminEpisode.fromMap({
        'id': '11111111-1111-1111-1111-111111111111',
        'series_id': '22222222-2222-2222-2222-222222222222',
        'episode_number': 3,
        'title': ' Pilot ',
        'synopsis': 'Açıklama',
        'thumbnail_path': 'thumbs/a.jpg',
        'cloudflare_stream_uid': 'stream-123',
        'cloudflare_stream_status': 'ready',
        'cloudflare_stream_last_checked_at': '2026-07-29T12:00:00.000Z',
        'duration_seconds': 120,
        'is_free': false,
        'coin_price': 5,
        'is_published': true,
        'total_views': 42,
        'release_at': '2026-07-29T10:30:00.000Z',
        'created_at': '2026-07-28T08:00:00.000Z',
        'updated_at': '2026-07-28T09:00:00.000Z',
      });

      expect(episode.id, '11111111-1111-1111-1111-111111111111');
      expect(episode.seriesId, '22222222-2222-2222-2222-222222222222');
      expect(episode.episodeNumber, 3);
      expect(episode.title, 'Pilot');
      expect(episode.hasVideo, isTrue);
      expect(episode.cloudflareStreamStatus, CloudflareStreamStatus.ready);
      expect(episode.cloudflareStreamLastCheckedAt?.isUtc, isTrue);
      expect(episode.coinPrice, 5);
      expect(episode.releaseAt?.isUtc, isTrue);
    });

    test('parses nullable release_at as null', () {
      final episode = AdminEpisode.fromMap({
        'id': '11111111-1111-1111-1111-111111111111',
        'series_id': '22222222-2222-2222-2222-222222222222',
        'episode_number': 1,
        'title': 'Bölüm 1',
        'synopsis': '',
        'thumbnail_path': null,
        'cloudflare_stream_uid': null,
        'duration_seconds': null,
        'is_free': true,
        'coin_price': 0,
        'is_published': false,
        'total_views': 0,
        'release_at': null,
        'created_at': '2026-07-28T08:00:00.000Z',
        'updated_at': '2026-07-28T09:00:00.000Z',
      });

      expect(episode.releaseAt, isNull);
      expect(episode.hasVideo, isFalse);
      expect(episode.cloudflareStreamStatus, CloudflareStreamStatus.none);
    });

    test('throws on unknown cloudflare stream status', () {
      expect(
        () => AdminEpisode.fromMap({
          'id': '11111111-1111-1111-1111-111111111111',
          'series_id': '22222222-2222-2222-2222-222222222222',
          'episode_number': 1,
          'title': 'Bölüm 1',
          'synopsis': '',
          'cloudflare_stream_status': 'unexpected',
          'is_free': true,
          'coin_price': 0,
          'is_published': false,
          'total_views': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when required fields are missing', () {
      expect(
        () => AdminEpisode.fromMap({
          'id': '',
          'series_id': '22222222-2222-2222-2222-222222222222',
          'episode_number': 1,
          'title': 'Bölüm',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('compareEpisodesByNumber', () {
    test('sorts by episode number then createdAt', () {
      final episodes = [
        AdminEpisode.fromMap({
          'id': '2',
          'series_id': 's',
          'episode_number': 2,
          'title': 'B2',
          'synopsis': '',
          'is_free': true,
          'coin_price': 0,
          'is_published': false,
          'total_views': 0,
          'created_at': '2026-07-28T10:00:00.000Z',
        }),
        AdminEpisode.fromMap({
          'id': '1',
          'series_id': 's',
          'episode_number': 1,
          'title': 'B1',
          'synopsis': '',
          'is_free': true,
          'coin_price': 0,
          'is_published': false,
          'total_views': 0,
          'created_at': '2026-07-28T11:00:00.000Z',
        }),
      ]..sort(compareEpisodesByNumber);

      expect(episodes.first.episodeNumber, 1);
      expect(episodes.last.episodeNumber, 2);
    });
  });
}
