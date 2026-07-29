import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/create_episode_input.dart';
import 'package:vidxon_admin/features/episodes/domain/episode_release_at.dart';
import 'package:vidxon_admin/features/episodes/domain/update_episode_input.dart';

void main() {
  group('validateEpisodeFields', () {
    test('rejects non-positive episode number', () {
      expect(
        validateEpisodeFields(
          episodeNumber: 0,
          title: 'Bölüm',
          isFree: true,
          coinPrice: 0,
          isPublished: false,
        ),
        isNotNull,
      );
    });

    test('rejects empty title', () {
      expect(
        validateEpisodeFields(
          episodeNumber: 1,
          title: '   ',
          isFree: true,
          coinPrice: 0,
          isPublished: false,
        ),
        isNotNull,
      );
    });

    test('rejects negative coin price', () {
      expect(
        validateEpisodeFields(
          episodeNumber: 1,
          title: 'Bölüm',
          isFree: false,
          coinPrice: -1,
          isPublished: false,
        ),
        isNotNull,
      );
    });

    test('rejects free episode with positive coin price', () {
      expect(
        validateEpisodeFields(
          episodeNumber: 1,
          title: 'Bölüm',
          isFree: true,
          coinPrice: 5,
          isPublished: false,
        ),
        isNotNull,
      );
    });

    test('rejects published locked episode with zero coin price', () {
      expect(
        validateEpisodeFields(
          episodeNumber: 1,
          title: 'Bölüm',
          isFree: false,
          coinPrice: 0,
          isPublished: true,
        ),
        isNotNull,
      );
    });

    test('accepts draft locked episode with zero coin price', () {
      expect(
        validateEpisodeFields(
          episodeNumber: 1,
          title: 'Bölüm',
          isFree: false,
          coinPrice: 0,
          isPublished: false,
        ),
        isNull,
      );
    });
  });

  group('normalizeCoinPrice', () {
    test('returns 0 when episode is free', () {
      expect(normalizeCoinPrice(isFree: true, coinPrice: 99), 0);
    });
  });

  group('buildCreateEpisodeRpcParams', () {
    test('uses backend signature keys', () {
      final localRelease = DateTime(2026, 7, 29, 13, 45);

      final params = buildCreateEpisodeRpcParams(
        CreateEpisodeInput(
          seriesId: '22222222-2222-2222-2222-222222222222',
          episodeNumber: 1,
          title: 'Pilot',
          synopsis: 'Açıklama',
          isFree: false,
          coinPrice: 10,
          isPublished: true,
          releaseAtLocal: localRelease,
        ),
      );

      expect(
        params.keys,
        containsAll([
          'p_series_id',
          'p_episode_number',
          'p_title',
          'p_synopsis',
          'p_is_free',
          'p_coin_price',
          'p_is_published',
          'p_release_at',
        ]),
      );
      expect(params['p_coin_price'], 10);
      expect(params['p_release_at'], localRelease.toUtc().toIso8601String());
    });

    test('normalizes free episode coin price to 0', () {
      final params = buildCreateEpisodeRpcParams(
        const CreateEpisodeInput(
          seriesId: '22222222-2222-2222-2222-222222222222',
          episodeNumber: 1,
          title: 'Pilot',
          isFree: true,
          coinPrice: 25,
          isPublished: false,
        ),
      );

      expect(params['p_coin_price'], 0);
    });
  });

  group('buildUpdateEpisodeRpcParams', () {
    test('uses backend signature keys and null release_at', () {
      final params = buildUpdateEpisodeRpcParams(
        const UpdateEpisodeInput(
          episodeId: '11111111-1111-1111-1111-111111111111',
          episodeNumber: 2,
          title: 'Güncel',
          isFree: false,
          coinPrice: 5,
          isPublished: false,
        ),
      );

      expect(
        params.keys,
        containsAll([
          'p_episode_id',
          'p_episode_number',
          'p_title',
          'p_synopsis',
          'p_is_free',
          'p_coin_price',
          'p_is_published',
          'p_release_at',
        ]),
      );
      expect(params['p_release_at'], isNull);
    });
  });

  group('releaseAtLocalToRpcPayload', () {
    test('converts local datetime to UTC ISO-8601', () {
      final local = DateTime(2026, 7, 29, 15, 30);
      final payload = releaseAtLocalToRpcPayload(local);

      expect(payload, local.toUtc().toIso8601String());
      expect(payload, isNotNull);
    });

    test('returns null for missing release date', () {
      expect(releaseAtLocalToRpcPayload(null), isNull);
    });
  });
}
