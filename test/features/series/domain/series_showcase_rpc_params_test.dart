import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidxon_admin/features/content/data/content_errors.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';
import 'package:vidxon_admin/features/series/domain/series_mutation_results.dart';
import 'package:vidxon_admin/features/series/domain/update_series_input.dart';

import '../../content/content_test_helpers.dart';

void main() {
  test('admin_set_series_showcase_v1 params match the backend contract', () {
    final params = buildSetSeriesShowcaseRpcParams(
      seriesId: testSeriesId,
      isShowcase: true,
      expectedContentVersion: 7,
      showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
    );

    expect(params.keys, [
      'p_series_id',
      'p_is_showcase',
      'p_showcase_landscape_path',
      'p_expected_content_version',
    ]);
    expect(params['p_series_id'], testSeriesId);
    expect(params['p_is_showcase'], isTrue);
    expect(params['p_expected_content_version'], 7);
    expect(
      params['p_showcase_landscape_path'],
      'posters/series/$testSeriesId/land.webp',
    );
  });

  test('empty landscape path is sent as blank so backend keeps the stored path', () {
    final params = buildSetSeriesShowcaseRpcParams(
      seriesId: testSeriesId,
      isShowcase: false,
      expectedContentVersion: 3,
    );

    expect(params['p_is_showcase'], isFalse);
    expect(params['p_showcase_landscape_path'], '');
  });

  test('repository calls admin_set_series_showcase_v1', () {
    final source = File(
      'lib/features/series/data/series_mutation_repository.dart',
    ).readAsStringSync();
    expect(source, contains("rpcName: 'admin_set_series_showcase_v1'"));
    expect(source, contains('buildSetSeriesShowcaseRpcParams'));
  });

  test('series list/detail select includes showcase columns', () {
    final source = File(
      'lib/features/series/data/series_repository.dart',
    ).readAsStringSync();
    expect(source, contains('showcase_landscape_path'));
    expect(source, contains('is_showcase'));
  });

  test('fromMap loads showcase without changing poster', () {
    final series = AdminSeries.fromMap({
      'id': testSeriesId,
      'title': 'Dizi',
      'slug': 'dizi',
      'synopsis': '',
      'poster_path': 'posters/series/$testSeriesId/portrait.png',
      'showcase_landscape_path': 'posters/series/$testSeriesId/land.webp',
      'is_showcase': true,
      'status': 'ongoing',
      'is_published': false,
      'is_archived': false,
      'content_version': 4,
    }, episodeCount: 0);

    expect(series.posterPath, 'posters/series/$testSeriesId/portrait.png');
    expect(series.showcaseLandscapePath, 'posters/series/$testSeriesId/land.webp');
    expect(series.isShowcase, isTrue);
    expect(series.hasShowcaseLandscape, isTrue);
  });

  test('poster and landscape object keys cannot collide', () {
    const poster = 'posters/series/$testSeriesId/upload-1.png';
    const landscape = 'posters/series/$testSeriesId/upload-2.png';
    const prefix = 'posters/series/$testSeriesId/';

    expect(poster.startsWith(prefix), isTrue);
    expect(landscape.startsWith(prefix), isTrue);
    expect(poster, isNot(landscape));
    expect(poster.endsWith('/'), isFalse);
    expect(landscape.endsWith('/'), isFalse);
  });

  test('showcase applyTo does not change poster and stores returned version', () {
    final series = testSeries(
      contentVersion: 4,
      posterPath: 'posters/series/$testSeriesId/portrait.png',
      showcaseLandscapePath: 'posters/series/$testSeriesId/old-land.png',
      isShowcase: false,
    );
    final updated = SeriesShowcaseResult(
      seriesId: testSeriesId,
      isShowcase: true,
      showcaseLandscapePath: 'posters/series/$testSeriesId/new-land.png',
      contentVersion: 5,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    ).applyTo(series);

    expect(updated.posterPath, series.posterPath);
    expect(updated.showcaseLandscapePath, 'posters/series/$testSeriesId/new-land.png');
    expect(updated.isShowcase, isTrue);
    expect(updated.contentVersion, 5);
  });

  test('disable applyTo keeps landscape when RPC omits a replacement path', () {
    final series = testSeries(
      contentVersion: 4,
      posterPath: 'posters/series/$testSeriesId/portrait.png',
      showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
      isShowcase: true,
    );
    final updated = SeriesShowcaseResult(
      seriesId: testSeriesId,
      isShowcase: false,
      contentVersion: 5,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
    ).applyTo(series);

    expect(updated.isShowcase, isFalse);
    expect(updated.showcaseLandscapePath, 'posters/series/$testSeriesId/land.webp');
    expect(updated.posterPath, series.posterPath);
    expect(updated.contentVersion, 5);
  });

  test('poster replacement copyWith does not change landscape', () {
    final series = testSeries(
      posterPath: 'posters/series/$testSeriesId/portrait.png',
      showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
      isShowcase: true,
    );
    final updated = series.copyWith(
      posterPath: 'posters/series/$testSeriesId/new-portrait.png',
      contentVersion: 6,
    );

    expect(updated.posterPath, 'posters/series/$testSeriesId/new-portrait.png');
    expect(updated.showcaseLandscapePath, 'posters/series/$testSeriesId/land.webp');
    expect(updated.isShowcase, isTrue);
  });

  test('metadata save applyTo preserves showcase fields', () {
    final series = testSeries(
      title: 'Once',
      contentVersion: 2,
      posterPath: 'posters/series/$testSeriesId/portrait.png',
      showcaseLandscapePath: 'posters/series/$testSeriesId/land.webp',
      isShowcase: true,
    );
    final updated = SeriesUpdateResult(
      seriesId: testSeriesId,
      title: 'Once',
      synopsis: 'Synopsis',
      slug: 'test-dizi',
      status: 'ongoing',
      isPublished: false,
      posterPath: 'posters/series/$testSeriesId/portrait.png',
      contentVersion: 3,
      updatedAt: DateTime.utc(2026, 8, 1, 12),
      isArchived: false,
    ).applyTo(series);

    expect(updated.contentVersion, 3);
    expect(updated.showcaseLandscapePath, series.showcaseLandscapePath);
    expect(updated.isShowcase, isTrue);
    expect(updated.posterPath, series.posterPath);
  });

  test('showcase missing landscape maps to a stable Admin message', () {
    final mapped = ContentErrorMapper.fromPostgrest(
      const PostgrestException(
        message: 'Showcase landscape path is required',
        code: '22023',
      ),
    );
    expect(mapped.message, 'Vitrinde göstermek için yatay vitrin görseli yükleyin.');
    expect(mapped.message.toLowerCase(), isNot(contains('sqlstate')));
    expect(mapped.message.toLowerCase(), isNot(contains('22023')));
  });

  test('unknown backend errors are not leaked raw', () {
    final mapped = ContentErrorMapper.fromPostgrest(
      const PostgrestException(
        message: 'SQLSTATE 23514 check constraint failed on series',
        code: '23514',
      ),
    );
    expect(mapped.message, 'İşlem tamamlanamadı. Lütfen tekrar deneyin.');
    expect(mapped.message.toLowerCase(), isNot(contains('sqlstate')));
    expect(mapped.message.toLowerCase(), isNot(contains('23514')));
  });
}
