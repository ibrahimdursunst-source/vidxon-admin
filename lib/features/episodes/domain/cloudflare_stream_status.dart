enum CloudflareStreamStatus {
  none,
  processing,
  ready,
  error;

  static CloudflareStreamStatus parse(dynamic value) {
    if (value == null) {
      return CloudflareStreamStatus.none;
    }

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) {
      return CloudflareStreamStatus.none;
    }

    return switch (normalized) {
      'none' => CloudflareStreamStatus.none,
      'processing' => CloudflareStreamStatus.processing,
      'ready' => CloudflareStreamStatus.ready,
      'error' => CloudflareStreamStatus.error,
      _ => throw FormatException(
        'Unknown cloudflare_stream_status value: $value',
      ),
    };
  }

  String get storageValue => name;
}
