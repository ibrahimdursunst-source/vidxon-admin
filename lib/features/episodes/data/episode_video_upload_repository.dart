import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_episode.dart';
import '../domain/episode_video_file.dart';
import '../domain/stream_upload_ticket.dart';
import '../domain/update_episode_input.dart';
import 'episode_repository.dart';
import 'episode_video_upload_errors.dart';
import 'upload_progress.dart';

class EpisodeVideoUploadRepository {
  EpisodeVideoUploadRepository({
    this._client,
    http.Client? httpClient,
    DateTime Function()? now,
    this._uploadTimeout = const Duration(minutes: 60),
  }) : _httpClient = httpClient ?? http.Client(),
       _now = now ?? DateTime.now;

  final SupabaseClient? _client;
  final http.Client _httpClient;
  final DateTime Function() _now;
  final Duration _uploadTimeout;

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

  Future<StreamUploadTicket> createUploadTicket({
    required String episodeId,
    required EpisodeVideoFile file,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'admin-create-stream-upload-url',
        body: buildCreateUploadTicketPayload(episodeId: episodeId, file: file),
      );

      if (response.status != 200) {
        throw EpisodeVideoUploadErrorMapper.fromFunctionResponse(
          status: response.status,
          data: response.data,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw EpisodeVideoUploadException(
          message: 'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
          kind: EpisodeVideoUploadFailureKind.ticketCreationFailed,
        );
      }

      return StreamUploadTicket.fromJson(
        data,
        expectedEpisodeId: episodeId,
        now: _now(),
      );
    } on FunctionException catch (error) {
      throw EpisodeVideoUploadErrorMapper.fromFunctionResponse(
        status: error.status,
        data: error.details,
      );
    } on EpisodeVideoUploadException {
      rethrow;
    } on FormatException {
      throw EpisodeVideoUploadException(
        message: 'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.ticketCreationFailed,
      );
    } catch (_) {
      throw EpisodeVideoUploadException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.networkError,
      );
    }
  }

  Future<void> uploadVideo({
    required StreamUploadTicket ticket,
    required EpisodeVideoFile file,
    void Function(double progress)? onProgress,
  }) async {
    if (ticket.isExpiredAt(_now().toUtc())) {
      throw EpisodeVideoUploadException(
        message: 'Yükleme bağlantısının süresi doldu. Lütfen tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.ticketExpired,
      );
    }

    final tracker = UploadProgressTracker(
      totalBytes: file.size,
      onProgress: onProgress,
    );

    final request = http.MultipartRequest('POST', Uri.parse(ticket.uploadUrl))
      ..files.add(
        http.MultipartFile(
          ticket.requiredFieldName,
          tracker.wrap(file.readStream),
          file.size,
          filename: file.name,
          contentType: MediaType.parse(file.contentType),
        ),
      );

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_uploadTimeout);

      if (streamedResponse.statusCode >= 300 &&
          streamedResponse.statusCode < 400) {
        throw EpisodeVideoUploadException(
          message: 'Video yüklemesi başarısız oldu. Lütfen tekrar deneyin.',
          kind: EpisodeVideoUploadFailureKind.cloudflareUploadFailed,
        );
      }

      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        onProgress?.call(1);
        return;
      }

      throw EpisodeVideoUploadException(
        message: 'Video yüklemesi başarısız oldu. Lütfen tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.cloudflareUploadFailed,
      );
    } on TimeoutException {
      throw EpisodeVideoUploadException(
        message: 'Video yüklemesi zaman aşımına uğradı. Lütfen tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.networkError,
      );
    } on EpisodeVideoUploadException {
      rethrow;
    } catch (_) {
      throw EpisodeVideoUploadException(
        message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.networkError,
      );
    }
  }

  Future<AdminEpisode> attachVideo({
    required String episodeId,
    required String streamUid,
    required int expectedContentVersion,
  }) async {
    try {
      await _supabaseClient.rpc(
        'admin_attach_episode_stream_video',
        params: buildAttachStreamVideoRpcParams(
          episodeId: episodeId,
          streamUid: streamUid,
          expectedContentVersion: expectedContentVersion,
        ),
      );

      return _fetchEpisode(episodeId);
    } on PostgrestException catch (error) {
      final mapped = EpisodeVideoUploadErrorMapper.fromPostgrest(error);
      throw EpisodeVideoUploadException(
        message: mapped.message,
        kind: mapped.kind,
        canRetryAttach: mapped.canRetryAttach,
        pendingStreamUid: streamUid,
      );
    } on EpisodeVideoUploadException {
      rethrow;
    } catch (_) {
      throw EpisodeVideoUploadException(
        message:
            'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.attachFailed,
        canRetryAttach: true,
        pendingStreamUid: streamUid,
      );
    }
  }

  Future<AdminEpisode> requestStreamReplacement({
    required String episodeId,
    required String streamUid,
    required int expectedContentVersion,
  }) async {
    try {
      await _supabaseClient.rpc(
        'admin_request_episode_stream_replacement',
        params: buildRequestStreamReplacementRpcParams(
          episodeId: episodeId,
          streamUid: streamUid,
          expectedContentVersion: expectedContentVersion,
        ),
      );

      return _fetchEpisode(episodeId);
    } on PostgrestException catch (error) {
      final mapped = EpisodeVideoUploadErrorMapper.fromPostgrest(error);
      throw EpisodeVideoUploadException(
        message: mapped.message,
        kind: mapped.kind,
        canRetryAttach: mapped.canRetryAttach,
        pendingStreamUid: streamUid,
      );
    } on EpisodeVideoUploadException {
      rethrow;
    } catch (_) {
      throw EpisodeVideoUploadException(
        message:
            'Video değişim isteği kaydedilemedi. Bağlama işlemini tekrar deneyin.',
        kind: EpisodeVideoUploadFailureKind.attachFailed,
        canRetryAttach: true,
        pendingStreamUid: streamUid,
      );
    }
  }

  Future<AdminEpisode> _fetchEpisode(String episodeId) async {
    final repository = EpisodeRepository(client: _supabaseClient);
    return repository.fetchById(episodeId);
  }

  Future<AdminEpisode> uploadEpisodeVideo({
    required String episodeId,
    required EpisodeVideoFile file,
    required int expectedContentVersion,
    void Function(double progress)? onUploadProgress,
  }) {
    return runEpisodeVideoUploadSteps(
      createTicket: () => createUploadTicket(episodeId: episodeId, file: file),
      uploadVideoStep: (ticket) =>
          uploadVideo(ticket: ticket, file: file, onProgress: onUploadProgress),
      attachVideoStep: (streamUid) => attachVideo(
        episodeId: episodeId,
        streamUid: streamUid,
        expectedContentVersion: expectedContentVersion,
      ),
    );
  }

  Future<AdminEpisode> replaceEpisodeVideo({
    required String episodeId,
    required EpisodeVideoFile file,
    required int expectedContentVersion,
    void Function(double progress)? onUploadProgress,
  }) {
    return runEpisodeVideoUploadSteps(
      createTicket: () => createUploadTicket(episodeId: episodeId, file: file),
      uploadVideoStep: (ticket) =>
          uploadVideo(ticket: ticket, file: file, onProgress: onUploadProgress),
      attachVideoStep: (streamUid) => requestStreamReplacement(
        episodeId: episodeId,
        streamUid: streamUid,
        expectedContentVersion: expectedContentVersion,
      ),
    );
  }
}

@visibleForTesting
Future<AdminEpisode> runEpisodeVideoUploadSteps({
  required Future<StreamUploadTicket> Function() createTicket,
  required Future<void> Function(StreamUploadTicket ticket) uploadVideoStep,
  required Future<AdminEpisode> Function(String streamUid) attachVideoStep,
}) async {
  final ticket = await createTicket();
  await uploadVideoStep(ticket);
  return attachVideoStep(ticket.uid);
}
