import 'dart:typed_data';

class PosterFile {
  const PosterFile({
    required this.bytes,
    required this.fileName,
    required this.extension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String extension;
  final String contentType;

  int get sizeInBytes => bytes.length;
}

class PosterFileValidationException implements Exception {
  PosterFileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class PosterFileValidator {
  static const int maxSizeBytes = 10 * 1024 * 1024;

  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  static String? contentTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  static String? extensionFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= fileName.length - 1) {
      return null;
    }

    final extension = fileName.substring(dotIndex + 1).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return null;
    }

    return extension == 'jpeg' ? 'jpeg' : extension;
  }

  static PosterFile validate({
    required Uint8List bytes,
    required String fileName,
  }) {
    if (bytes.isEmpty) {
      throw PosterFileValidationException('Poster dosyası boş olamaz.');
    }

    if (bytes.length > maxSizeBytes) {
      throw PosterFileValidationException(
        'Poster dosyası en fazla 10 MiB olabilir.',
      );
    }

    final extension = extensionFromFileName(fileName);
    if (extension == null) {
      throw PosterFileValidationException(
        'Poster yalnızca JPG, PNG veya WEBP formatında olabilir.',
      );
    }

    final contentType = contentTypeForExtension(extension);
    if (contentType == null) {
      throw PosterFileValidationException('Poster dosya türü desteklenmiyor.');
    }

    return PosterFile(
      bytes: bytes,
      fileName: fileName,
      extension: extension,
      contentType: contentType,
    );
  }

  static bool isWithinSizeLimit(int sizeInBytes) {
    return sizeInBytes > 0 && sizeInBytes <= maxSizeBytes;
  }
}
