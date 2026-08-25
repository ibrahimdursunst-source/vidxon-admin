import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';

void main() {
  test('AdminEpisode parses qualified_views_total', () {
    final episode = AdminEpisode.fromMap({
      'id': '11111111-1111-1111-1111-111111111111',
      'series_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'episode_number': 1,
      'title': 'Bölüm 1',
      'synopsis': '',
      'cloudflare_stream_status': 'ready',
      'cloudflare_stream_pending_status': 'none',
      'is_free': true,
      'coin_price': 0,
      'is_published': true,
      'is_archived': false,
      'content_version': 1,
      'total_views': 999,
      'qualified_views_total': 17,
    });

    expect(episode.qualifiedViewsTotal, 17);
    expect(episode.totalViews, 999);
  });

  test('AdminSeries parses qualified_views_total', () {
    final series = AdminSeries.fromMap(
      {
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'title': 'Test',
        'slug': 'test',
        'synopsis': '',
        'poster_path': '',
        'status': 'ongoing',
        'is_published': true,
        'is_archived': false,
        'content_version': 1,
        'total_views': 5000,
        'qualified_views_total': 120,
        'series_categories': const [],
      },
      episodeCount: 3,
    );

    expect(series.qualifiedViewsTotal, 120);
  });

  test('episode form source keeps Nitelikli as read-only Text, not TextFormField', () {
    final source = File(
      'lib/features/episodes/presentation/episode_form_page.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'Nitelikli İzlenme'"));
    expect(source, contains('_ReadOnlyInfo'));
    // No editable binding for qualified views.
    expect(source.contains('qualifiedViewsTotalController'), isFalse);
    expect(
      RegExp(r'TextFormField\([\s\S]{0,200}qualified', caseSensitive: false)
          .hasMatch(source),
      isFalse,
    );
  });
}
