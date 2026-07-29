import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_episode.dart';

enum EpisodeVideoUploadFailureKind {
  sessionExpired,
  adminRequired,
  episodeNotFound,
  episodeAlreadyHasVideo,
  invalidVideoFile,
  fileTooLarge,
  ticketCreationFailed,
  ticketExpired,
  cloudflareUploadFailed,
  attachFailed,
  networkError,
  unknown,
}

class EpisodeVideoUploadException implements Exception {
  EpisodeVideoUploadException({
    required this.message,
    required this.kind,
    this.canRetryAttach = false,
    this.pendingStreamUid,
  });

  final String message;
  final EpisodeVideoUploadFailureKind kind;
  final bool canRetryAttach;
  final String? pendingStreamUid;

  @override
  String toString() => message;
}

class EpisodeVideoUploadPartialSuccess implements Exception {
  EpisodeVideoUploadPartialSuccess({
    required this.message,
    required this.streamUid,
  });

  final String message;
  final String streamUid;

  @override
  String toString() => message;
}

abstract final class EpisodeVideoUploadErrorMapper {
  static EpisodeVideoUploadException fromFunctionResponse({
    required int status,
    required dynamic data,
  }) {
    final errorText = _extractErrorMessage(data).toLowerCase();

    if (status == 401 ||
        errorText.contains('unauthorized') ||
        errorText.contains('authorization required')) {
      return EpisodeVideoUploadException(
        message: 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
        kind: EpisodeVideoUploadFailureKind.sessionExpired,
      );
    }

    if (status == 403 || errorText.contains('forbidden')) {
      return EpisodeVideoUploadException(
        message: 'Bu işlem için admin yetkisi gerekli.',
        kind: EpisodeVideoUploadFailureKind.adminRequired,
      );
    }

    if (status == 404 || errorText.contains('episode not found')) {
      return EpisodeVideoUploadException(
        message: 'Bölüm bulunamadı.',
        kind: EpisodeVideoUploadFailureKind.episodeNotFound,
      );
    }

    if (status == 409 ||
        errorText.contains('already has an attached stream video')) {
      return EpisodeVideoUploadException(
        message: 'Bu bölümde zaten bir video var.',
        kind: EpisodeVideoUploadFailureKind.episodeAlreadyHasVideo,
      );
    }

    return EpisodeVideoUploadException(
      message: 'Yükleme bağlantısı oluşturulamadı. Lütfen tekrar deneyin.',
      kind: EpisodeVideoUploadFailureKind.ticketCreationFailed,
    );
  }

  static EpisodeVideoUploadException fromPostgrest(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    if (message.contains('authentication required') ||
        message.contains('jwt')) {
      return EpisodeVideoUploadException(
        message: 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
        kind: EpisodeVideoUploadFailureKind.sessionExpired,
      );
    }

    if (message.contains('admin access required')) {
      return EpisodeVideoUploadException(
        message: 'Bu işlem için admin yetkisi gerekli.',
        kind: EpisodeVideoUploadFailureKind.adminRequired,
      );
    }

    if (message.contains('episode not found')) {
      return EpisodeVideoUploadException(
        message: 'Bölüm bulunamadı.',
        kind: EpisodeVideoUploadFailureKind.episodeNotFound,
      );
    }

    if (code == '23505' ||
        message.contains('already has an attached stream video')) {
      return EpisodeVideoUploadException(
        message: 'Bu bölümde zaten bir video var.',
        kind: EpisodeVideoUploadFailureKind.episodeAlreadyHasVideo,
      );
    }

    return EpisodeVideoUploadException(
      message:
          'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.',
      kind: EpisodeVideoUploadFailureKind.attachFailed,
      canRetryAttach: true,
    );
  }

  static String _extractErrorMessage(dynamic data) {
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    return data?.toString() ?? '';
  }
}

AdminEpisode parseAttachEpisodeResult(dynamic result) {
  if (result is! Map<String, dynamic>) {
    throw EpisodeVideoUploadException(
      message:
          'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.',
      kind: EpisodeVideoUploadFailureKind.attachFailed,
      canRetryAttach: true,
    );
  }

  try {
    return AdminEpisode.fromMap(result);
  } on FormatException {
    throw EpisodeVideoUploadException(
      message:
          'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.',
      kind: EpisodeVideoUploadFailureKind.attachFailed,
      canRetryAttach: true,
    );
  }
}
