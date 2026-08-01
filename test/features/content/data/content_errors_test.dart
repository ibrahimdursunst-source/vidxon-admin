import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/series/domain/update_series_input.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ContentErrorMapper', () {
    test('maps conflict error from SQLSTATE 40001', () {
      final error = ContentErrorMapper.fromPostgrest(
        const PostgrestException(
          message: 'Content was modified by another admin',
          code: '40001',
        ),
      );

      expect(error.isConflict, isTrue);
      expect(error.message, ContentErrorMapper.conflictMessage);
    });

    test('maps create unpublished validation', () {
      final error = ContentErrorMapper.fromPostgrest(
        const PostgrestException(
          message: 'Series must be created as unpublished',
          code: 'P0001',
        ),
      );

      expect(error.kind, ContentFailureKind.validation);
    });
  });

  group('buildReorderSeriesEpisodesRpcParams', () {
    test('sends complete ordered episode ids and series version', () {
      final params = buildReorderSeriesEpisodesRpcParams(
        seriesId: '11111111-1111-1111-1111-111111111111',
        orderedEpisodeIds: const [
          'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        ],
        expectedSeriesVersion: 7,
      );

      expect(params['p_series_id'], '11111111-1111-1111-1111-111111111111');
      expect(params['p_ordered_episode_ids'], hasLength(2));
      expect(params['p_expected_series_version'], 7);
    });
  });
}
