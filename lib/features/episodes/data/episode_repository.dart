import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_episode.dart';
import '../domain/create_episode_input.dart';
import '../domain/update_episode_input.dart';

class EpisodeMutationException implements Exception {
  EpisodeMutationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EpisodeRepository {
  EpisodeRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _episodeSelect = '''
    id,
    series_id,
    episode_number,
    title,
    synopsis,
    thumbnail_path,
    cloudflare_stream_uid,
    duration_seconds,
    is_free,
    coin_price,
    is_published,
    total_views,
    release_at,
    created_at,
    updated_at
  ''';

  Future<List<AdminEpisode>> fetchEpisodesForSeries(String seriesId) async {
    final response = await _client
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

  Future<AdminEpisode> createEpisode(CreateEpisodeInput input) async {
    try {
      final result = await _client.rpc(
        'admin_create_episode',
        params: buildCreateEpisodeRpcParams(input),
      );

      return _parseEpisodeResult(result);
    } on PostgrestException catch (error) {
      throw EpisodeMutationException(_mapPostgrestError(error));
    } catch (error) {
      if (error is EpisodeMutationException) {
        rethrow;
      }

      throw EpisodeMutationException(
        'Bölüm kaydedilemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  Future<AdminEpisode> updateEpisode(UpdateEpisodeInput input) async {
    try {
      final result = await _client.rpc(
        'admin_update_episode',
        params: buildUpdateEpisodeRpcParams(input),
      );

      return _parseEpisodeResult(result);
    } on PostgrestException catch (error) {
      throw EpisodeMutationException(_mapPostgrestError(error));
    } catch (error) {
      if (error is EpisodeMutationException) {
        rethrow;
      }

      throw EpisodeMutationException(
        'Bölüm güncellenemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  AdminEpisode _parseEpisodeResult(dynamic result) {
    if (result is! Map<String, dynamic>) {
      throw EpisodeMutationException('Bölüm yanıtı geçersiz.');
    }

    try {
      return AdminEpisode.fromMap(result);
    } on FormatException {
      throw EpisodeMutationException('Bölüm yanıtı geçersiz.');
    }
  }

  String _mapPostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    if (code == '23505' || message.contains('episode number already exists')) {
      return 'Bu dizi için aynı bölüm numarası zaten kullanılıyor.';
    }

    if (message.contains('episode number must be greater than 0')) {
      return 'Bölüm numarası 0\'dan büyük olmalıdır.';
    }

    if (message.contains('title is required')) {
      return 'Başlık zorunludur.';
    }

    if (message.contains('coin price cannot be negative')) {
      return 'Coin fiyatı negatif olamaz.';
    }

    if (message.contains('free episodes must have a coin price of 0')) {
      return 'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.';
    }

    if (message.contains(
      'published locked episodes must have a coin price greater than 0',
    )) {
      return 'Yayında kilitli bölümlerde coin fiyatı 0\'dan büyük olmalıdır.';
    }

    if (message.contains('series not found')) {
      return 'Dizi bulunamadı.';
    }

    if (message.contains('episode not found')) {
      return 'Bölüm bulunamadı.';
    }

    if (message.contains('admin access required') ||
        message.contains('authentication required')) {
      return 'Bu işlem için admin oturumu gerekli.';
    }

    return 'Bölüm kaydedilemedi. Lütfen bilgileri kontrol edip tekrar deneyin.';
  }
}
