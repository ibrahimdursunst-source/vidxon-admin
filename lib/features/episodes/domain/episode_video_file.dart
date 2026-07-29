import 'dart:async';

class EpisodeVideoFile {
  const EpisodeVideoFile({
    required this.name,
    required this.size,
    required this.extension,
    required this.contentType,
    required this.readStream,
  });

  static const int maxSizeBytes = 209715200;
  static const String allowedExtension = 'mp4';
  static const String allowedContentType = 'video/mp4';

  final String name;
  final int size;
  final String extension;
  final String contentType;
  final Stream<List<int>> readStream;
}

class EpisodeVideoFileValidationException implements Exception {
  EpisodeVideoFileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class EpisodeVideoFileValidator {
  static String? extensionFromFileName(String fileName) {
    final trimmed = fileName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= trimmed.length - 1) {
      return null;
    }

    final extension = trimmed.substring(dotIndex + 1).toLowerCase();
    if (extension != EpisodeVideoFile.allowedExtension) {
      return null;
    }

    return extension;
  }

  static EpisodeVideoFile validate({
    required String name,
    required int size,
    required String? contentType,
    required Stream<List<int>>? readStream,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw EpisodeVideoFileValidationException('Video dosya adı boş olamaz.');
    }

    if (readStream == null) {
      throw EpisodeVideoFileValidationException(
        'Video dosyası akışı okunamadı.',
      );
    }

    final extension = extensionFromFileName(trimmedName);
    if (extension == null) {
      throw EpisodeVideoFileValidationException(
        'Yalnızca MP4 formatındaki videolar desteklenir.',
      );
    }

    final normalizedContentType = contentType?.trim().toLowerCase();
    if (normalizedContentType != EpisodeVideoFile.allowedContentType) {
      throw EpisodeVideoFileValidationException(
        'Video dosya türü video/mp4 olmalıdır.',
      );
    }

    if (size <= 0) {
      throw EpisodeVideoFileValidationException('Video dosyası boş olamaz.');
    }

    if (size > EpisodeVideoFile.maxSizeBytes) {
      throw EpisodeVideoFileValidationException(
        'Video dosyası en fazla 200 MB olabilir.',
      );
    }

    return EpisodeVideoFile(
      name: trimmedName,
      size: size,
      extension: extension,
      contentType: EpisodeVideoFile.allowedContentType,
      readStream: readStream,
    );
  }
}
