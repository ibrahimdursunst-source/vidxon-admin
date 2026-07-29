import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vidxon_admin/features/episodes/data/episode_video_upload_errors.dart';
import 'package:vidxon_admin/features/episodes/data/episode_video_upload_repository.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/domain/episode_video_file.dart';
import 'package:vidxon_admin/features/episodes/domain/stream_upload_ticket.dart';

EpisodeVideoFile _testFile({int size = 10}) {
  return EpisodeVideoFile(
    name: 'episode-1.mp4',
    size: size,
    extension: 'mp4',
    contentType: 'video/mp4',
    readStream: Stream<List<int>>.fromIterable([List<int>.filled(size, 1)]),
  );
}

StreamUploadTicket _testTicket({
  required String episodeId,
  String uploadUrl = 'https://upload.cloudflarestream.com/signed',
}) {
  return StreamUploadTicket(
    uploadUrl: uploadUrl,
    uid: 'streamuid123',
    episodeId: episodeId,
    expiresAt: DateTime.utc(2099, 1, 1),
    maxDurationSeconds: 600,
    maxFileSizeBytes: EpisodeVideoFile.maxSizeBytes,
    requiredMethod: 'POST',
    requiredFieldName: 'file',
    requiredContentType: 'video/mp4',
    requireSignedURLs: true,
  );
}

AdminEpisode _testEpisode(String episodeId) {
  return AdminEpisode.fromMap({
    'id': episodeId,
    'series_id': '22222222-2222-2222-2222-222222222222',
    'episode_number': 1,
    'title': 'Bölüm 1',
    'synopsis': '',
    'cloudflare_stream_uid': 'streamuid123',
    'cloudflare_stream_status': 'processing',
    'is_free': true,
    'coin_price': 0,
    'is_published': false,
    'total_views': 0,
  });
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient(this.onSend);

  final Future<http.StreamedResponse> Function(http.BaseRequest request) onSend;
  int sendCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sendCount += 1;
    return onSend(request);
  }
}

void main() {
  const episodeId = '11111111-1111-1111-1111-111111111111';

  group('runEpisodeVideoUploadSteps', () {
    test('does not attach before upload succeeds', () async {
      final calls = <String>[];

      await expectLater(
        runEpisodeVideoUploadSteps(
          createTicket: () async {
            calls.add('ticket');
            return _testTicket(episodeId: episodeId);
          },
          uploadVideoStep: (_) async {
            calls.add('upload');
            throw EpisodeVideoUploadException(
              message: 'upload failed',
              kind: EpisodeVideoUploadFailureKind.cloudflareUploadFailed,
            );
          },
          attachVideoStep: (_) async {
            calls.add('attach');
            return _testEpisode(episodeId);
          },
        ),
        throwsA(isA<EpisodeVideoUploadException>()),
      );

      expect(calls, ['ticket', 'upload']);
    });

    test('upload success then attach success', () async {
      final calls = <String>[];

      final episode = await runEpisodeVideoUploadSteps(
        createTicket: () async {
          calls.add('ticket');
          return _testTicket(episodeId: episodeId);
        },
        uploadVideoStep: (_) async {
          calls.add('upload');
        },
        attachVideoStep: (uid) async {
          calls.add('attach:$uid');
          return _testEpisode(episodeId);
        },
      );

      expect(calls, ['ticket', 'upload', 'attach:streamuid123']);
      expect(episode.cloudflareStreamStatus, CloudflareStreamStatus.processing);
    });

    test('upload success then attach failure', () async {
      await expectLater(
        runEpisodeVideoUploadSteps(
          createTicket: () async => _testTicket(episodeId: episodeId),
          uploadVideoStep: (_) async {},
          attachVideoStep: (_) async {
            throw EpisodeVideoUploadException(
              message: 'attach failed',
              kind: EpisodeVideoUploadFailureKind.attachFailed,
              canRetryAttach: true,
              pendingStreamUid: 'streamuid123',
            );
          },
        ),
        throwsA(
          isA<EpisodeVideoUploadException>().having(
            (error) => error.canRetryAttach,
            'canRetryAttach',
            isTrue,
          ),
        ),
      );
    });
  });

  group('EpisodeVideoUploadRepository.uploadVideo', () {
    test(
      'posts multipart file field without loading entire file into memory',
      () async {
        http.BaseRequest? capturedRequest;
        final client = _RecordingHttpClient((request) async {
          capturedRequest = request;
          return http.StreamedResponse(
            Stream.value(utf8.encode('{"success":true}')),
            200,
          );
        });

        final repository = EpisodeVideoUploadRepository(
          httpClient: client,
          now: () => DateTime.utc(2026, 1, 1),
        );

        await repository.uploadVideo(
          ticket: _testTicket(episodeId: episodeId),
          file: _testFile(size: 4),
        );

        expect(client.sendCount, 1);
        expect(capturedRequest, isA<http.MultipartRequest>());
        final multipart = capturedRequest! as http.MultipartRequest;
        expect(multipart.method, 'POST');
        expect(multipart.files.single.field, 'file');
        expect(multipart.files.single.filename, 'episode-1.mp4');
      },
    );
  });

  group('AdminEpisode upload eligibility', () {
    test('blocks upload when video uid exists', () {
      final episode = AdminEpisode.fromMap({
        'id': episodeId,
        'series_id': '22222222-2222-2222-2222-222222222222',
        'episode_number': 1,
        'title': 'Bölüm',
        'synopsis': '',
        'cloudflare_stream_uid': 'uid-1',
        'cloudflare_stream_status': 'processing',
        'is_free': true,
        'coin_price': 0,
        'is_published': false,
        'total_views': 0,
      });

      expect(episode.allowsVideoUpload, isFalse);
    });

    test('allows upload only for none status without uid', () {
      final episode = AdminEpisode.fromMap({
        'id': episodeId,
        'series_id': '22222222-2222-2222-2222-222222222222',
        'episode_number': 1,
        'title': 'Bölüm',
        'synopsis': '',
        'cloudflare_stream_uid': null,
        'cloudflare_stream_status': 'none',
        'is_free': true,
        'coin_price': 0,
        'is_published': false,
        'total_views': 0,
      });

      expect(episode.allowsVideoUpload, isTrue);
    });

    test('blocks upload for ready and error statuses even without uid', () {
      for (final status in ['ready', 'error', 'processing']) {
        final episode = AdminEpisode.fromMap({
          'id': episodeId,
          'series_id': '22222222-2222-2222-2222-222222222222',
          'episode_number': 1,
          'title': 'Bölüm',
          'synopsis': '',
          'cloudflare_stream_uid': null,
          'cloudflare_stream_status': status,
          'is_free': true,
          'coin_price': 0,
          'is_published': false,
          'total_views': 0,
        });

        expect(episode.allowsVideoUpload, isFalse);
      }
    });
  });
}
