import 'package:supabase_flutter/supabase_flutter.dart';

import '../../content/data/content_errors.dart';
import '../domain/admin_series.dart';
import '../domain/create_series_input.dart';
import '../domain/series_mutation_results.dart';
import '../domain/update_series_input.dart';
import 'series_repository.dart';

class SeriesMutationRepository {
  SeriesMutationRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<AdminSeries> createSeries(CreateSeriesInput input) async {
    try {
      final result = await _resolvedClient.rpc(
        'admin_create_series',
        params: buildCreateSeriesRpcParams(input),
      );

      final seriesId = result?.toString().trim();
      if (seriesId == null || seriesId.isEmpty) {
        throw const ContentException(
          message: 'Dizi kaydedildi ancak yanıt geçersiz.',
          kind: ContentFailureKind.serverError,
        );
      }

      return SeriesRepository(client: _client).fetchById(seriesId);
    } on PostgrestException catch (error) {
      throw ContentErrorMapper.fromPostgrest(error);
    } on ContentException {
      rethrow;
    } catch (_) {
      throw const ContentException(
        message: 'Dizi kaydedilemedi. Lütfen tekrar deneyin.',
        kind: ContentFailureKind.unknown,
      );
    }
  }

  Future<SeriesUpdateResult> updateSeries(UpdateSeriesInput input) async {
    return _runSeriesRowMutation(
      rpcName: 'admin_update_series',
      params: buildUpdateSeriesRpcParams(input),
      parser: SeriesUpdateResult.fromMap,
    );
  }

  Future<SeriesPosterReplaceResult> replacePoster({
    required String seriesId,
    required String posterPath,
    required int expectedContentVersion,
  }) async {
    return _runSeriesRowMutation(
      rpcName: 'admin_replace_series_poster',
      params: buildReplaceSeriesPosterRpcParams(
        seriesId: seriesId,
        posterPath: posterPath,
        expectedContentVersion: expectedContentVersion,
      ),
      parser: SeriesPosterReplaceResult.fromMap,
    );
  }

  Future<SeriesLifecycleResult> publishSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) {
    return _runSeriesRowMutation(
      rpcName: 'admin_publish_series',
      params: buildSeriesLifecycleRpcParams(
        seriesId: seriesId,
        expectedContentVersion: expectedContentVersion,
      ),
      parser: SeriesLifecycleResult.fromMap,
    );
  }

  Future<SeriesLifecycleResult> unpublishSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) {
    return _runSeriesRowMutation(
      rpcName: 'admin_unpublish_series',
      params: buildSeriesLifecycleRpcParams(
        seriesId: seriesId,
        expectedContentVersion: expectedContentVersion,
      ),
      parser: SeriesLifecycleResult.fromMap,
    );
  }

  Future<SeriesLifecycleResult> archiveSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) {
    return _runSeriesRowMutation(
      rpcName: 'admin_archive_series',
      params: buildSeriesLifecycleRpcParams(
        seriesId: seriesId,
        expectedContentVersion: expectedContentVersion,
      ),
      parser: SeriesLifecycleResult.fromMap,
    );
  }

  Future<SeriesLifecycleResult> restoreSeries({
    required String seriesId,
    required int expectedContentVersion,
  }) {
    return _runSeriesRowMutation(
      rpcName: 'admin_restore_series',
      params: buildSeriesLifecycleRpcParams(
        seriesId: seriesId,
        expectedContentVersion: expectedContentVersion,
      ),
      parser: SeriesLifecycleResult.fromMap,
    );
  }

  Future<SeriesReorderResult> reorderEpisodes({
    required String seriesId,
    required List<String> orderedEpisodeIds,
    required int expectedSeriesVersion,
  }) {
    return _runSeriesRowMutation(
      rpcName: 'admin_reorder_series_episodes',
      params: buildReorderSeriesEpisodesRpcParams(
        seriesId: seriesId,
        orderedEpisodeIds: orderedEpisodeIds,
        expectedSeriesVersion: expectedSeriesVersion,
      ),
      parser: SeriesReorderResult.fromMap,
    );
  }

  Future<T> _runSeriesRowMutation<T>({
    required String rpcName,
    required Map<String, dynamic> params,
    required T Function(Map<String, dynamic> map) parser,
  }) async {
    try {
      final result = await _resolvedClient.rpc(rpcName, params: params);
      final row = parseRpcRow(result);
      if (row == null) {
        throw const ContentException(
          message: 'Sunucu yanıtı geçersiz.',
          kind: ContentFailureKind.serverError,
        );
      }

      return parser(row);
    } on PostgrestException catch (error) {
      throw ContentErrorMapper.fromPostgrest(error);
    } on ContentException {
      rethrow;
    } on FormatException {
      throw const ContentException(
        message: 'Sunucu yanıtı geçersiz.',
        kind: ContentFailureKind.serverError,
      );
    } catch (_) {
      throw const ContentException(
        message: 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
        kind: ContentFailureKind.unknown,
      );
    }
  }
}

@Deprecated('Use ContentException')
typedef SeriesMutationException = ContentException;
