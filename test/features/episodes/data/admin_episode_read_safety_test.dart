import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/data/episode_repository.dart';

void main() {
  final libDir = Directory('lib');
  final libSources = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  group('Admin episode read safety', () {
    test('lib/ never references raw Cloudflare Stream UID columns', () {
      const forbiddenColumns = [
        'cloudflare_stream_uid',
        'cloudflare_stream_pending_uid',
      ];

      for (final file in libSources) {
        final content = file.readAsStringSync();
        for (final column in forbiddenColumns) {
          expect(
            content.contains(column),
            isFalse,
            reason: '${file.path} must not reference $column',
          );
        }
      }
    });

    test('canonical admin episode select excludes raw Stream UID columns', () {
      const forbiddenColumns = [
        'cloudflare_stream_uid',
        'cloudflare_stream_pending_uid',
      ];

      for (final column in forbiddenColumns) {
        expect(EpisodeRepository.adminEpisodeSelect.contains(column), isFalse);
      }

      expect(EpisodeRepository.adminEpisodeSelect, contains('id'));
      expect(EpisodeRepository.adminEpisodeSelect, isNot(contains('*')));
    });

    test('dashboard episode count uses explicit safe column select', () {
      final content = File(
        'lib/features/dashboard/data/dashboard_repository.dart',
      ).readAsStringSync();

      expect(content, contains("from('episodes')"));
      expect(
        content,
        contains('.select(EpisodeRepository.adminEpisodeCountColumn)'),
      );
      expect(content, contains('.count(CountOption.exact)'));
      expect(
        RegExp(r"from\('episodes'\)\.count\(").hasMatch(content),
        isFalse,
        reason: 'episodes count must not use implicit column projection',
      );
    });

    test(
      'series queries avoid PostgREST aggregates and use safe per-series counts',
      () {
        final content = File(
          'lib/features/series/data/series_repository.dart',
        ).readAsStringSync();

        const forbiddenAggregatePatterns = [
          'episodes(count',
          'id.count()',
          'count()',
          '.sum()',
          '.avg()',
          '.max()',
          '.min()',
        ];

        for (final pattern in forbiddenAggregatePatterns) {
          expect(
            content.contains(pattern),
            isFalse,
            reason:
                'series repository must not use PostgREST aggregate: $pattern',
          );
        }

        expect(content, isNot(contains('episodes(')));
        expect(content, contains('_countEpisodesForSeries'));
        expect(content, contains("from('episodes')"));
        expect(
          content,
          contains('.select(EpisodeRepository.adminEpisodeCountColumn)'),
        );
        expect(content, contains(".eq('series_id', seriesId)"));
        expect(content, contains('.count(CountOption.exact)'));
        expect(content, contains('response.count'));
      },
    );

    test('episode repository reads use explicit safe column list', () {
      final content = File(
        'lib/features/episodes/data/episode_repository.dart',
      ).readAsStringSync();

      expect(content, contains('.select(adminEpisodeSelect)'));
      expect(
        RegExp(r"from\('episodes'\)\s*\n\s*\.select\(\)").hasMatch(content),
        isFalse,
      );
      expect(content, isNot(contains(".select('*')")));
      expect(content, isNot(contains('.select("*")')));
    });
  });
}
