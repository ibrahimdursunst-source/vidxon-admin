import 'package:supabase_flutter/supabase_flutter.dart';

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
    created_at,
    updated_at,
    series_categories (
      category_id,
      categories (
        id,
        name
      )
    ),
    episodes(count)
  ''';

  Future<List<AdminSeries>> fetchAll() async {
    final response = await _resolvedClient
        .from('series')
        .select(_seriesSelect)
        .order('updated_at', ascending: false);

    final rows = response as List<dynamic>;

    return rows
        .map((row) => AdminSeries.fromMap(row as Map<String, dynamic>))
        .toList();
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

    return AdminSeries.fromMap(response);
  }
}
