class ImageUploadResponse {
  const ImageUploadResponse({
    required this.uploadUrl,
    required this.objectPath,
    required this.publicUrl,
    required this.contentType,
    required this.requiredHeaders,
    required this.expiresIn,
  });

  final String uploadUrl;
  final String objectPath;
  final String publicUrl;
  final String contentType;
  final Map<String, String> requiredHeaders;
  final int expiresIn;

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    final uploadUrl = _requireString(json['uploadUrl'], 'uploadUrl');
    final objectPath = _requireString(json['objectPath'], 'objectPath');
    final publicUrl = _requireString(json['publicUrl'], 'publicUrl');
    final contentType = _requireString(json['contentType'], 'contentType');
    final expiresIn = _parseInt(json['expiresIn']);

    final headersValue = json['requiredHeaders'];
    if (headersValue is! Map) {
      throw FormatException('requiredHeaders alanı geçersiz.');
    }

    final requiredHeaders = <String, String>{};
    for (final entry in headersValue.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw FormatException('requiredHeaders alanı geçersiz.');
      }
      requiredHeaders[entry.key as String] = entry.value as String;
    }

    if (requiredHeaders.isEmpty) {
      throw FormatException('requiredHeaders alanı boş olamaz.');
    }

    return ImageUploadResponse(
      uploadUrl: uploadUrl,
      objectPath: objectPath,
      publicUrl: publicUrl,
      contentType: contentType,
      requiredHeaders: requiredHeaders,
      expiresIn: expiresIn,
    );
  }

  static String _requireString(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$fieldName alanı geçersiz.');
    }

    return value.trim();
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
