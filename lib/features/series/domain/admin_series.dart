class AdminSeries {
  const AdminSeries({
    required this.id,
    required this.title,
    required this.slug,
    required this.synopsis,
    required this.posterPath,
    required this.status,
    required this.isPublished,
    required this.isArchived,
    required this.contentVersion,
    required this.totalViews,
    required this.categories,
    required this.categoryIds,
    required this.episodeCount,
    this.archivedAt,
    this.createdAt,
    this.updatedAt,
    this.isFeatured = false,
    this.isPremium = false,
  });

  final String id;
  final String title;
  final String slug;
  final String synopsis;
  final String posterPath;
  final String status;
  final bool isPublished;
  final bool isArchived;
  final int contentVersion;
  final int totalViews;
  final List<String> categories;
  final List<String> categoryIds;
  final int episodeCount;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFeatured;
  final bool isPremium;

  String get statusLabel => switch (status) {
    'ongoing' => 'Devam Ediyor',
    'completed' => 'Tamamlandı',
    'coming_soon' => 'Yakında',
    _ => status,
  };

  String get publishLabel => isPublished ? 'Yayında' : 'Yayında Değil';

  String get archiveLabel => isArchived ? 'Arşivlenmiş' : 'Aktif';

  AdminSeries copyWith({
    String? title,
    String? slug,
    String? synopsis,
    String? posterPath,
    String? status,
    bool? isPublished,
    bool? isArchived,
    int? contentVersion,
    int? totalViews,
    List<String>? categories,
    List<String>? categoryIds,
    int? episodeCount,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFeatured,
    bool? isPremium,
  }) {
    return AdminSeries(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      synopsis: synopsis ?? this.synopsis,
      posterPath: posterPath ?? this.posterPath,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      contentVersion: contentVersion ?? this.contentVersion,
      totalViews: totalViews ?? this.totalViews,
      categories: categories ?? this.categories,
      categoryIds: categoryIds ?? this.categoryIds,
      episodeCount: episodeCount ?? this.episodeCount,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  factory AdminSeries.fromMap(Map<String, dynamic> map) {
    final categoryData = _parseCategoryData(map['series_categories']);

    return AdminSeries(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      synopsis: map['synopsis']?.toString() ?? '',
      posterPath: map['poster_path']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ongoing',
      isPublished: map['is_published'] == true,
      isArchived: map['is_archived'] == true,
      contentVersion: _parseInt(map['content_version']),
      totalViews: _parseInt(map['total_views']),
      categories: categoryData.names,
      categoryIds: categoryData.ids,
      episodeCount: _parseEpisodeCount(map['episodes']),
      archivedAt: _parseDateTime(map['archived_at']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      isFeatured: map['is_featured'] == true,
      isPremium: map['is_premium'] == true,
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
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static _CategoryData _parseCategoryData(dynamic value) {
    if (value is! List) {
      return const _CategoryData([], []);
    }

    final names = <String>[];
    final ids = <String>[];

    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final categoryId = item['category_id']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        ids.add(categoryId);
      }

      final category = item['categories'];
      if (category is Map<String, dynamic>) {
        final name = category['name']?.toString();
        if (name != null && name.isNotEmpty) {
          names.add(name);
        }

        final nestedId = category['id']?.toString();
        if (nestedId != null &&
            nestedId.isNotEmpty &&
            !ids.contains(nestedId)) {
          ids.add(nestedId);
        }
      }
    }

    return _CategoryData(names, ids);
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

class _CategoryData {
  const _CategoryData(this.names, this.ids);

  final List<String> names;
  final List<String> ids;
}

int parseContentVersion(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
