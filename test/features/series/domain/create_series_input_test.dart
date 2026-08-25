import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/series/domain/create_series_input.dart';

void main() {
  group('buildCreateSeriesRpcParams', () {
    test('uses objectPath for p_poster_path and not publicUrl', () {
      const objectPath = 'posters/2026/07/series-id.jpg';
      const publicUrl =
          'https://media.vidxon.com/posters/2026/07/series-id.jpg';

      final params = buildCreateSeriesRpcParams(
        const CreateSeriesInput(
          title: 'Test Dizi',
          slug: 'test-dizi',
          posterPath: objectPath,
          status: 'ongoing',
          isFeatured: false,
          isPremium: false,
          categoryIds: ['11111111-1111-1111-1111-111111111111'],
        ),
      );

      expect(params['p_poster_path'], objectPath);
      expect(params['p_poster_path'], isNot(publicUrl));
      expect(params['p_backdrop_path'], isNull);
      expect(params['p_status'], 'ongoing');
      expect(params['p_is_published'], isFalse);
      expect(params['p_category_ids'], [
        '11111111-1111-1111-1111-111111111111',
      ]);
      expect(params['p_content_age_rating'], isNull);
      expect(params['p_content_descriptors'], isEmpty);
    });

    test('sends null synopsis and release date when empty', () {
      final params = buildCreateSeriesRpcParams(
        const CreateSeriesInput(
          title: 'Test Dizi',
          slug: 'test-dizi',
          posterPath: 'posters/a.jpg',
          synopsis: '   ',
          status: 'ongoing',
          isFeatured: false,
          isPremium: false,
          releaseDate: '',
          categoryIds: [],
        ),
      );

      expect(params['p_synopsis'], isNull);
      expect(params['p_release_date'], isNull);
      expect(params['p_is_published'], isFalse);
    });
  });
}
