import 'package:supabase_flutter/supabase_flutter.dart';

import '../../episodes/data/episode_repository.dart';
import '../domain/admin_series.dart';

class SeriesRepository {
  SeriesRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  static const _seriesSelect = '''
    id,
    title,
    slug,
    synopsis,
    poster_path,
    status,
    is_published,
    is_archived,
    archived_at,
    content_version,
    is_featured,
    is_premium,
    total_views,
    qualified_views_total,
    content_age_rating,
    content_descriptors,
    created_at,
    updated_at,
    series_categories (
      category_id,
      categories (
        id,
        name
      )
    )
  ''';

  Future<List<AdminSeries>> fetchAll() async {
    final response = await _resolvedClient
        .from('series')
        .select(_seriesSelect)
        .order('updated_at', ascending: false);

    final rows = response as List<dynamic>;
    final counts = await Future.wait(
      rows.map((row) {
        final map = row as Map<String, dynamic>;
        return _countEpisodesForSeries(map['id'].toString());
      }),
    );

    return [
      for (var i = 0; i < rows.length; i++)
        AdminSeries.fromMap(
          rows[i] as Map<String, dynamic>,
          episodeCount: counts[i],
        ),
    ];
  }

  Future<AdminSeries> fetchById(String seriesId) async {
    final response = await _resolvedClient
        .from('series')
        .select(_seriesSelect)
        .eq('id', seriesId)
        .maybeSingle();

    if (response == null) {
      throw StateError('Series not found');
    }

    final episodeCount = await _countEpisodesForSeries(seriesId);

    return AdminSeries.fromMap(response, episodeCount: episodeCount);
  }

  Future<int> _countEpisodesForSeries(String seriesId) async {
    final response = await _resolvedClient
        .from('episodes')
        .select(EpisodeRepository.adminEpisodeCountColumn)
        .eq('series_id', seriesId)
        .count(CountOption.exact);

    return response.count;
  }
}
