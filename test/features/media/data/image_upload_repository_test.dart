import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidxon_admin/features/media/data/image_upload_repository.dart';
import 'package:vidxon_admin/features/media/domain/image_upload_response.dart';

class _ThrowingPutClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException('Failed to fetch', request.url);
  }
}

void main() {
  group('imageUploadUrlFailureMessage', () {
    test('401 maps to session expiry without leaking transport text', () {
      expect(
        imageUploadUrlFailureMessage(status: 401),
        imageUploadSessionExpiredMessage,
      );
      expect(
        imageUploadUrlFailureMessage(status: 401).toLowerCase(),
        isNot(contains('failed to fetch')),
      );
    });

    test('forbidden and unknown statuses stay on the stable upload message', () {
      expect(
        imageUploadUrlFailureMessage(status: 403),
        imageUploadUrlFailedMessage,
      );
      expect(
        imageUploadUrlFailureMessage(status: 400),
        imageUploadUrlFailedMessage,
      );
      expect(imageUploadUrlFailureMessage(), imageUploadUrlFailedMessage);
      expect(
        imageUploadUrlFailedMessage.toLowerCase(),
        isNot(contains('cors')),
      );
      expect(
        imageUploadUrlFailedMessage.toLowerCase(),
        isNot(contains('sqlstate')),
      );
    });

    test('FunctionException status uses the same stable mapping', () {
      const error = FunctionException(status: 403, details: 'Forbidden');
      expect(
        imageUploadUrlFailureMessage(status: error.status),
        imageUploadUrlFailedMessage,
      );
      expect(
        imageUploadUrlFailureMessage(status: error.status),
        isNot(contains('Forbidden')),
      );
    });
  });

  group('ImageUploadRepository.uploadPoster', () {
    test('maps PUT transport failures to ImageUploadException', () async {
      final repository = ImageUploadRepository(httpClient: _ThrowingPutClient());
      const uploadInfo = ImageUploadResponse(
        uploadUrl: 'https://upload.example.com/poster',
        objectPath: 'posters/test/poster.png',
        publicUrl: 'https://media.example.com/posters/test/poster.png',
        contentType: 'image/png',
        requiredHeaders: {'Content-Type': 'image/png'},
        expiresIn: 60,
      );

      expect(
        () => repository.uploadPoster(
          uploadInfo: uploadInfo,
          fileBytes: Uint8List.fromList(const [1, 2, 3]),
        ),
        throwsA(
          isA<ImageUploadException>().having(
            (error) => error.message,
            'message',
            imageUploadPutFailedMessage,
          ),
        ),
      );
    });
  });
}
