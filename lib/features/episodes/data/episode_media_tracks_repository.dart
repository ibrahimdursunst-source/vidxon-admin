import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_episode.dart';
import '../domain/duration_warning.dart';
import '../domain/episode_audio_file.dart';
import '../domain/episode_media_tracks.dart';
import '../domain/episode_subtitle_file.dart';
import '../domain/media_locale.dart';
import 'episode_media_tracks_errors.dart';
import 'episode_repository.dart';
import 'upload_progress.dart';

class EpisodeMediaTracksRepository {
  EpisodeMediaTracksRepository({
    this._client,
    http.Client? httpClient,
    this._uploadTimeout = const Duration(minutes: 30),
  }) : _httpClient = httpClient ?? http.Client();

  final SupabaseClient? _client;
  final http.Client _httpClient;
  final Duration _uploadTimeout;

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

  Future<EpisodeMediaTracksSnapshot> listTracks(String episodeId) async {
    try {
      final result = await _supabaseClient.rpc(
        'admin_list_episode_media_tracks',
        params: {'p_episode_id': episodeId},
      );

      if (result is Map<String, dynamic>) {
        return EpisodeMediaTracksSnapshot.fromMap(result);
      }
      if (result is Map) {
        return EpisodeMediaTracksSnapshot.fromMap(
          Map<String, dynamic>.from(result),
        );
      }
      if (result is String) {
        final decoded = jsonDecode(result);
        if (decoded is Map) {
          return EpisodeMediaTracksSnapshot.fromMap(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      throw EpisodeMediaTracksException(
        message: 'Medya parçaları yüklenemedi. Lütfen tekrar deneyin.',
        kind: EpisodeMediaTracksFailureKind.unknown,
      );
    } on PostgrestException catch (error) {
      throw EpisodeMediaTracksErrorMapper.fromPostgrest(error);
    } on EpisodeMediaTracksException {
      rethrow;
    } on FormatException {
      throw EpisodeMediaTracksException(
        message: 'Medya parçaları yanıtı geçersiz.',
        kind: EpisodeMediaTracksFailureKind.unknown,
      );
    } catch (_) {
      throw EpisodeMediaTracksErrorMapper.network();
    }
  }

  Future<AdminEpisode> setOriginalAudioLocale({
    required String episodeId,
    required String locale,
    required int expectedContentVersion,
  }) async {
    final normalized = MediaLocale.normalizeOrNull(locale);
    if (normalized == null) {
      throw EpisodeMediaTracksException(
        message: 'Geçersiz dil kodu. Örnek: tr, en, pt_BR.',
        kind: EpisodeMediaTracksFailureKind.invalidLocale,
      );
    }

    try {
      final result = await _supabaseClient.rpc(
        'admin_set_episode_original_audio_locale',
        params: {
          'p_episode_id': episodeId,
          'p_locale': normalized,
          'p_expected_content_version': expectedContentVersion,
        },
      );

      if (result is Map<String, dynamic>) {
        return AdminEpisode.fromMap(result);
      }
      if (result is Map) {
        return AdminEpisode.fromMap(Map<String, dynamic>.from(result));
      }

      return await EpisodeRepository(
        client: _supabaseClient,
      ).fetchById(episodeId);
    } on PostgrestException catch (error) {
      throw EpisodeMediaTracksErrorMapper.fromPostgrest(error);
    } on EpisodeMediaTracksException {
      rethrow;
    } catch (_) {
      throw EpisodeMediaTracksErrorMapper.network();
    }
  }

  Future<Map<String, dynamic>> uploadAudioTrack({
    required String episodeId,
    required String locale,
    required EpisodeAudioFile file,
    int? audioDurationMs,
    int? videoDurationMs,
    required bool adminDurationOverride,
    void Function(double progress)? onProgress,
  }) {
    DurationWarningResult? warning;
    if (audioDurationMs != null && videoDurationMs != null) {
      warning = classifyDurationWarning(
        audioDurationMs: audioDurationMs,
        videoDurationMs: videoDurationMs,
      );
    }

    return runAudioUploadOrchestration(
      classify: () => warning,
      ensureOverrideAllowed: (level) {
        if (level.requiresExplicitOverride && !adminDurationOverride) {
          throw EpisodeMediaTracksException(
            message:
                'Ciddi süre farkı için onay kutusu işaretlenmeden yükleme yapılamaz.',
            kind: EpisodeMediaTracksFailureKind.severeOverrideRequired,
          );
        }
      },
      upload: (classified) async {
        final normalized = MediaLocale.normalizeOrNull(locale);
        if (normalized == null) {
          throw EpisodeMediaTracksException(
            message: 'Geçersiz dil kodu. Örnek: tr, en, pt_BR.',
            kind: EpisodeMediaTracksFailureKind.invalidLocale,
          );
        }

        final level = classified?.level ?? DurationWarningLevel.none;
        final fields = <String, String>{
          'episodeId': episodeId,
          'locale': normalized,
          'durationWarningLevel': level.apiValue,
          'adminDurationOverride': adminDurationOverride ? 'true' : 'false',
        };

        if (audioDurationMs != null) {
          fields['durationMs'] = audioDurationMs.toString();
        }
        if (classified != null) {
          fields['durationDeltaMs'] = classified.deltaMs.toString();
        }

        return _postMultipart(
          functionName: 'admin-upload-episode-audio',
          fields: fields,
          file: http.MultipartFile(
            'file',
            UploadProgressTracker(
              totalBytes: file.size,
              onProgress: onProgress,
            ).wrap(file.readStream),
            file.size,
            filename: file.name,
            contentType: MediaType.parse(file.contentType),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> reconcileAudio({required String trackId}) {
    return _postJsonAction(
      functionName: 'admin-upload-episode-audio',
      body: {'action': 'reconcile', 'trackId': trackId},
    );
  }

  Future<Map<String, dynamic>> activateAudio({required String trackId}) {
    return _postJsonAction(
      functionName: 'admin-upload-episode-audio',
      body: {'action': 'activate', 'trackId': trackId},
    );
  }

  Future<Map<String, dynamic>> removeAudio({required String trackId}) {
    return _postJsonAction(
      functionName: 'admin-upload-episode-audio',
      body: {'action': 'remove', 'trackId': trackId},
    );
  }

  Future<Map<String, dynamic>> uploadSubtitle({
    required String episodeId,
    required String locale,
    required EpisodeSubtitleFile file,
    void Function(double progress)? onProgress,
  }) async {
    final normalized = MediaLocale.normalizeOrNull(locale);
    if (normalized == null) {
      throw EpisodeMediaTracksException(
        message: 'Geçersiz dil kodu. Örnek: tr, en, pt_BR.',
        kind: EpisodeMediaTracksFailureKind.invalidLocale,
      );
    }

    return _postMultipart(
      functionName: 'admin-upload-episode-subtitle',
      fields: {'episodeId': episodeId, 'locale': normalized},
      file: http.MultipartFile(
        'file',
        UploadProgressTracker(
          totalBytes: file.size,
          onProgress: onProgress,
        ).wrap(file.readStream),
        file.size,
        filename: file.name,
        contentType: MediaType('text', 'vtt'),
      ),
    );
  }

  Future<Map<String, dynamic>> removeSubtitle({required String trackId}) {
    return _postJsonAction(
      functionName: 'admin-upload-episode-subtitle',
      body: {'action': 'remove', 'trackId': trackId},
    );
  }

  Uri _functionsUri(String functionName) {
    final restUri = Uri.parse(_supabaseClient.rest.url);
    final authority = restUri.hasPort
        ? '${restUri.host}:${restUri.port}'
        : restUri.host;
    return Uri.parse(
      '${restUri.scheme}://$authority/functions/v1/$functionName',
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final session = _supabaseClient.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw EpisodeMediaTracksException(
        message: 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
        kind: EpisodeMediaTracksFailureKind.sessionExpired,
      );
    }

    final apikey = _supabaseClient.headers['apikey'] ?? '';
    return {
      'Authorization': 'Bearer $accessToken',
      if (apikey.isNotEmpty) 'apikey': apikey,
    };
  }

  Future<Map<String, dynamic>> _postMultipart({
    required String functionName,
    required Map<String, String> fields,
    required http.MultipartFile file,
  }) async {
    final headers = await _authHeaders();
    final request = http.MultipartRequest('POST', _functionsUri(functionName))
      ..headers.addAll(headers)
      ..fields.addAll(fields)
      ..files.add(file);

    try {
      final streamed = await _httpClient.send(request).timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _parseFunctionHttpResponse(response);
    } on TimeoutException {
      throw EpisodeMediaTracksException(
        message: 'Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.',
        kind: EpisodeMediaTracksFailureKind.networkError,
      );
    } on EpisodeMediaTracksException {
      rethrow;
    } catch (_) {
      throw EpisodeMediaTracksErrorMapper.network();
    }
  }

  Future<Map<String, dynamic>> _postJsonAction({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        functionName,
        body: body,
      );

      if (response.status < 200 || response.status >= 300) {
        throw EpisodeMediaTracksErrorMapper.fromFunctionResponse(
          status: response.status,
          data: response.data,
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return <String, dynamic>{'ok': true};
    } on FunctionException catch (error) {
      throw EpisodeMediaTracksErrorMapper.fromFunctionResponse(
        status: error.status,
        data: error.details,
      );
    } on EpisodeMediaTracksException {
      rethrow;
    } catch (_) {
      throw EpisodeMediaTracksErrorMapper.network();
    }
  }

  Map<String, dynamic> _parseFunctionHttpResponse(http.Response response) {
    dynamic data;
    final body = response.body;
    if (body.isNotEmpty) {
      try {
        data = jsonDecode(body);
      } catch (_) {
        data = body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EpisodeMediaTracksErrorMapper.fromFunctionResponse(
        status: response.statusCode,
        data: data,
      );
    }

    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{'ok': true};
  }
}

@visibleForTesting
Future<Map<String, dynamic>> runAudioUploadOrchestration({
  required DurationWarningResult? Function() classify,
  required void Function(DurationWarningLevel level) ensureOverrideAllowed,
  required Future<Map<String, dynamic>> Function(
    DurationWarningResult? classified,
  )
  upload,
}) async {
  final classified = classify();
  ensureOverrideAllowed(classified?.level ?? DurationWarningLevel.none);
  return upload(classified);
}
