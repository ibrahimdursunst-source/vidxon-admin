import 'package:supabase_flutter/supabase_flutter.dart';

enum ContentFailureKind {
  conflict,
  authRequired,
  adminRequired,
  archived,
  invalidState,
  validation,
  notFound,
  serverError,
  unknown,
}

class ContentException implements Exception {
  const ContentException({
    required this.message,
    required this.kind,
    this.isConflict = false,
  });

  final String message;
  final ContentFailureKind kind;
  final bool isConflict;

  @override
  String toString() => message;
}

abstract final class ContentErrorMapper {
  static const conflictMessage =
      'Bu içerik başka bir yönetici tarafından değiştirildi. '
      'Güncel veriler yeniden yüklendi; lütfen değişikliğinizi tekrar kontrol edin.';

  static const reorderConflictReconciledMessage =
      'İçerik düzenleme sırasında değişti. En güncel sıralama yüklendi.';

  static ContentException fromPostgrest(PostgrestException error) {
    final message = error.message;
    final lowered = message.toLowerCase();
    final code = error.code ?? '';

    if (code == '40001' ||
        lowered.contains('content was modified by another admin')) {
      return const ContentException(
        message: conflictMessage,
        kind: ContentFailureKind.conflict,
        isConflict: true,
      );
    }

    if (lowered.contains('authentication required')) {
      return const ContentException(
        message: 'Bu işlem için oturum açmanız gerekiyor.',
        kind: ContentFailureKind.authRequired,
      );
    }

    if (lowered.contains('admin access required')) {
      return const ContentException(
        message: 'Bu işlem için admin yetkisi gerekiyor.',
        kind: ContentFailureKind.adminRequired,
      );
    }

    if (lowered.contains('archived series cannot be edited') ||
        lowered.contains('archived episodes cannot be edited') ||
        lowered.contains('archived series episodes cannot be edited') ||
        lowered.contains('archived series cannot be published') ||
        lowered.contains('archived episodes cannot be published') ||
        lowered.contains('episodes in archived series cannot be published') ||
        lowered.contains('episodes cannot be created for archived series') ||
        lowered.contains('archived episodes cannot attach') ||
        lowered.contains(
          'archived episodes cannot request stream replacement',
        ) ||
        lowered.contains('episodes in archived series cannot attach') ||
        lowered.contains('episodes in archived series cannot request')) {
      return const ContentException(
        message: 'Arşivlenmiş içerik üzerinde bu işlem yapılamaz.',
        kind: ContentFailureKind.archived,
      );
    }

    if (lowered.contains('series poster is required before publishing')) {
      return const ContentException(
        message: 'Yayınlamadan önce dizi posteri yüklenmelidir.',
        kind: ContentFailureKind.invalidState,
      );
    }

    if (lowered.contains('episode must have an attached stream video') ||
        lowered.contains('stream video must be ready before publishing')) {
      return const ContentException(
        message: 'Yayınlamadan önce bölüm videosu hazır olmalıdır.',
        kind: ContentFailureKind.invalidState,
      );
    }

    if (lowered.contains('episode already has a pending stream replacement') ||
        lowered.contains('pending stream replacement')) {
      return const ContentException(
        message: 'Bu bölüm için zaten devam eden bir video değişimi var.',
        kind: ContentFailureKind.invalidState,
      );
    }

    if (lowered.contains('episode already has an attached stream video')) {
      return const ContentException(
        message: 'Bu bölümde zaten bir video bulunuyor.',
        kind: ContentFailureKind.invalidState,
      );
    }

    if (lowered.contains('series must be created as unpublished') ||
        lowered.contains('episodes must be created as unpublished')) {
      return const ContentException(
        message: 'İçerik yalnızca yayında değil olarak oluşturulabilir.',
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains('expected content version is required')) {
      return const ContentException(
        message:
            'İçerik sürüm bilgisi eksik. Sayfayı yenileyip tekrar deneyin.',
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains('coin price exceeds the maximum allowed limit')) {
      return const ContentException(
        message: 'Coin fiyatı en fazla 10000 olabilir.',
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains('invalid poster path') ||
        lowered.contains('poster path must use the posters namespace') ||
        lowered.contains('poster path must belong to the target series')) {
      return const ContentException(
        message: 'Poster yolu geçersiz.',
        kind: ContentFailureKind.validation,
      );
    }

    if (code == 'P0002' ||
        lowered.contains('series not found') ||
        lowered.contains('episode not found')) {
      return const ContentException(
        message: 'İçerik bulunamadı.',
        kind: ContentFailureKind.notFound,
      );
    }

    if (code == '23505' ||
        lowered.contains('duplicate') ||
        lowered.contains('already exists')) {
      return ContentException(
        message: _duplicateMessage(lowered),
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains('title is required')) {
      return const ContentException(
        message: 'Başlık zorunludur.',
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains('invalid status')) {
      return const ContentException(
        message: 'Seçilen durum geçersiz.',
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains('category ids are invalid')) {
      return const ContentException(
        message: 'Seçilen kategorilerden biri geçersiz.',
        kind: ContentFailureKind.validation,
      );
    }

    if (lowered.contains(
      'reorder list must include all non-archived episodes',
    )) {
      return const ContentException(
        message: 'Sıralama listesi tüm aktif bölümleri içermelidir.',
        kind: ContentFailureKind.validation,
      );
    }

    return const ContentException(
      message: 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
      kind: ContentFailureKind.unknown,
    );
  }

  static ContentException fromFunctionResponse({
    required int status,
    dynamic data,
  }) {
    final errorMessage = _extractFunctionError(data);

    if (status == 401) {
      return const ContentException(
        message: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
        kind: ContentFailureKind.authRequired,
      );
    }

    if (status == 403) {
      return const ContentException(
        message: 'Bu işlem için admin yetkisi gerekiyor.',
        kind: ContentFailureKind.adminRequired,
      );
    }

    if (status == 404) {
      return ContentException(
        message: _previewNotFoundMessage(errorMessage),
        kind: ContentFailureKind.notFound,
      );
    }

    if (status == 409) {
      return ContentException(
        message: _previewNotReadyMessage(errorMessage),
        kind: ContentFailureKind.invalidState,
      );
    }

    return ContentException(
      message:
          errorMessage ??
          'Sunucu isteği başarısız oldu. Lütfen tekrar deneyin.',
      kind: ContentFailureKind.serverError,
    );
  }

  static String? _extractFunctionError(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return _mapFunctionError(error.trim());
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return _mapFunctionError(data.trim());
    }

    return null;
  }

  static String _mapFunctionError(String error) {
    final lowered = error.toLowerCase();

    if (lowered.contains('episode already has a pending stream replacement')) {
      return 'Bu bölüm için zaten devam eden bir video değişimi var.';
    }

    if (lowered.contains('not ready')) {
      return 'Video önizleme için henüz hazır değil.';
    }

    if (lowered.contains('not found')) {
      return 'Video bulunamadı.';
    }

    if (lowered.contains('forbidden')) {
      return 'Bu işlem için admin yetkisi gerekiyor.';
    }

    if (lowered.contains('unauthorized') ||
        lowered.contains('authorization required')) {
      return 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
    }

    return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  }

  static String _duplicateMessage(String lowered) {
    if (lowered.contains('slug')) {
      return 'Bu slug zaten kullanılıyor. Farklı bir slug deneyin.';
    }

    if (lowered.contains('episode number')) {
      return 'Bu dizi için aynı bölüm numarası zaten kullanılıyor.';
    }

    if (lowered.contains('stream uid')) {
      return 'Bu video kimliği başka bir bölümde kullanılıyor.';
    }

    return 'Bu kayıt zaten mevcut.';
  }

  static String _previewNotFoundMessage(String? errorMessage) {
    if (errorMessage != null &&
        errorMessage.toLowerCase().contains('pending')) {
      return 'Bekleyen video bulunamadı.';
    }

    return 'Video bulunamadı.';
  }

  static String _previewNotReadyMessage(String? errorMessage) {
    if (errorMessage != null &&
        errorMessage.toLowerCase().contains('not ready')) {
      return 'Video önizleme için henüz hazır değil.';
    }

    return 'Video şu anda önizlenemiyor.';
  }
}
