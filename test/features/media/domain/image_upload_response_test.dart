import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/media/domain/image_upload_response.dart';

void main() {
  group('ImageUploadResponse.fromJson', () {
    test('parses valid response', () {
      final response = ImageUploadResponse.fromJson({
        'uploadUrl': 'https://example.com/upload?sig=secret',
        'objectPath': 'posters/2026/07/uuid.jpg',
        'publicUrl': 'https://media.vidxon.com/posters/2026/07/uuid.jpg',
        'contentType': 'image/jpeg',
        'requiredHeaders': {'Content-Type': 'image/jpeg'},
        'expiresIn': 300,
      });

      expect(response.objectPath, 'posters/2026/07/uuid.jpg');
      expect(response.publicUrl, contains('media.vidxon.com'));
      expect(response.requiredHeaders['Content-Type'], 'image/jpeg');
      expect(response.expiresIn, 300);
    });

    test('throws when required fields are missing', () {
      expect(
        () => ImageUploadResponse.fromJson({
          'uploadUrl': 'https://example.com/upload',
          'objectPath': '',
          'publicUrl': 'https://media.vidxon.com/a.jpg',
          'contentType': 'image/jpeg',
          'requiredHeaders': {},
          'expiresIn': 300,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when requiredHeaders is invalid', () {
      expect(
        () => ImageUploadResponse.fromJson({
          'uploadUrl': 'https://example.com/upload',
          'objectPath': 'posters/a.jpg',
          'publicUrl': 'https://media.vidxon.com/posters/a.jpg',
          'contentType': 'image/jpeg',
          'requiredHeaders': 'invalid',
          'expiresIn': 300,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
