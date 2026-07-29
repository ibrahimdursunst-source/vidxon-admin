import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/domain/episode_video_file.dart';
import 'package:vidxon_admin/features/episodes/domain/stream_upload_ticket.dart';

void main() {
  const episodeId = '11111111-1111-1111-1111-111111111111';

  Map<String, dynamic> validJson({String? expiresAt}) {
    return {
      'uploadUrl': 'https://upload.cloudflarestream.com/signed-upload',
      'uid': 'abc123streamuid',
      'episodeId': episodeId,
      'expiresAt': expiresAt ?? '2099-01-01T00:00:00.000Z',
      'maxDurationSeconds': 600,
      'maxFileSizeBytes': EpisodeVideoFile.maxSizeBytes,
      'requiredMethod': 'POST',
      'requiredFieldName': 'file',
      'requiredContentType': 'video/mp4',
      'requireSignedURLs': true,
    };
  }

  group('StreamUploadTicket.fromJson', () {
    test('parses valid JSON', () {
      final ticket = StreamUploadTicket.fromJson(
        validJson(),
        expectedEpisodeId: episodeId,
        now: DateTime.utc(2026, 1, 1),
      );

      expect(ticket.uploadUrl, startsWith('https://'));
      expect(ticket.uid, 'abc123streamuid');
      expect(ticket.episodeId, episodeId);
      expect(ticket.requiredMethod, 'POST');
      expect(ticket.requiredFieldName, 'file');
      expect(ticket.requiredContentType, 'video/mp4');
      expect(ticket.requireSignedURLs, isTrue);
      expect(ticket.expiresAt.isUtc, isTrue);
    });

    test('rejects non-HTTPS uploadUrl', () {
      final json = validJson()
        ..['uploadUrl'] = 'http://upload.cloudflarestream.com/insecure';

      expect(
        () => StreamUploadTicket.fromJson(
          json,
          expectedEpisodeId: episodeId,
          now: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects requireSignedURLs=false', () {
      final json = validJson()..['requireSignedURLs'] = false;

      expect(
        () => StreamUploadTicket.fromJson(
          json,
          expectedEpisodeId: episodeId,
          now: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects requiredMethod other than POST', () {
      final json = validJson()..['requiredMethod'] = 'PUT';

      expect(
        () => StreamUploadTicket.fromJson(
          json,
          expectedEpisodeId: episodeId,
          now: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects requiredFieldName other than file', () {
      final json = validJson()..['requiredFieldName'] = 'video';

      expect(
        () => StreamUploadTicket.fromJson(
          json,
          expectedEpisodeId: episodeId,
          now: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects requiredContentType other than video/mp4', () {
      final json = validJson()..['requiredContentType'] = 'video/webm';

      expect(
        () => StreamUploadTicket.fromJson(
          json,
          expectedEpisodeId: episodeId,
          now: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('detects expired ticket', () {
      expect(
        () => StreamUploadTicket.fromJson(
          validJson(expiresAt: '2020-01-01T00:00:00.000Z'),
          expectedEpisodeId: episodeId,
          now: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('buildCreateUploadTicketPayload', () {
    test('uses expected payload keys', () {
      final file = EpisodeVideoFile(
        name: 'episode-1.mp4',
        size: 1024,
        extension: 'mp4',
        contentType: 'video/mp4',
        readStream: const Stream.empty(),
      );

      final payload = buildCreateUploadTicketPayload(
        episodeId: episodeId,
        file: file,
      );

      expect(
        payload.keys,
        containsAll(['episodeId', 'fileName', 'fileSize', 'contentType']),
      );
      expect(payload['episodeId'], episodeId);
      expect(payload['fileName'], 'episode-1.mp4');
      expect(payload['fileSize'], 1024);
      expect(payload['contentType'], 'video/mp4');
    });
  });

  group('buildAttachStreamVideoRpcParams', () {
    test('uses expected RPC payload keys', () {
      final params = buildAttachStreamVideoRpcParams(
        episodeId: episodeId,
        streamUid: 'stream-uid-123',
      );

      expect(params.keys, containsAll(['p_episode_id', 'p_stream_uid']));
      expect(params['p_episode_id'], episodeId);
      expect(params['p_stream_uid'], 'stream-uid-123');
    });
  });
}
