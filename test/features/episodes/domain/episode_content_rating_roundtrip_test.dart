import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/create_episode_input.dart';
import 'package:vidxon_admin/features/episodes/domain/update_episode_input.dart';

void main() {
  group('episode content rating NULL vs [] round-trip', () {
    Map<String, dynamic> baseMap({
      int? age,
      List<String>? descriptors,
      bool includeDescriptorsKey = true,
    }) {
      final map = <String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'series_id': '22222222-2222-2222-2222-222222222222',
        'episode_number': 1,
        'title': 'Bölüm 1',
        'synopsis': '',
        'cloudflare_stream_status': 'none',
        'is_free': true,
        'coin_price': 0,
        'is_published': false,
        'is_archived': false,
        'content_version': 1,
        'total_views': 0,
        'content_age_rating': age,
      };
      if (includeDescriptorsKey) {
        map['content_descriptors'] = descriptors;
      }
      return map;
    }

    /// Simulates form load + unchanged save payload builders.
    Map<String, dynamic> roundTripUpdate({
      required AdminEpisode episode,
      bool? forceOverride,
      int? forceAge,
      List<String>? forceDescriptors,
      bool clearDescriptorsKey = false,
    }) {
      final useOverride = forceOverride ?? episode.hasContentRatingOverride;
      final age = forceAge ?? episode.contentAgeRating;
      final descriptors = clearDescriptorsKey
          ? null
          : (forceDescriptors ??
                (episode.contentDescriptors == null
                    ? null
                    : List<String>.from(episode.contentDescriptors!)));

      return buildUpdateEpisodeRpcParams(
        UpdateEpisodeInput(
          episodeId: episode.id,
          title: episode.title,
          synopsis: episode.synopsis,
          isFree: episode.isFree,
          coinPrice: episode.coinPrice,
          expectedContentVersion: episode.contentVersion,
          useContentRatingOverride: useOverride,
          contentAgeRating: age,
          contentDescriptors: descriptors,
        ),
      );
    }

    test('CASE A: NULL / NULL inherits both and stays NULL / NULL', () {
      final episode = AdminEpisode.fromMap(baseMap());
      expect(episode.contentAgeRating, isNull);
      expect(episode.contentDescriptors, isNull);
      expect(episode.hasContentRatingOverride, isFalse);

      final params = roundTripUpdate(episode: episode);
      expect(params['p_clear_content_rating_override'], isTrue);
      expect(params['p_apply_content_rating_override'], isFalse);
      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isNull);
    });

    test('CASE B: 16 / NULL age-only override stays 16 / NULL', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 16, includeDescriptorsKey: false),
      );
      expect(episode.contentAgeRating, 16);
      expect(episode.contentDescriptors, isNull);

      final params = roundTripUpdate(episode: episode);
      expect(params['p_clear_content_rating_override'], isFalse);
      expect(params['p_apply_content_rating_override'], isTrue);
      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isNull);
    });

    test('CASE C: 16 / [] explicit empty stays 16 / []', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 16, descriptors: <String>[]),
      );
      expect(episode.contentAgeRating, 16);
      expect(episode.contentDescriptors, isEmpty);
      expect(identical(episode.contentDescriptors, null), isFalse);

      final params = roundTripUpdate(episode: episode);
      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isEmpty);
      expect(params['p_content_descriptors'], isA<List>());
      expect(params['p_content_descriptors'], isNot(isNull));
    });

    test('CASE D: 18 / [violence] stays 18 / [violence]', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 18, descriptors: ['violence']),
      );

      final params = roundTripUpdate(episode: episode);
      expect(params['p_content_age_rating'], 18);
      expect(params['p_content_descriptors'], ['violence']);
    });

    test('CASE E: override OFF clears to series inheritance', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 18, descriptors: ['violence']),
      );

      final params = roundTripUpdate(episode: episode, forceOverride: false);
      expect(params['p_clear_content_rating_override'], isTrue);
      expect(params['p_apply_content_rating_override'], isFalse);
      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isNull);
    });

    test('age-only edit keeps inherited descriptors as NULL', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 13, includeDescriptorsKey: false),
      );

      final params = roundTripUpdate(episode: episode, forceAge: 16);
      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isNull);
    });

    test('explicit empty descriptors remain [] after age edit', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 13, descriptors: <String>[]),
      );

      final params = roundTripUpdate(episode: episode, forceAge: 16);
      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isEmpty);
      expect(params['p_content_descriptors'], isNot(isNull));
    });

    test('switching inherited descriptors to explicit starts as []', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 16, includeDescriptorsKey: false),
      );

      // Form: inherit switch OFF → explicit empty list.
      final params = roundTripUpdate(
        episode: episode,
        forceDescriptors: <String>[],
      );
      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isEmpty);
      expect(params['p_content_descriptors'], isNot(isNull));
    });

    test('editing chips changes inherited -> explicit list', () {
      final episode = AdminEpisode.fromMap(
        baseMap(age: 16, includeDescriptorsKey: false),
      );

      final params = roundTripUpdate(
        episode: episode,
        forceDescriptors: ['violence', 'profanity'],
      );
      expect(params['p_content_descriptors'], ['violence', 'profanity']);
    });

    test('create age-only override sends NULL descriptors', () {
      final params = buildCreateEpisodeRpcParams(
        const CreateEpisodeInput(
          seriesId: '22222222-2222-2222-2222-222222222222',
          episodeNumber: 1,
          title: 'Pilot',
          isFree: true,
          coinPrice: 0,
          useContentRatingOverride: true,
          contentAgeRating: 16,
          contentDescriptors: null,
        ),
      );

      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isNull);
    });

    test('create explicit empty descriptors sends []', () {
      final params = buildCreateEpisodeRpcParams(
        const CreateEpisodeInput(
          seriesId: '22222222-2222-2222-2222-222222222222',
          episodeNumber: 1,
          title: 'Pilot',
          isFree: true,
          coinPrice: 0,
          useContentRatingOverride: true,
          contentAgeRating: 16,
          contentDescriptors: [],
        ),
      );

      expect(params['p_content_age_rating'], 16);
      expect(params['p_content_descriptors'], isEmpty);
      expect(params['p_content_descriptors'], isNot(isNull));
    });

    test('normalizeEpisodeContentDescriptors preserves null vs empty', () {
      expect(normalizeEpisodeContentDescriptors(null), isNull);
      expect(normalizeEpisodeContentDescriptors(const []), isEmpty);
      expect(
        normalizeEpisodeContentDescriptors(const ['violence', 'violence']),
        ['violence'],
      );
    });
  });
}
