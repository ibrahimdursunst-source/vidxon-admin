import 'dart:async';

class EpisodeAudioFile {
  const EpisodeAudioFile({
    required this.name,
    required this.size,
    required this.extension,
    required this.contentType,
    required this.readStream,
  });

  static const int maxSizeBytes = 32 * 1024 * 1024; // 32 MiB — Edge memory-safe
  static const List<String> allowedExtensions = ['mp3', 'm4a', 'aac'];
  static const Map<String, String> extensionContentTypes = {
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
  };

  final String name;
  final int size;
  final String extension;
  final String contentType;
  final Stream<List<int>> readStream;
}

class EpisodeAudioFileValidationException implements Exception {
  EpisodeAudioFileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class EpisodeAudioFileValidator {
  static String? extensionFromFileName(String fileName) {
    final trimmed = fileName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= trimmed.length - 1) {
      return null;
    }

    final extension = trimmed.substring(dotIndex + 1).toLowerCase();
    if (!EpisodeAudioFile.allowedExtensions.contains(extension)) {
      return null;
    }
    return extension;
  }

  static EpisodeAudioFile validate({
    required String name,
    required int size,
    required String? contentType,
    required Stream<List<int>>? readStream,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw EpisodeAudioFileValidationException('Ses dosya adı boş olamaz.');
    }

    if (readStream == null) {
      throw EpisodeAudioFileValidationException('Ses dosyası akışı okunamadı.');
    }

    final extension = extensionFromFileName(trimmedName);
    if (extension == null) {
      throw EpisodeAudioFileValidationException(
        'Yalnızca MP3, M4A veya AAC formatındaki ses dosyaları desteklenir.',
      );
    }

    final expectedContentType =
        EpisodeAudioFile.extensionContentTypes[extension]!;
    final normalizedContentType = contentType?.trim().toLowerCase() ?? '';
    if (normalizedContentType.isNotEmpty &&
        normalizedContentType != expectedContentType &&
        !(extension == 'm4a' &&
            (normalizedContentType == 'audio/x-m4a' ||
                normalizedContentType == 'audio/aac')) &&
        !(extension == 'aac' && normalizedContentType == 'audio/x-m4a')) {
      // Allow empty MIME (some pickers omit it); reject clear mismatches.
      final allowed = {'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/x-m4a'};
      if (!allowed.contains(normalizedContentType)) {
        throw EpisodeAudioFileValidationException(
          'Ses dosya türü desteklenmiyor.',
        );
      }
    }

    if (size <= 0) {
      throw EpisodeAudioFileValidationException('Ses dosyası boş olamaz.');
    }

    if (size > EpisodeAudioFile.maxSizeBytes) {
      throw EpisodeAudioFileValidationException(
        'Ses dosyası en fazla 32 MB olabilir.',
      );
    }

    return EpisodeAudioFile(
      name: trimmedName,
      size: size,
      extension: extension,
      contentType: normalizedContentType.isEmpty
          ? expectedContentType
          : normalizedContentType,
      readStream: readStream,
    );
  }
}
