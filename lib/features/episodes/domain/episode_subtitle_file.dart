import 'dart:async';

class EpisodeSubtitleFile {
  const EpisodeSubtitleFile({
    required this.name,
    required this.size,
    required this.readStream,
  });

  static const int maxSizeBytes = 5 * 1024 * 1024;
  static const String allowedExtension = 'vtt';
  static const String allowedContentType = 'text/vtt';

  final String name;
  final int size;
  final Stream<List<int>> readStream;
}

class EpisodeSubtitleFileValidationException implements Exception {
  EpisodeSubtitleFileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class EpisodeSubtitleFileValidator {
  static bool hasVttExtension(String fileName) {
    final trimmed = fileName.trim().toLowerCase();
    return trimmed.endsWith('.${EpisodeSubtitleFile.allowedExtension}');
  }

  static EpisodeSubtitleFile validate({
    required String name,
    required int size,
    required Stream<List<int>>? readStream,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw EpisodeSubtitleFileValidationException(
        'Altyazı dosya adı boş olamaz.',
      );
    }

    if (readStream == null) {
      throw EpisodeSubtitleFileValidationException(
        'Altyazı dosyası akışı okunamadı.',
      );
    }

    if (!hasVttExtension(trimmedName)) {
      throw EpisodeSubtitleFileValidationException(
        'Yalnızca WebVTT (.vtt) altyazı dosyaları desteklenir.',
      );
    }

    if (size <= 0) {
      throw EpisodeSubtitleFileValidationException(
        'Altyazı dosyası boş olamaz.',
      );
    }

    if (size > EpisodeSubtitleFile.maxSizeBytes) {
      throw EpisodeSubtitleFileValidationException(
        'Altyazı dosyası en fazla 5 MB olabilir.',
      );
    }

    return EpisodeSubtitleFile(
      name: trimmedName,
      size: size,
      readStream: readStream,
    );
  }
}
