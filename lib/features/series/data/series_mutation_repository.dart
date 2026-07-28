import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/create_series_input.dart';

class SeriesMutationException implements Exception {
  SeriesMutationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SeriesMutationRepository {
  SeriesMutationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> createSeries(CreateSeriesInput input) async {
    try {
      final result = await _client.rpc(
        'admin_create_series',
        params: buildCreateSeriesRpcParams(input),
      );

      final seriesId = result?.toString().trim();
      if (seriesId == null || seriesId.isEmpty) {
        throw SeriesMutationException('Dizi kaydedildi ancak yanıt geçersiz.');
      }

      return seriesId;
    } on PostgrestException catch (error) {
      throw SeriesMutationException(_mapPostgrestError(error));
    } catch (error) {
      if (error is SeriesMutationException) {
        rethrow;
      }

      throw SeriesMutationException(
        'Dizi kaydedilemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  String _mapPostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    if (code == '23505' ||
        message.contains('duplicate') ||
        message.contains('unique')) {
      return 'Bu slug zaten kullanılıyor. Farklı bir slug deneyin.';
    }

    if (message.contains('slug must use only lowercase letters')) {
      return 'Slug yalnızca küçük harf, rakam ve tire içerebilir.';
    }

    if (message.contains('slug is required')) {
      return 'Slug alanı zorunludur.';
    }

    if (message.contains('title is required')) {
      return 'Başlık alanı zorunludur.';
    }

    if (message.contains('poster path is required')) {
      return 'Poster yüklenmesi zorunludur.';
    }

    if (message.contains('invalid status')) {
      return 'Seçilen durum geçersiz.';
    }

    if (message.contains('category ids are invalid')) {
      return 'Seçilen kategorilerden biri geçersiz.';
    }

    if (message.contains('admin access required') ||
        message.contains('authentication required')) {
      return 'Bu işlem için admin oturumu gerekli.';
    }

    return 'Dizi kaydedilemedi. Lütfen bilgileri kontrol edip tekrar deneyin.';
  }
}
