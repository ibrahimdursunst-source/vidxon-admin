import 'cloudflare_stream_status.dart';
import '../../content_rating/domain/content_rating_catalog.dart';

class AdminEpisode {
  const AdminEpisode({
    required this.id,
    required this.seriesId,
    required this.episodeNumber,
    required this.title,
    required this.synopsis,
    required this.isFree,
    required this.coinPrice,
    required this.isPublished,
    required this.isArchived,
    required this.contentVersion,
    required this.totalViews,
    this.qualifiedViewsTotal = 0,
    required this.cloudflareStreamStatus,
    required this.cloudflareStreamPendingStatus,
    this.thumbnailPath,
    this.cloudflareStreamPendingRequestedAt,
    this.durationSeconds,
    this.cloudflareStreamLastCheckedAt,
    this.archivedAt,
    this.releaseAt,
    this.createdAt,
    this.updatedAt,
    this.contentAgeRating,
    this.contentDescriptors,
  });

  final String id;
  final String seriesId;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final String? thumbnailPath;
  final int? durationSeconds;
  final bool isFree;
  final int coinPrice;
  final bool isPublished;
  final bool isArchived;
  final int contentVersion;
  final int totalViews;
  final int qualifiedViewsTotal;
  final CloudflareStreamStatus cloudflareStreamStatus;
  final CloudflareStreamStatus cloudflareStreamPendingStatus;
  final DateTime? cloudflareStreamPendingRequestedAt;
  final DateTime? cloudflareStreamLastCheckedAt;
  final DateTime? archivedAt;
  final DateTime? releaseAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? contentAgeRating;

  /// Null means inherit series descriptors; non-null (including empty) is override.
  final List<String>? contentDescriptors;

  bool get hasContentRatingOverride =>
      contentAgeRating != null || contentDescriptors != null;

  bool get hasActiveVideo =>
      cloudflareStreamStatus != CloudflareStreamStatus.none;

  bool get hasPendingReplacement =>
      cloudflareStreamPendingStatus != CloudflareStreamStatus.none;

  bool get allowsInitialVideoUpload =>
      !isArchived &&
      !hasActiveVideo &&
      !hasPendingReplacement &&
      cloudflareStreamStatus == CloudflareStreamStatus.none;

  bool get allowsReplacementRequest =>
      !isArchived && hasActiveVideo && !hasPendingReplacement;

  bool get allowsReplacementRetry =>
      hasPendingReplacement &&
      cloudflareStreamPendingStatus == CloudflareStreamStatus.error;

  bool get canPublish =>
      !isArchived &&
      hasActiveVideo &&
      cloudflareStreamStatus == CloudflareStreamStatus.ready &&
      title.trim().isNotEmpty &&
      episodeNumber > 0 &&
      (isFree || coinPrice > 0);

  /// Shown when the parent series is archived (menu / UX only; mirrors gate).
  static const parentSeriesArchivedPublishBlockReason =
      'Arşivlenmiş bir dizinin bölümü yayınlanamaz.';

  String? get publishBlockReason {
    if (isArchived) {
      return 'Arşivlenmiş bölüm yayınlanamaz.';
    }

    if (!hasActiveVideo) {
      return 'Yayınlamak için aktif video gerekir.';
    }

    if (cloudflareStreamStatus == CloudflareStreamStatus.processing) {
      return 'Video işleniyor.';
    }

    if (cloudflareStreamStatus == CloudflareStreamStatus.error) {
      return 'Video hatası giderilmelidir.';
    }

    if (cloudflareStreamStatus != CloudflareStreamStatus.ready) {
      return 'Video henüz hazır değil.';
    }

    if (!isFree && coinPrice <= 0) {
      return 'Ücretli bölümde coin fiyatı 0\'dan büyük olmalıdır.';
    }

    return null;
  }

  /// Publish menu eligibility: episode rules plus archived parent gate.
  bool canPublishFromMenu({required bool parentSeriesArchived}) =>
      !parentSeriesArchived && canPublish;

  /// Human-readable block reason for the Publish menu item.
  String? publishMenuBlockReason({required bool parentSeriesArchived}) {
    if (parentSeriesArchived) {
      return parentSeriesArchivedPublishBlockReason;
    }
    return publishBlockReason;
  }

  String get videoStatusLabel => switch (cloudflareStreamStatus) {
    CloudflareStreamStatus.none => 'Video Yok',
    CloudflareStreamStatus.processing => 'İşleniyor',
    CloudflareStreamStatus.ready => 'Video Hazır',
    CloudflareStreamStatus.error => 'Video Hatası',
  };

  String get pendingVideoStatusLabel {
    if (!hasPendingReplacement) {
      return '—';
    }

    return switch (cloudflareStreamPendingStatus) {
      CloudflareStreamStatus.processing => 'Değişim: İşleniyor',
      CloudflareStreamStatus.ready => 'Değişim: Hazır',
      CloudflareStreamStatus.error => 'Değişim: Hata',
      CloudflareStreamStatus.none => 'Değişim: Bekliyor',
    };
  }

  String get publishLabel => isPublished ? 'Yayında' : 'Yayında Değil';

  String get archiveLabel => isArchived ? 'Arşivlenmiş' : 'Aktif';

  String get priceLabel => isFree ? 'Ücretsiz' : '$coinPrice jeton';

