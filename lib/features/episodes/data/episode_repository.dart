import 'package:supabase_flutter/supabase_flutter.dart';

import '../../content/data/content_errors.dart';
import '../domain/admin_episode.dart';
import '../domain/create_episode_input.dart';
import '../domain/update_episode_input.dart';

class EpisodeRepository {
  EpisodeRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  static const _episodeSelect = '''
    id,
    series_id,
    episode_number,
    title,
    synopsis,
    thumbnail_path,
    cloudflare_stream_uid,
    cloudflare_stream_status,
    cloudflare_stream_pending_uid,
    cloudflare_stream_pending_status,
    cloudflare_stream_pending_requested_at,
    cloudflare_stream_last_checked_at,
    duration_seconds,
    is_free,
    coin_price,
    is_published,
    is_archived,
    archived_at,
    content_version,
    total_views,
    release_at,
    created_at,
    updated_at
  ''';

  Future<List<AdminEpisode>> fetchEpisodesForSeries(String seriesId) async {
    final response = await _resolvedClient
        .from('episodes')
        .select(_episodeSelect)
        .eq('series_id', seriesId)
        .order('episode_number', ascending: true)
        .order('created_at', ascending: true);

    final rows = response as List<dynamic>;

    return rows
        .map((row) => AdminEpisode.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<AdminEpisode> fetchById(String episodeId) async {
    final response = await _resolvedClient
        .from('episodes')
        .select(_episodeSelect)
        .eq('id', episodeId)
        .maybeSingle();

    if (response == null) {
      throw const ContentException(
        message: 'Bölüm bulunamadı.',
        kind: ContentFailureKind.notFound,
      );
    }

    return AdminEpisode.fromMap(response);
  }

  Future<AdminEpisode> createEpisode(CreateEpisodeInput input) async {
    try {
      final result = await _resolvedClient.rpc(
        'admin_create_episode',
        params: buildCreateEpisodeRpcParams(input),
      );

      return _parseEpisodeResult(result);
    } on PostgrestException catch (error) {
      throw ContentErrorMapper.fromPostgrest(error);
    } on ContentException {
      rethrow;
    } catch (_) {
      throw const ContentException(
        message: 'Bölüm kaydedilemedi. Lütfen tekrar deneyin.',
        kind: ContentFailureKind.unknown,
      );
    }
  }

  Future<AdminEpisode> updateEpisode(UpdateEpisodeInput input) async {
    try {
      final result = await _resolvedClient.rpc(
        'admin_update_episode',
        params: buildUpdateEpisodeRpcParams(input),
      );

      final row = _parseLifecycleRow(result);
      if (row == null) {
        throw const ContentException(
          message: 'Bölüm yanıtı geçersiz.',
          kind: ContentFailureKind.serverError,
        );
      }

      final episodeId = row['episode_id']?.toString() ?? input.episodeId;
      return fetchById(episodeId);
    } on PostgrestException catch (error) {
      throw ContentErrorMapper.fromPostgrest(error);
    } on ContentException {
      rethrow;
    } catch (_) {
      throw const ContentException(
        message: 'Bölüm güncellenemedi. Lütfen tekrar deneyin.',
        kind: ContentFailureKind.unknown,
      );
    }
  }

  Future<AdminEpisode> publishEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) {
    return _runEpisodeLifecycleMutation(
      rpcName: 'admin_publish_episode',
      params: buildEpisodeLifecycleRpcParams(
        episodeId: episodeId,
        expectedContentVersion: expectedContentVersion,
      ),
    );
  }

  Future<AdminEpisode> unpublishEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) {
    return _runEpisodeLifecycleMutation(
      rpcName: 'admin_unpublish_episode',
      params: buildEpisodeLifecycleRpcParams(
        episodeId: episodeId,
        expectedContentVersion: expectedContentVersion,
      ),
    );
  }

  Future<AdminEpisode> archiveEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) {
    return _runEpisodeLifecycleMutation(
      rpcName: 'admin_archive_episode',
      params: buildEpisodeLifecycleRpcParams(
        episodeId: episodeId,
        expectedContentVersion: expectedContentVersion,
      ),
    );
  }

  Future<AdminEpisode> restoreEpisode({
    required String episodeId,
    required int expectedContentVersion,
  }) {
    return _runEpisodeLifecycleMutation(
      rpcName: 'admin_restore_episode',
      params: buildEpisodeLifecycleRpcParams(
        episodeId: episodeId,
        expectedContentVersion: expectedContentVersion,
      ),
    );
  }

  Future<AdminEpisode> _runEpisodeLifecycleMutation({
    required String rpcName,
    required Map<String, dynamic> params,
  }) async {
    try {
      final result = await _resolvedClient.rpc(rpcName, params: params);
      final row = _parseLifecycleRow(result);
      if (row == null) {
        throw const ContentException(
          message: 'Sunucu yanıtı geçersiz.',
          kind: ContentFailureKind.serverError,
        );
      }

      final episodeId = row['episode_id']?.toString() ?? params['p_episode_id'];
      return fetchById(episodeId.toString());
    } on PostgrestException catch (error) {
      throw ContentErrorMapper.fromPostgrest(error);
    } on ContentException {
      rethrow;
    } catch (_) {
      throw const ContentException(
        message: 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
        kind: ContentFailureKind.unknown,
      );
    }
  }

  AdminEpisode _parseEpisodeResult(dynamic result) {
    if (result is! Map<String, dynamic>) {
      throw const ContentException(
        message: 'Bölüm yanıtı geçersiz.',
        kind: ContentFailureKind.serverError,
      );
    }

    try {
      return AdminEpisode.fromMap(result);
    } on FormatException {
      throw const ContentException(
        message: 'Bölüm yanıtı geçersiz.',
        kind: ContentFailureKind.serverError,
      );
    }
  }

  Map<String, dynamic>? _parseLifecycleRow(dynamic result) {
    if (result is Map<String, dynamic>) {
      return result;
    }

    if (result is List && result.isNotEmpty) {
      final first = result.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }

    return null;
  }
}

@Deprecated('Use ContentException')
typedef EpisodeMutationException = ContentException;
