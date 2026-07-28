import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/dashboard_counts.dart';

class DashboardRepository {
  DashboardRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DashboardCounts> fetchCounts() async {
    final results = await Future.wait([
      _client.from('categories').count(CountOption.exact),
      _client.from('series').count(CountOption.exact),
      _client.from('episodes').count(CountOption.exact),
    ]);

    return DashboardCounts(
      categoryCount: results[0],
      seriesCount: results[1],
      episodeCount: results[2],
    );
  }
}
