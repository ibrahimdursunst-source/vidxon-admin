import 'episode_video_file.dart';

class StreamUploadTicket {
  const StreamUploadTicket({
    required this.uploadUrl,
    required this.uid,
    required this.episodeId,
    required this.expiresAt,
    required this.maxDurationSeconds,
    required this.maxFileSizeBytes,
    required this.requiredMethod,
    required this.requiredFieldName,
    required this.requiredContentType,
    required this.requireSignedURLs,
  });

  static final RegExp _uidPattern = RegExp(r'^[A-Za-z0-9_-]{1,32}$');

  final String uploadUrl;
  final String uid;
  final String episodeId;
  final DateTime expiresAt;
  final int maxDurationSeconds;
  final int maxFileSizeBytes;
  final String requiredMethod;
  final String requiredFieldName;
  final String requiredContentType;
  final bool requireSignedURLs;

  bool isExpiredAt(DateTime nowUtc) {
    return !nowUtc.isBefore(expiresAt.toUtc());
  }

  factory StreamUploadTicket.fromJson(
    Map<String, dynamic> json, {
    required String expectedEpisodeId,
    DateTime? now,
  }) {
    final uploadUrl = _requireHttpsUrl(json['uploadUrl'], 'uploadUrl');
    final uid = _requireStreamUid(json['uid']);
    final episodeId = _requireString(json['episodeId'], 'episodeId');
    final expiresAt = _parseUtcDateTime(json['expiresAt'], 'expiresAt');
    final maxDurationSeconds = _parsePositiveInt(
      json['maxDurationSeconds'],
      'maxDurationSeconds',
    );
    final maxFileSizeBytes = _parsePositiveInt(
      json['maxFileSizeBytes'],
      'maxFileSizeBytes',
    );
    final requiredMethod = _requireExactString(
      json['requiredMethod'],
      'requiredMethod',
      expected: 'POST',
    );
    final requiredFieldName = _requireExactString(
      json['requiredFieldName'],
      'requiredFieldName',
      expected: 'file',
    );
    final requiredContentType = _requireExactString(
      json['requiredContentType'],
      'requiredContentType',
      expected: EpisodeVideoFile.allowedContentType,
    );
    final requireSignedURLs = json['requireSignedURLs'];
    if (requireSignedURLs != true) {
      throw FormatException('requireSignedURLs must be true.');
    }

    if (episodeId != expectedEpisodeId.trim()) {
      throw FormatException('episodeId does not match the requested episode.');
    }

    final ticket = StreamUploadTicket(
      uploadUrl: uploadUrl,
      uid: uid,
      episodeId: episodeId,
      expiresAt: expiresAt,
      maxDurationSeconds: maxDurationSeconds,
      maxFileSizeBytes: maxFileSizeBytes,
      requiredMethod: requiredMethod,
      requiredFieldName: requiredFieldName,
      requiredContentType: requiredContentType,
      requireSignedURLs: true,
    );

    if (ticket.isExpiredAt((now ?? DateTime.now()).toUtc())) {
      throw FormatException('Upload ticket has expired.');
    }

    return ticket;
  }

  static String _requireString(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$fieldName is invalid.');
    }

    return value.trim();
  }

  static String _requireExactString(
    dynamic value,
    String fieldName, {
    required String expected,
  }) {
    final parsed = _requireString(value, fieldName);
    if (parsed != expected) {
      throw FormatException('$fieldName must be $expected.');
    }

    return parsed;
  }

  static String _requireHttpsUrl(dynamic value, String fieldName) {
    final parsed = _requireString(value, fieldName);
    final uri = Uri.tryParse(parsed);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('$fieldName must be a valid HTTPS URL.');
    }

    return parsed;
  }

  static String _requireStreamUid(dynamic value) {
    final parsed = _requireString(value, 'uid');
    if (!_uidPattern.hasMatch(parsed)) {
      throw FormatException('uid is invalid.');
    }

    return parsed;
  }

  static DateTime _parseUtcDateTime(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$fieldName is invalid.');
    }

    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      throw FormatException('$fieldName is invalid.');
    }

    return parsed.toUtc();
  }

  static int _parsePositiveInt(dynamic value, String fieldName) {
    if (value is! int || value <= 0) {
      if (value is num && value > 0) {
        return value.toInt();
      }
      throw FormatException('$fieldName is invalid.');
    }

    return value;
  }
}

Map<String, dynamic> buildCreateUploadTicketPayload({
  required String episodeId,
  required EpisodeVideoFile file,
}) {
  return {
    'episodeId': episodeId.trim(),
    'fileName': file.name,
    'fileSize': file.size,
    'contentType': file.contentType,
  };
}

Map<String, dynamic> buildAttachStreamVideoRpcParams({
  required String episodeId,
  required String streamUid,
}) {
  return {'p_episode_id': episodeId.trim(), 'p_stream_uid': streamUid.trim()};
}
