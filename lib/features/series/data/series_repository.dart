import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_series.dart';

class SeriesRepository {
  SeriesRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _seriesSelect = '''
    id,
    title,
    slug,
    synopsis,
    poster_path,
    is_published,
    total_views,
    created_at,
    updated_at,
    series_categories (
      categories (
        name
      )
    ),
    episodes(count)
  ''';

  Future<List<AdminSeries>> fetchAll() async {
    final response = await _client
        .from('series')
        .select(_seriesSelect)
        .order('updated_at', ascending: false);

    final rows = response as List<dynamic>;

    return rows
        .map((row) => AdminSeries.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
