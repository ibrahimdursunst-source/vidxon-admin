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

  factory SeriesUpdateResult.fromMap(Map<String, dynamic> map) {
    return SeriesUpdateResult(
      seriesId: map['series_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      synopsis: map['synopsis']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ongoing',
      isPublished: map['is_published'] == true,
      posterPath: map['poster_path']?.toString() ?? '',
      contentVersion: parseContentVersion(map['content_version']),
      updatedAt: DateTime.parse(map['updated_at'].toString()).toUtc(),
      isArchived: map['is_archived'] == true,
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

Map<String, dynamic>? parseRpcRow(dynamic result) {
  if (result is Map<String, dynamic>) {
    return result;
  }

  if (result is List && result.isNotEmpty) {
    final first = result.first;
    if (first is Map<String, dynamic>) {
      return first;
    }
  }

  return null;
}
