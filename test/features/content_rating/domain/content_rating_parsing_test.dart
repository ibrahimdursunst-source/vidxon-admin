import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content_rating/domain/content_rating_catalog.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';

void main() {
  group('ContentRatingCatalog', () {
    test('normalizes strong_violence by dropping violence', () {
      expect(
        ContentRatingCatalog.normalizeDescriptors([
          'violence',
          'strong_violence',
          'profanity',
        ]),
        ['strong_violence', 'profanity'],
      );
    });

    test('parses only allowed ages', () {
      expect(ContentRatingCatalog.parseAgeRating(16), 16);
      expect(ContentRatingCatalog.parseAgeRating('18+'), 18);
      expect(ContentRatingCatalog.parseAgeRating(12), isNull);
      expect(ContentRatingCatalog.parseAgeRating(null), isNull);
    });
  });

  group('AdminSeries content rating parsing', () {
    test('parses age and descriptors', () {
      final series = AdminSeries.fromMap({
        'id': 's1',
        'title': 'Dizi',
        'slug': 'dizi',
        'synopsis': 'Açıklama',
        'poster_path': 'p.jpg',
        'status': 'ongoing',
        'is_published': false,
        'is_archived': false,
        'content_version': 1,
        'total_views': 0,
        'content_age_rating': 16,
        'content_descriptors': ['violence', 'profanity'],
        'series_categories': const [],
      }, episodeCount: 0);

      expect(series.contentAgeRating, 16);
      expect(series.contentDescriptors, ['violence', 'profanity']);
    });

    test('defaults unspecified rating and empty descriptors', () {
      final series = AdminSeries.fromMap({
        'id': 's1',
        'title': 'Dizi',
        'slug': 'dizi',
        'synopsis': '',
        'poster_path': '',
        'status': 'ongoing',
        'is_published': false,
        'is_archived': false,
        'content_version': 0,
        'total_views': 0,
        'series_categories': const [],
      }, episodeCount: 0);

      expect(series.contentAgeRating, isNull);
      expect(series.contentDescriptors, isEmpty);
    });
  });

  group('AdminEpisode content rating parsing', () {
    Map<String, dynamic> baseMap() => {
      'id': '11111111-1111-1111-1111-111111111111',
      'series_id': '22222222-2222-2222-2222-222222222222',
      'episode_number': 1,
      'title': 'Bölüm 1',
      'synopsis': '',
      'cloudflare_stream_status': 'none',
      'is_free': true,
      'coin_price': 0,
      'is_published': false,
      'total_views': 0,
    };

    test('inherits when age and descriptors are null', () {
      final episode = AdminEpisode.fromMap(baseMap());
      expect(episode.contentAgeRating, isNull);
      expect(episode.contentDescriptors, isNull);
      expect(episode.hasContentRatingOverride, isFalse);
    });

    test('has override when age is set', () {
      final episode = AdminEpisode.fromMap({
        ...baseMap(),
        'content_age_rating': 18,
      });
      expect(episode.contentAgeRating, 18);
      expect(episode.hasContentRatingOverride, isTrue);
    });

    test('has override when descriptors list is present including empty', () {
      final emptyOverride = AdminEpisode.fromMap({
        ...baseMap(),
        'content_descriptors': <String>[],
      });
      expect(emptyOverride.contentDescriptors, isEmpty);
      expect(emptyOverride.hasContentRatingOverride, isTrue);

      final withDescriptors = AdminEpisode.fromMap({
        ...baseMap(),
        'content_descriptors': ['fear_horror'],
      });
      expect(withDescriptors.contentDescriptors, ['fear_horror']);
      expect(withDescriptors.hasContentRatingOverride, isTrue);
    });
  });
}
