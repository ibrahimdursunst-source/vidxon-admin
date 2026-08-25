import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/create_episode_input.dart';
import 'package:vidxon_admin/features/episodes/domain/update_episode_input.dart';
import 'package:vidxon_admin/features/series/domain/create_series_input.dart';
import 'package:vidxon_admin/features/series/domain/update_series_input.dart';

void main() {
  group('series content rating RPC params', () {
    test('create sends unspecified rating fields', () {
      final params = buildCreateSeriesRpcParams(
        const CreateSeriesInput(
          title: 'Test',
          slug: 'test',
          posterPath: 'posters/a.jpg',
          status: 'ongoing',
          isFeatured: false,
          isPremium: false,
          categoryIds: [],
        ),
      );

      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isEmpty);
    });

    test('create sends 16+ with descriptors', () {
      final params = buildCreateSeriesRpcParams(
        const CreateSeriesInput(
          title: 'Test',
          slug: 'test',
          posterPath: 'posters/a.jpg',
          status: 'ongoing',
          isFeatured: false,
          isPremium: false,
          categoryIds: [],
          contentAgeRating: 16,
          contentDescriptors: ['profanity', 'mature_themes'],
        ),
      );

      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], [
        'profanity',
        'mature_themes',
      ]);
    });

    test('update clears rating to unspecified with update flag', () {
      final params = buildUpdateSeriesRpcParams(
        const UpdateSeriesInput(
          seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          title: 'Test',
          synopsis: 'A',
          status: 'ongoing',
          isFeatured: false,
          isPremium: false,
          categoryIds: [],
          expectedContentVersion: 2,
          contentAgeRating: null,
          contentDescriptors: [],
        ),
      );

      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isEmpty);
      expect(params['p_update_content_rating'], isTrue);
    });
  });

  group('episode content rating RPC params', () {
    test('create inherits by default', () {
      final params = buildCreateEpisodeRpcParams(
        const CreateEpisodeInput(
          seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          episodeNumber: 1,
          title: 'Pilot',
          isFree: true,
          coinPrice: 0,
        ),
      );

      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isNull);
    });

    test('create override sends age and descriptors', () {
      final params = buildCreateEpisodeRpcParams(
        const CreateEpisodeInput(
          seriesId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          episodeNumber: 1,
          title: 'Pilot',
          isFree: true,
          coinPrice: 0,
          useContentRatingOverride: true,
          contentAgeRating: 18,
          contentDescriptors: ['sexual_content'],
        ),
      );

      expect(params['p_content_age_rating'], 18);
      expect(params['p_content_descriptors'], ['sexual_content']);
    });

    test('update inherit clears override flags', () {
      final params = buildUpdateEpisodeRpcParams(
        const UpdateEpisodeInput(
          episodeId: '11111111-1111-1111-1111-111111111111',
          title: 'Pilot',
          synopsis: '',
          isFree: true,
          coinPrice: 0,
          expectedContentVersion: 1,
          useContentRatingOverride: false,
        ),
      );

      expect(params['p_clear_content_rating_override'], isTrue);
      expect(params['p_apply_content_rating_override'], isFalse);
      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isNull);
    });

    test('update override applies age and descriptors', () {
      final params = buildUpdateEpisodeRpcParams(
        const UpdateEpisodeInput(
          episodeId: '11111111-1111-1111-1111-111111111111',
          title: 'Pilot',
          synopsis: '',
          isFree: true,
          coinPrice: 0,
          expectedContentVersion: 1,
          useContentRatingOverride: true,
          contentAgeRating: null,
          contentDescriptors: ['violence'],
        ),
      );

      expect(params['p_clear_content_rating_override'], isFalse);
      expect(params['p_apply_content_rating_override'], isTrue);
      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], ['violence']);
    });

    test('update age-only override preserves NULL descriptors', () {
      final params = buildUpdateEpisodeRpcParams(
        const UpdateEpisodeInput(
          episodeId: '11111111-1111-1111-1111-111111111111',
          title: 'Pilot',
          synopsis: '',
          isFree: true,
          coinPrice: 0,
          expectedContentVersion: 1,
          useContentRatingOverride: true,
          contentAgeRating: 16,
          contentDescriptors: null,
        ),
      );

      expect(params['p_apply_content_rating_override'], isTrue);
      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isNull);
    });

    test('update explicit empty descriptors sends [] not null', () {
      final params = buildUpdateEpisodeRpcParams(
        const UpdateEpisodeInput(
          episodeId: '11111111-1111-1111-1111-111111111111',
          title: 'Pilot',
          synopsis: '',
          isFree: true,
          coinPrice: 0,
          expectedContentVersion: 1,
          useContentRatingOverride: true,
          contentAgeRating: 16,
          contentDescriptors: [],
        ),
      );

      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isEmpty);
      expect(params['p_content_descriptors'], isNot(isNull));
    });
  });
}
