import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/dashboard_counts.dart';

class DashboardRepository {
  DashboardRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<DashboardCounts> fetchCounts() async {
    final results = await Future.wait([
      _resolvedClient.from('categories').count(CountOption.exact),
      _resolvedClient.from('series').count(CountOption.exact),
      _resolvedClient.from('episodes').count(CountOption.exact),
    ]);

    return DashboardCounts(
      categoryCount: results[0],
      seriesCount: results[1],
      episodeCount: results[2],
    );
  }
}
