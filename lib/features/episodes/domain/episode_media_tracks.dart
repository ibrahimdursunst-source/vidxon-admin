import 'duration_warning.dart';

enum EpisodeMediaTrackLifecycle {
  pending,
  active,
  failed,
  retired;

  static EpisodeMediaTrackLifecycle parse(dynamic raw) {
    return switch ((raw?.toString() ?? '').trim().toLowerCase()) {
      'pending' => EpisodeMediaTrackLifecycle.pending,
      'active' => EpisodeMediaTrackLifecycle.active,
      'failed' => EpisodeMediaTrackLifecycle.failed,
      'retired' => EpisodeMediaTrackLifecycle.retired,
      _ => EpisodeMediaTrackLifecycle.pending,
    };
  }
}

enum EpisodeMediaTrackStatus {
  queued,
  processing,
  ready,
  error;

  static EpisodeMediaTrackStatus parse(dynamic raw) {
    return switch ((raw?.toString() ?? '').trim().toLowerCase()) {
      'queued' => EpisodeMediaTrackStatus.queued,
      'processing' => EpisodeMediaTrackStatus.processing,
      'ready' => EpisodeMediaTrackStatus.ready,
      'error' => EpisodeMediaTrackStatus.error,
      _ => EpisodeMediaTrackStatus.queued,
    };
  }
}

class EpisodeAudioTrack {
  const EpisodeAudioTrack({
    required this.id,
    required this.episodeId,
    required this.locale,
    required this.lifecycle,
    required this.status,
    required this.durationWarningLevel,
    this.durationMs,
    this.durationDeltaMs,
    this.adminDurationOverride = false,
    this.sanitizedFailureCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String episodeId;
  final String locale;
  final EpisodeMediaTrackLifecycle lifecycle;
  final EpisodeMediaTrackStatus status;
  final DurationWarningLevel durationWarningLevel;
  final int? durationMs;
  final int? durationDeltaMs;
  final bool adminDurationOverride;
  final String? sanitizedFailureCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFailed =>
      lifecycle == EpisodeMediaTrackLifecycle.failed ||
      status == EpisodeMediaTrackStatus.error;

  bool get isReady =>
      lifecycle == EpisodeMediaTrackLifecycle.active &&
      status == EpisodeMediaTrackStatus.ready;

  bool get isProcessing => !isFailed && !isReady;

  /// Turkish status for list UI: Hazır / İşleniyor / Başarısız.
  String get statusLabel {
    if (isFailed) {
      return 'Başarısız';
    }
    if (isReady) {
      return 'Hazır';
    }
    return 'İşleniyor';
  }

  bool get canReconcile =>
      lifecycle == EpisodeMediaTrackLifecycle.pending && !isFailed;

  bool get canRemove =>
      lifecycle == EpisodeMediaTrackLifecycle.active ||
      lifecycle == EpisodeMediaTrackLifecycle.pending ||
      lifecycle == EpisodeMediaTrackLifecycle.failed;

  factory EpisodeAudioTrack.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim() ?? '';
    final episodeId = map['episode_id']?.toString().trim() ?? '';
    final locale = map['locale']?.toString().trim() ?? '';
    if (id.isEmpty || episodeId.isEmpty || locale.isEmpty) {
      throw const FormatException('Audio track row is incomplete.');
    }

    return EpisodeAudioTrack(
      id: id,
      episodeId: episodeId,
      locale: locale,
      lifecycle: EpisodeMediaTrackLifecycle.parse(map['lifecycle']),
      status: EpisodeMediaTrackStatus.parse(map['status']),
      durationWarningLevel: DurationWarningLevel.parse(
        map['duration_warning_level']?.toString(),
      ),
      durationMs: _parseNullableInt(map['duration_ms']),
      durationDeltaMs: _parseNullableInt(map['duration_delta_ms']),
      adminDurationOverride: map['admin_duration_override'] == true,
      sanitizedFailureCode: _nullableString(map['sanitized_failure_code']),
      createdAt: _parseUtc(map['created_at']),
      updatedAt: _parseUtc(map['updated_at']),
    );
  }
}

class EpisodeSubtitleTrack {
  const EpisodeSubtitleTrack({
    required this.id,
    required this.episodeId,
    required this.locale,
    required this.lifecycle,
    required this.status,
    this.sanitizedFailureCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String episodeId;
  final String locale;
  final EpisodeMediaTrackLifecycle lifecycle;
  final EpisodeMediaTrackStatus status;
  final String? sanitizedFailureCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFailed =>
      lifecycle == EpisodeMediaTrackLifecycle.failed ||
      status == EpisodeMediaTrackStatus.error;

  bool get isReady =>
      lifecycle == EpisodeMediaTrackLifecycle.active &&
      status == EpisodeMediaTrackStatus.ready;

  bool get isProcessing => !isFailed && !isReady;

  String get statusLabel {
    if (isFailed) {
      return 'Başarısız';
    }
    if (isReady) {
      return 'Hazır';
    }
    return 'İşleniyor';
  }

  bool get canRemove =>
      lifecycle == EpisodeMediaTrackLifecycle.active ||
      lifecycle == EpisodeMediaTrackLifecycle.pending ||
      lifecycle == EpisodeMediaTrackLifecycle.failed;

  factory EpisodeSubtitleTrack.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim() ?? '';
    final episodeId = map['episode_id']?.toString().trim() ?? '';
    final locale = map['locale']?.toString().trim() ?? '';
    if (id.isEmpty || episodeId.isEmpty || locale.isEmpty) {
      throw const FormatException('Subtitle track row is incomplete.');
    }

    return EpisodeSubtitleTrack(
      id: id,
      episodeId: episodeId,
      locale: locale,
      lifecycle: EpisodeMediaTrackLifecycle.parse(map['lifecycle']),
      status: EpisodeMediaTrackStatus.parse(map['status']),
      sanitizedFailureCode: _nullableString(map['sanitized_failure_code']),
      createdAt: _parseUtc(map['created_at']),
      updatedAt: _parseUtc(map['updated_at']),
    );
  }
}

class EpisodeMediaTracksSnapshot {
  const EpisodeMediaTracksSnapshot({
    required this.originalAudioLocale,
    required this.audioTracks,
    required this.subtitleTracks,
  });

  final String originalAudioLocale;
  final List<EpisodeAudioTrack> audioTracks;
  final List<EpisodeSubtitleTrack> subtitleTracks;

  factory EpisodeMediaTracksSnapshot.fromMap(Map<String, dynamic> map) {
    final original =
        map['originalAudioLocale']?.toString().trim() ??
        map['original_audio_locale']?.toString().trim() ??
        '';
    if (original.isEmpty) {
      throw const FormatException('originalAudioLocale is required.');
    }

    return EpisodeMediaTracksSnapshot(
      originalAudioLocale: original,
      audioTracks: _parseAudioList(map['audioTracks'] ?? map['audio_tracks']),
      subtitleTracks: _parseSubtitleList(
        map['subtitleTracks'] ?? map['subtitle_tracks'],
      ),
    );
  }

  static List<EpisodeAudioTrack> _parseAudioList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((row) => EpisodeAudioTrack.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static List<EpisodeSubtitleTrack> _parseSubtitleList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map(
          (row) => EpisodeSubtitleTrack.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _parseNullableInt(dynamic value) {
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

DateTime? _parseUtc(dynamic value) {
  if (value == null) {
    return null;
  }
  final parsed = DateTime.tryParse(value.toString());
  return parsed?.toUtc();
}
