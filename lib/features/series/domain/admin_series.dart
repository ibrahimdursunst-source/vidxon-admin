class AdminSeries {
  const AdminSeries({
    required this.id,
    required this.title,
    required this.slug,
    required this.synopsis,
    required this.posterPath,
    required this.isPublished,
    required this.totalViews,
    required this.categories,
    required this.episodeCount,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String slug;
  final String synopsis;
  final String posterPath;
  final bool isPublished;
  final int totalViews;
  final List<String> categories;
  final int episodeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminSeries.fromMap(Map<String, dynamic> map) {
    return AdminSeries(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      synopsis: map['synopsis']?.toString() ?? '',
      posterPath: map['poster_path']?.toString() ?? '',
      isPublished: map['is_published'] == true,
      totalViews: _parseInt(map['total_views']),
      categories: _parseCategories(map['series_categories']),
      episodeCount: _parseEpisodeCount(map['episodes']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static List<String> _parseCategories(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final categories = <String>[];

    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final category = item['categories'];
      if (category is Map<String, dynamic>) {
        final name = category['name']?.toString();
        if (name != null && name.isNotEmpty) {
          categories.add(name);
        }
      }
    }

    return categories;
  }

  static int _parseEpisodeCount(dynamic value) {
    if (value is! List || value.isEmpty) {
      return 0;
    }

    final first = value.first;
    if (first is Map<String, dynamic>) {
      return _parseInt(first['count']);
    }

    return 0;
  }
}
