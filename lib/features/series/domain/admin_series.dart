import '../../content_rating/domain/content_rating_catalog.dart';
import '../../content/domain/editorial_copy.dart';

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
    this.qualifiedViewsTotal = 0,
    required this.categories,
    required this.categoryIds,
    required this.episodeCount,
    this.archivedAt,
    this.createdAt,
    this.updatedAt,
    this.isFeatured = false,
    this.isPremium = false,
    this.contentAgeRating,
    this.contentDescriptors = const [],
    this.publishedAt,
    this.originalLocale = 'tr',
    this.translations = const {},
    this.showcaseLandscapePath,
    this.isShowcase = false,
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
  final int qualifiedViewsTotal;
  final List<String> categories;
  final List<String> categoryIds;
  final int episodeCount;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFeatured;
  final bool isPremium;
  final int? contentAgeRating;
  final List<String> contentDescriptors;
  final DateTime? publishedAt;
  final String originalLocale;
  final Map<String, EditorialCopy> translations;
  final String? showcaseLandscapePath;
  final bool isShowcase;

  bool get hasShowcaseLandscape =>
      (showcaseLandscapePath ?? '').trim().isNotEmpty;

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
    int? qualifiedViewsTotal,
    List<String>? categories,
    List<String>? categoryIds,
    int? episodeCount,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFeatured,
    bool? isPremium,
    int? contentAgeRating,
    List<String>? contentDescriptors,
    DateTime? publishedAt,
    String? originalLocale,
    Map<String, EditorialCopy>? translations,
    String? showcaseLandscapePath,
    bool? isShowcase,
    bool clearContentAgeRating = false,
    bool clearPublishedAt = false,
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
      qualifiedViewsTotal: qualifiedViewsTotal ?? this.qualifiedViewsTotal,
      categories: categories ?? this.categories,
      categoryIds: categoryIds ?? this.categoryIds,
      episodeCount: episodeCount ?? this.episodeCount,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isPremium: isPremium ?? this.isPremium,
      contentAgeRating: clearContentAgeRating
          ? null
          : (contentAgeRating ?? this.contentAgeRating),
      contentDescriptors: contentDescriptors ?? this.contentDescriptors,
      publishedAt: clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      originalLocale: originalLocale ?? this.originalLocale,
      translations: translations ?? this.translations,
      showcaseLandscapePath:
          showcaseLandscapePath ?? this.showcaseLandscapePath,
      isShowcase: isShowcase ?? this.isShowcase,
    );
  }

  factory AdminSeries.fromMap(
    Map<String, dynamic> map, {
    required int episodeCount,
  }) {
    final categoryData = _parseCategoryData(map['series_categories']);
    final landscape = map['showcase_landscape_path']?.toString().trim();

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
      qualifiedViewsTotal: _parseInt(map['qualified_views_total']),
      categories: categoryData.names,
      categoryIds: categoryData.ids,
      episodeCount: episodeCount,
      archivedAt: _parseDateTime(map['archived_at']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      isFeatured: map['is_featured'] == true,
      isPremium: map['is_premium'] == true,
      contentAgeRating: ContentRatingCatalog.parseAgeRating(
        map['content_age_rating'],
      ),
      contentDescriptors: ContentRatingCatalog.parseDescriptors(
        map['content_descriptors'],
      ),
      publishedAt: _parseDateTime(map['published_at']),
      originalLocale: map['original_locale']?.toString() ?? 'tr',
      translations: _parseTranslations(map['series_translations']),
      showcaseLandscapePath:
          landscape != null && landscape.isNotEmpty ? landscape : null,
      isShowcase: map['is_showcase'] == true,
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

  static Map<String, EditorialCopy> _parseTranslations(dynamic value) {
    if (value is! List) {
      return const {};
    }
    final translations = <String, EditorialCopy>{};
    for (final item in value) {
      if (item is! Map) {
        continue;
      }
      final row = Map<String, dynamic>.from(item);
      final locale = row['locale']?.toString() ?? '';
      if (locale.isEmpty) {
        continue;
      }
      translations[locale] = EditorialCopy(
        title: row['title']?.toString() ?? '',
        description: row['description']?.toString() ?? '',
      );
    }
    return translations;
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
