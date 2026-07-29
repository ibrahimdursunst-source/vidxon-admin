import 'cloudflare_stream_status.dart';

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
    required this.totalViews,
    required this.cloudflareStreamStatus,
    this.thumbnailPath,
    this.cloudflareStreamUid,
    this.durationSeconds,
    this.cloudflareStreamLastCheckedAt,
    this.releaseAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String seriesId;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final String? thumbnailPath;
  final String? cloudflareStreamUid;
  final int? durationSeconds;
  final bool isFree;
  final int coinPrice;
  final bool isPublished;
  final int totalViews;
  final CloudflareStreamStatus cloudflareStreamStatus;
  final DateTime? cloudflareStreamLastCheckedAt;
  final DateTime? releaseAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasVideo =>
      cloudflareStreamUid != null && cloudflareStreamUid!.trim().isNotEmpty;

  bool get allowsVideoUpload =>
      !hasVideo && cloudflareStreamStatus == CloudflareStreamStatus.none;

  String get videoStatusLabel => switch (cloudflareStreamStatus) {
    CloudflareStreamStatus.none => 'Video Yok',
    CloudflareStreamStatus.processing => 'İşleniyor',
    CloudflareStreamStatus.ready => 'Video Hazır',
    CloudflareStreamStatus.error => 'Video Hatası',
  };

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
      cloudflareStreamUid: _nullableString(map['cloudflare_stream_uid']),
      durationSeconds: _parseNullableInt(map['duration_seconds']),
      isFree: map['is_free'] == true,
      coinPrice: _parseInt(map['coin_price']),
      isPublished: map['is_published'] == true,
      totalViews: _parseInt(map['total_views']),
      cloudflareStreamStatus: CloudflareStreamStatus.parse(
        map['cloudflare_stream_status'],
      ),
      cloudflareStreamLastCheckedAt: _parseUtcDateTime(
        map['cloudflare_stream_last_checked_at'],
      ),
      releaseAt: _parseUtcDateTime(map['release_at']),
      createdAt: _parseUtcDateTime(map['created_at']),
      updatedAt: _parseUtcDateTime(map['updated_at']),
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
