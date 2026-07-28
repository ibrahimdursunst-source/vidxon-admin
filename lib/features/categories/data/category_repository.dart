import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_category.dart';

class CategoryRepository {
  CategoryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AdminCategory>> fetchAll() async {
    final response = await _client
        .from('categories')
        .select('id, name')
        .order('name', ascending: true);

    final rows = response as List<dynamic>;

    return rows
        .map((row) => AdminCategory.fromMap(row as Map<String, dynamic>))
        .where((category) => category.id.isNotEmpty && category.name.isNotEmpty)
        .toList();
  }
}
