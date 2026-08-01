class StreamPreviewResponse {
  const StreamPreviewResponse({
    required this.previewUrl,
    required this.expiresAt,
    required this.episodeId,
    required this.videoSource,
  });

  final String previewUrl;
  final DateTime expiresAt;
  final String episodeId;
  final String videoSource;

  factory StreamPreviewResponse.fromJson(Map<String, dynamic> json) {
    final previewUrl = json['previewUrl']?.toString().trim() ?? '';
    if (previewUrl.isEmpty) {
      throw FormatException('previewUrl is required.');
    }

    final expiresAtRaw = json['expiresAt']?.toString();
    if (expiresAtRaw == null || expiresAtRaw.isEmpty) {
      throw FormatException('expiresAt is required.');
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      throw FormatException('expiresAt is invalid.');
    }

    return StreamPreviewResponse(
      previewUrl: previewUrl,
      expiresAt: expiresAt.toUtc(),
      episodeId: json['episodeId']?.toString() ?? '',
      videoSource: json['videoSource']?.toString() ?? 'active',
    );
  }
}

Map<String, dynamic> buildStreamPreviewRequest({
  required String episodeId,
  required String videoSource,
}) {
  return {'episodeId': episodeId.trim(), 'videoSource': videoSource};
}
