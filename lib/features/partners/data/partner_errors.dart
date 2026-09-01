import 'package:supabase_flutter/supabase_flutter.dart';

enum PartnerFailureKind {
  sessionExpired,
  adminRequired,
  notFound,
  validation,
  conflict,
  duplicateMember,
  inactivePartner,
  serverError,
  networkError,
  parseError,
  unknown,
}

class PartnerException implements Exception {
  const PartnerException({required this.message, required this.kind});

  final String message;
  final PartnerFailureKind kind;

  @override
  String toString() => message;
}

abstract final class PartnerErrorMapper {
  static PartnerException fromPostgrest(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    if (message.contains('authentication required') ||
        message.contains('jwt expired') ||
        message.contains('invalid jwt')) {
      return const PartnerException(
        message: 'Oturumunuz doğrulanamadı. Yeniden giriş yapın.',
        kind: PartnerFailureKind.sessionExpired,
      );
    }

    if (message.contains('admin access required') ||
        message.contains('forbidden')) {
      return const PartnerException(
        message: 'Bu işlem için admin yetkisi gerekiyor.',
        kind: PartnerFailureKind.adminRequired,
      );
    }

    if (message.contains('partner not found') ||
        message.contains('user not found') ||
        message.contains('series not found')) {
      return const PartnerException(
        message: 'Kayıt bulunamadı.',
        kind: PartnerFailureKind.notFound,
      );
    }

    if (message.contains('duplicate') ||
        message.contains('already an active member') ||
        message.contains('already a member')) {
      return const PartnerException(
        message: 'Kullanıcı bu Partner için zaten aktif üye.',
        kind: PartnerFailureKind.duplicateMember,
      );
    }

    if (message.contains('suspended') ||
        message.contains('ended partner') ||
        message.contains('inactive partner') ||
        message.contains('partner is not active')) {
      return const PartnerException(
        message: 'Askıdaki veya sonlandırılmış Partner’a atama yapılamaz.',
        kind: PartnerFailureKind.inactivePartner,
      );
    }

    if (code == '40001' ||
        message.contains('content was modified by another admin') ||
        message.contains('content_version')) {
      return const PartnerException(
        message:
            'Bu içerik başka bir yönetici tarafından değiştirildi. '
            'Güncel veriler yeniden yüklendi; lütfen tekrar deneyin.',
        kind: PartnerFailureKind.conflict,
      );
    }

    if (message.contains('invalid') || message.contains('must be')) {
      return PartnerException(
        message: error.message.isNotEmpty ? error.message : 'Geçersiz istek.',
        kind: PartnerFailureKind.validation,
      );
    }

    if (code == 'PGRST003' || message.contains('timeout')) {
      return const PartnerException(
        message: 'Ağ bağlantısı zaman aşımına uğradı. Lütfen tekrar deneyin.',
        kind: PartnerFailureKind.networkError,
      );
    }

    return const PartnerException(
      message: 'Beklenmeyen bir sunucu hatası oluştu. Lütfen tekrar deneyin.',
      kind: PartnerFailureKind.serverError,
    );
  }

  static PartnerException parseFailure([String? detail]) {
    return PartnerException(
      message: detail == null || detail.isEmpty
          ? 'Partner yanıtı geçersiz. Rapor yüklenemedi.'
          : 'Partner yanıtı geçersiz: $detail',
      kind: PartnerFailureKind.parseError,
    );
  }
}

abstract final class PartnerRpcEnvelope {
  static Map<String, dynamic> parseSuccessObject(dynamic result) {
    final envelope = _requireEnvelopeMap(result);
    _requireOkTrue(envelope);
    return envelope;
  }

  static List<Map<String, dynamic>> parseSuccessList(
    dynamic result, {
    required String listKey,
  }) {
    final envelope = parseSuccessObject(result);
    if (!envelope.containsKey(listKey)) {
      throw PartnerErrorMapper.parseFailure('$listKey is required.');
    }

    final payload = envelope[listKey];
    if (payload is! List) {
      throw PartnerErrorMapper.parseFailure('$listKey is invalid.');
    }

    return payload
        .map((item) {
          if (item is! Map) {
            throw PartnerErrorMapper.parseFailure('$listKey item is invalid.');
          }
          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }

  static Map<String, dynamic> _requireEnvelopeMap(dynamic result) {
    if (result is! Map) {
      throw const PartnerException(
        message: 'Sunucu yanıtı geçersiz.',
        kind: PartnerFailureKind.serverError,
      );
    }
    return Map<String, dynamic>.from(result);
  }

  static void _requireOkTrue(Map<String, dynamic> envelope) {
    if (!envelope.containsKey('ok')) {
      throw PartnerErrorMapper.parseFailure('ok is required.');
    }

    if (envelope['ok'] != true) {
      throw const PartnerException(
        message: 'Sunucu yanıtı geçersiz.',
        kind: PartnerFailureKind.serverError,
      );
    }
  }
}

List<Map<String, dynamic>> parsePartnerRpcList(
  dynamic result, {
  required String listKey,
}) {
  return PartnerRpcEnvelope.parseSuccessList(result, listKey: listKey);
}

Map<String, dynamic> parsePartnerRpcMap(dynamic result) {
  return PartnerRpcEnvelope.parseSuccessObject(result);
}
