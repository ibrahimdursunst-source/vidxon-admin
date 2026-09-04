import 'package:supabase_flutter/supabase_flutter.dart';

import '../../content/data/content_errors.dart';

enum EpisodeMediaTracksFailureKind {
  sessionExpired,
  adminRequired,
  episodeNotFound,
  streamNotReady,
  invalidLocale,
  localeMatchesOriginal,
  originalLocaleHasDub,
  severeOverrideRequired,
  validation,
  conflict,
  networkError,
  uploadFailed,
  notFound,
  unknown,
}

class EpisodeMediaTracksException implements Exception {
  EpisodeMediaTracksException({
    required this.message,
    required this.kind,
    this.isConflict = false,
  });

  final String message;
  final EpisodeMediaTracksFailureKind kind;
  final bool isConflict;

  @override
  String toString() => message;
}

abstract final class EpisodeMediaTracksErrorMapper {
  static EpisodeMediaTracksException fromFunctionResponse({
    required int status,
    required dynamic data,
  }) {
    final errorText = _extractError(data);

    if (status == 401 ||
        errorText.contains('unauthorized') ||
        errorText.contains('authorization required')) {
      return EpisodeMediaTracksException(
        message: 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
        kind: EpisodeMediaTracksFailureKind.sessionExpired,
      );
    }

    if (status == 403 || errorText.contains('forbidden')) {
      return EpisodeMediaTracksException(
        message: 'Bu işlem için admin yetkisi gerekli.',
        kind: EpisodeMediaTracksFailureKind.adminRequired,
      );
    }

    if (status == 404 ||
        errorText.contains('not found') ||
        errorText.contains('episode not found') ||
        errorText.contains('audio track not found') ||
        errorText.contains('subtitle track not found')) {
      return EpisodeMediaTracksException(
        message: 'Kayıt bulunamadı.',
        kind: EpisodeMediaTracksFailureKind.notFound,
      );
    }

    if (status == 409 || errorText.contains('stream video is not ready')) {
      return EpisodeMediaTracksException(
        message: 'Bölüm videosu henüz hazır değil.',
        kind: EpisodeMediaTracksFailureKind.streamNotReady,
      );
    }

    if (errorText.contains('severe duration mismatch')) {
      return EpisodeMediaTracksException(
        message:
            'Ciddi süre farkı için onay kutusu işaretlenmeden yükleme yapılamaz.',
        kind: EpisodeMediaTracksFailureKind.severeOverrideRequired,
      );
    }

    if (errorText.contains('cannot match the original audio locale') ||
        errorText.contains('cannot match original_audio_locale')) {
      return EpisodeMediaTracksException(
        message: 'Dublaj dili orijinal ses diliyle aynı olamaz.',
        kind: EpisodeMediaTracksFailureKind.localeMatchesOriginal,
      );
    }

    if (errorText.contains('locale must match') ||
        errorText.contains('invalid locale') ||
        errorText.contains('invalid request')) {
      return EpisodeMediaTracksException(
        message: 'Geçersiz dil kodu. Örnek: tr, en, pt_BR.',
        kind: EpisodeMediaTracksFailureKind.invalidLocale,
      );
    }

    if (status == 400) {
      return EpisodeMediaTracksException(
        message: 'İstek geçersiz. Lütfen alanları kontrol edin.',
        kind: EpisodeMediaTracksFailureKind.validation,
      );
    }

    if (status >= 500) {
      return EpisodeMediaTracksException(
        message: 'Yükleme başarısız oldu. Lütfen tekrar deneyin.',
        kind: EpisodeMediaTracksFailureKind.uploadFailed,
      );
    }

    return EpisodeMediaTracksException(
      message: 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
      kind: EpisodeMediaTracksFailureKind.unknown,
    );
  }

  static EpisodeMediaTracksException fromPostgrest(PostgrestException error) {
    final content = ContentErrorMapper.fromPostgrest(error);
    if (content.isConflict) {
      return EpisodeMediaTracksException(
        message: content.message,
        kind: EpisodeMediaTracksFailureKind.conflict,
        isConflict: true,
      );
    }

    final lowered = error.message.toLowerCase();
    if (lowered.contains('cannot set original locale while a dub exists')) {
      return EpisodeMediaTracksException(
        message:
            'Bu dilde aktif veya bekleyen bir dublaj varken orijinal dil '
            'olarak ayarlanamaz.',
        kind: EpisodeMediaTracksFailureKind.originalLocaleHasDub,
      );
    }

    if (lowered.contains('invalid locale')) {
      return EpisodeMediaTracksException(
        message: 'Geçersiz dil kodu. Örnek: tr, en, pt_BR.',
        kind: EpisodeMediaTracksFailureKind.invalidLocale,
      );
    }

    if (lowered.contains('forbidden')) {
      return EpisodeMediaTracksException(
        message: 'Bu işlem için admin yetkisi gerekli.',
        kind: EpisodeMediaTracksFailureKind.adminRequired,
      );
    }

    if (lowered.contains('episode not found')) {
      return EpisodeMediaTracksException(
        message: 'Bölüm bulunamadı.',
        kind: EpisodeMediaTracksFailureKind.episodeNotFound,
      );
    }

    return EpisodeMediaTracksException(
      message: content.message,
      kind: EpisodeMediaTracksFailureKind.unknown,
    );
  }

  static EpisodeMediaTracksException network() {
    return EpisodeMediaTracksException(
      message: 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.',
      kind: EpisodeMediaTracksFailureKind.networkError,
    );
  }

  static String _extractError(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is String) {
        return error.trim().toLowerCase();
      }
    }
    if (data is String) {
      return data.trim().toLowerCase();
    }
    return '';
  }
}
