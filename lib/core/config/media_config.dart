abstract final class MediaConfig {
  static const String baseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'https://media.vidxon.com',
  );

  static String? resolvePosterUrl(String posterPath) {
    final trimmed = posterPath.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (baseUrl.isEmpty) {
      return null;
    }

    final normalizedBase = baseUrl.replaceAll(RegExp(r'/$'), '');
    final normalizedPath = trimmed.replaceFirst(RegExp(r'^/'), '');
    return '$normalizedBase/$normalizedPath';
  }
}