  AdminEpisode copyWith({
    String? title,
    String? synopsis,
    bool? isFree,
    int? coinPrice,
    bool? isPublished,
    bool? isArchived,
    int? contentVersion,
    CloudflareStreamStatus? cloudflareStreamStatus,
    CloudflareStreamStatus? cloudflareStreamPendingStatus,
    DateTime? cloudflareStreamPendingRequestedAt,
    DateTime? releaseAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    int? contentAgeRating,
    List<String>? contentDescriptors,
    bool clearContentAgeRating = false,
    bool clearContentDescriptors = false,
  }) {
    return AdminEpisode(
      id: id,
      seriesId: seriesId,
      episodeNumber: episodeNumber,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      isFree: isFree ?? this.isFree,
      coinPrice: coinPrice ?? this.coinPrice,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      contentVersion: contentVersion ?? this.contentVersion,
      totalViews: totalViews,
      qualifiedViewsTotal: qualifiedViewsTotal,
      cloudflareStreamStatus:
          cloudflareStreamStatus ?? this.cloudflareStreamStatus,
      cloudflareStreamPendingStatus:
          cloudflareStreamPendingStatus ?? this.cloudflareStreamPendingStatus,
      thumbnailPath: thumbnailPath,
      cloudflareStreamPendingRequestedAt:
          cloudflareStreamPendingRequestedAt ??
          this.cloudflareStreamPendingRequestedAt,
      durationSeconds: durationSeconds,
      cloudflareStreamLastCheckedAt: cloudflareStreamLastCheckedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      releaseAt: releaseAt ?? this.releaseAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentAgeRating: clearContentAgeRating
          ? null
          : (contentAgeRating ?? this.contentAgeRating),
      contentDescriptors: clearContentDescriptors
          ? null
          : (contentDescriptors ?? this.contentDescriptors),
    );
  }

  factory AdminEpisode.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim() ?? '';
    final seriesId = map['series_id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      throw FormatException('Episode id is required.');
    }

    if (seriesId.isEmpty) {
      throw FormatException('Episode series_id is required.');
    }

    final episodeNumber = _parseRequiredInt(
      map['episode_number'],
      fieldName: 'episode_number',
    );

    final title = map['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      throw FormatException('Episode title is required.');
    }

    return AdminEpisode(
      id: id,
      seriesId: seriesId,
      episodeNumber: episodeNumber,
      title: title,
      synopsis: map['synopsis']?.toString() ?? '',
      thumbnailPath: _nullableString(map['thumbnail_path']),
      durationSeconds: _parseNullableInt(map['duration_seconds']),
      isFree: map['is_free'] == true,
      coinPrice: _parseInt(map['coin_price']),
      isPublished: map['is_published'] == true,
      isArchived: map['is_archived'] == true,
      contentVersion: _parseInt(map['content_version']),
      totalViews: _parseInt(map['total_views']),
      qualifiedViewsTotal: _parseInt(map['qualified_views_total']),
      cloudflareStreamStatus: CloudflareStreamStatus.parse(
        map['cloudflare_stream_status'],
      ),
      cloudflareStreamPendingStatus: CloudflareStreamStatus.parse(
        map['cloudflare_stream_pending_status'],
      ),
      cloudflareStreamPendingRequestedAt: _parseUtcDateTime(
        map['cloudflare_stream_pending_requested_at'],
      ),
      cloudflareStreamLastCheckedAt: _parseUtcDateTime(
        map['cloudflare_stream_last_checked_at'],
      ),
      archivedAt: _parseUtcDateTime(map['archived_at']),
      releaseAt: _parseUtcDateTime(map['release_at']),
      createdAt: _parseUtcDateTime(map['created_at']),
      updatedAt: _parseUtcDateTime(map['updated_at']),
      contentAgeRating: ContentRatingCatalog.parseAgeRating(
        map['content_age_rating'],
      ),
      contentDescriptors: ContentRatingCatalog.parseNullableDescriptors(
        map['content_descriptors'],
      ),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
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

  static int _parseRequiredInt(dynamic value, {required String fieldName}) {
    if (value == null) {
      throw FormatException('Episode $fieldName is required.');
    }

    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    final parsed = int.tryParse(value.toString());
    if (parsed == null) {
      throw FormatException('Episode $fieldName is invalid.');
    }

    return parsed;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  static DateTime? _parseUtcDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return null;
    }

    return parsed.toUtc();
  }
}

int compareEpisodesByNumber(AdminEpisode a, AdminEpisode b) {
  final numberCompare = a.episodeNumber.compareTo(b.episodeNumber);
  if (numberCompare != 0) {
    return numberCompare;
  }

  final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return aCreated.compareTo(bCreated);
}

List<AdminEpisode> sortEpisodesByNumber(List<AdminEpisode> episodes) {
  final sorted = List<AdminEpisode>.from(episodes);
  sorted.sort(compareEpisodesByNumber);
  return sorted;
}

List<AdminEpisode> activeEpisodes(List<AdminEpisode> episodes) {
  return episodes.where((episode) => !episode.isArchived).toList();
}

List<AdminEpisode> archivedEpisodes(List<AdminEpisode> episodes) {
  return episodes.where((episode) => episode.isArchived).toList();
}
