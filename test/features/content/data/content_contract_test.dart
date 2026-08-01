import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/stream_preview_response.dart';

void main() {
  group('buildStreamPreviewRequest', () {
    test('sends only episodeId and videoSource', () {
      final body = buildStreamPreviewRequest(
        episodeId: '11111111-1111-1111-1111-111111111111',
        videoSource: 'pending',
      );

      expect(body.keys, ['episodeId', 'videoSource']);
      expect(body.containsKey('streamUid'), isFalse);
      expect(body.containsKey('token'), isFalse);
      expect(body['videoSource'], 'pending');
    });
  });

  group('ImageUploadRepository poster replacement body', () {
    test('includes required replacement fields only', () {
      final body = <String, dynamic>{
        'kind': 'poster',
        'contentType': 'image/jpeg',
        'fileSize': 1024,
        'purpose': 'series_poster_replacement',
        'seriesId': '22222222-2222-2222-2222-222222222222',
      };

      expect(body['purpose'], 'series_poster_replacement');
      expect(body['seriesId'], isNotNull);
      expect(body.containsKey('objectPath'), isFalse);
    });
  });
}
