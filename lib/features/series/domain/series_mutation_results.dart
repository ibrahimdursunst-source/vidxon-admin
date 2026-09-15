import '../../content_rating/domain/content_rating_catalog.dart';
import 'admin_series.dart';

class SeriesUpdateResult {
  const SeriesUpdateResult({
    required this.seriesId,
    required this.title,
    required this.synopsis,
    required this.slug,
    required this.status,
    required this.isPublished,
    required this.posterPath,
    required this.contentVersion,
    required this.updatedAt,
    required this.isArchived,
    this.contentAgeRating,
    this.contentDescriptors = const [],
    this.originalLocale,
  });

  final String seriesId;
  final String title;
  final String synopsis;
  final String slug;
  final String status;
  final bool isPublished;
  final String posterPath;
  final int contentVersion;
  final DateTime updatedAt;
  final bool isArchived;
  final int? contentAgeRating;
  final List<String> contentDescriptors;
  final String? originalLocale;

  factory SeriesUpdateResult.fromMap(Map<String, dynamic> map) {
    final seriesId = map['series_id']?.toString().trim() ?? '';
    if (seriesId.isEmpty) {
      throw const FormatException('series_id is required');
    }
    return SeriesUpdateResult(
      seriesId: seriesId,
      title: map['title']?.toString() ?? '',
      synopsis: map['synopsis']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ongoing',
      isPublished: map['is_published'] == true,
      posterPath: map['poster_path']?.toString() ?? '',
      contentVersion: requireContentVersion(map['content_version']),
      updatedAt: DateTime.parse(map['updated_at'].toString()).toUtc(),
      isArchived: map['is_archived'] == true,
      contentAgeRating: ContentRatingCatalog.parseAgeRating(
        map['content_age_rating'],
      ),
      contentDescriptors: ContentRatingCatalog.parseDescriptors(
        map['content_descriptors'],
      ),
      originalLocale: map['original_locale']?.toString(),
    );
  }

  AdminSeries applyTo(AdminSeries current) {
    return current.copyWith(
      title: title,
      synopsis: synopsis,
      slug: slug,
      status: status,
      isPublished: isPublished,
      posterPath: posterPath,
      contentVersion: contentVersion,
      updatedAt: updatedAt,
      isArchived: isArchived,
      contentAgeRating: contentAgeRating,
      clearContentAgeRating: contentAgeRating == null,
      contentDescriptors: contentDescriptors,
      originalLocale: originalLocale ?? current.originalLocale,
    );
  }
}

class SeriesPosterReplaceResult {
  const SeriesPosterReplaceResult({
    required this.seriesId,
    required this.posterPath,
    required this.contentVersion,
    required this.updatedAt,
  });

  final String seriesId;
  final String posterPath;
  final int contentVersion;
  final DateTime updatedAt;

  factory SeriesPosterReplaceResult.fromMap(Map<String, dynamic> map) {
    return SeriesPosterReplaceResult(
      seriesId: map['series_id']?.toString() ?? '',
      posterPath: map['poster_path']?.toString() ?? '',
      contentVersion: parseContentVersion(map['content_version']),
      updatedAt: DateTime.parse(map['updated_at'].toString()).toUtc(),
    );
  }
}

class SeriesLifecycleResult {
  const SeriesLifecycleResult({
    required this.seriesId,
    required this.isPublished,
    required this.isArchived,
    required this.contentVersion,
    required this.updatedAt,
  });

  final String seriesId;
  final bool isPublished;
  final bool isArchived;
  final int contentVersion;
  final DateTime updatedAt;

  factory SeriesLifecycleResult.fromMap(Map<String, dynamic> map) {
    return SeriesLifecycleResult(
      seriesId: map['series_id']?.toString() ?? '',
      isPublished: map['is_published'] == true,
      isArchived: map['is_archived'] == true,
      contentVersion: parseContentVersion(map['content_version']),
      updatedAt: DateTime.parse(map['updated_at'].toString()).toUtc(),
    );
  }
}

class SeriesReorderResult {
  const SeriesReorderResult({
    required this.seriesId,
    required this.contentVersion,
    required this.updatedAt,
  });

  final String seriesId;
  final int contentVersion;
  final DateTime updatedAt;

  factory SeriesReorderResult.fromMap(Map<String, dynamic> map) {
    return SeriesReorderResult(
      seriesId: map['series_id']?.toString() ?? '',
      contentVersion: parseContentVersion(map['content_version']),
      updatedAt: DateTime.parse(map['updated_at'].toString()).toUtc(),
    );
  }
}

int requireContentVersion(dynamic value) {
  if (value == null) {
    throw const FormatException('content_version is required');
  }
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value.toString());
  if (parsed == null) {
    throw const FormatException('content_version is required');
  }
  return parsed;
}

Map<String, dynamic>? parseRpcRow(dynamic result) {
  if (result is! Map) {
    if (result is List && result.isNotEmpty && result.first is Map) {
      result = result.first;
    } else {
      return null;
    }
  }

  final map = Map<String, dynamic>.from(result as Map);
  if (map.containsKey('ok') && map['ok'] != true) {
    return null;
  }
  if (map.containsKey('ok') && map['ok'] == true) {
    return map;
  }

  return map;
}
