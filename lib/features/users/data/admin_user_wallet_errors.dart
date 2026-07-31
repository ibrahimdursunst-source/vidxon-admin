import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminUserWalletFailureKind {
  sessionExpired,
  adminRequired,
  userNotFound,
  invalidAmount,
  invalidDescription,
  invalidReason,
  transactionLimitExceeded,
  idempotencyConflict,
  networkError,
  serverError,
  unknown,
}

class AdminUserWalletException implements Exception {
  AdminUserWalletException({required this.message, required this.kind});

  final String message;
  final AdminUserWalletFailureKind kind;

  @override
  String toString() => message;
}

abstract final class AdminUserWalletErrorMapper {
  static AdminUserWalletException fromPostgrest(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    if (message.contains('authentication required') ||
        message.contains('jwt expired') ||
        message.contains('invalid jwt')) {
      return AdminUserWalletException(
        message: 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
        kind: AdminUserWalletFailureKind.sessionExpired,
      );
    }

    if (message.contains('admin access required') ||
        message.contains('forbidden')) {
      return AdminUserWalletException(
        message: 'Bu işlem için admin yetkisi gerekli.',
        kind: AdminUserWalletFailureKind.adminRequired,
      );
    }

    if (message.contains('user not found')) {
      return AdminUserWalletException(
        message: 'Kullanıcı bulunamadı.',
        kind: AdminUserWalletFailureKind.userNotFound,
      );
    }

    if (message.contains('invalid amount') ||
        message.contains('amount must be')) {
      return AdminUserWalletException(
        message: 'Geçersiz jeton miktarı.',
        kind: AdminUserWalletFailureKind.invalidAmount,
      );
    }

    if (message.contains('description must be') ||
        message.contains('invalid description')) {
      return AdminUserWalletException(
        message: 'Açıklama geçersiz.',
        kind: AdminUserWalletFailureKind.invalidDescription,
      );
    }

    if (message.contains('invalid reason') || message.contains('reason code')) {
      return AdminUserWalletException(
        message: 'Geçersiz neden seçimi.',
        kind: AdminUserWalletFailureKind.invalidReason,
      );
    }

    if (message.contains('transaction limit') ||
        message.contains('maximum amount')) {
      return AdminUserWalletException(
        message: 'İşlem limiti aşıldı.',
        kind: AdminUserWalletFailureKind.transactionLimitExceeded,
      );
    }

    if (message.contains('idempotency') && message.contains('conflict')) {
      return AdminUserWalletException(
        message:
            'Bu işlem daha önce farklı bilgilerle başlatılmış. Lütfen formu kontrol edip yeniden onaylayın.',
        kind: AdminUserWalletFailureKind.idempotencyConflict,
      );
    }

    if (code == 'PGRST003' || message.contains('timeout')) {
      return AdminUserWalletException(
        message: 'Ağ bağlantısı zaman aşımına uğradı. Lütfen tekrar deneyin.',
        kind: AdminUserWalletFailureKind.networkError,
      );
    }

    return AdminUserWalletException(
      message: 'Beklenmeyen bir sunucu hatası oluştu. Lütfen tekrar deneyin.',
      kind: AdminUserWalletFailureKind.serverError,
    );
  }
}

List<Map<String, dynamic>> parseRpcListResult(dynamic result) {
  if (result is! List) {
    throw AdminUserWalletException(
      message: 'Sunucu yanıtı geçersiz.',
      kind: AdminUserWalletFailureKind.serverError,
    );
  }

  return result
      .map((item) {
        if (item is! Map) {
          throw AdminUserWalletException(
            message: 'Sunucu yanıtı geçersiz.',
            kind: AdminUserWalletFailureKind.serverError,
          );
        }

        return Map<String, dynamic>.from(item);
      })
      .toList(growable: false);
}

Map<String, dynamic> parseRpcMapResult(
  dynamic result, {
  AdminUserWalletFailureKind emptyResultKind =
      AdminUserWalletFailureKind.serverError,
  String emptyResultMessage = 'Sunucu yanıtı geçersiz.',
}) {
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }

  if (result is List) {
    if (result.isEmpty) {
      throw AdminUserWalletException(
        message: emptyResultMessage,
        kind: emptyResultKind,
      );
    }

    final item = result.first;
    if (item is! Map) {
      throw AdminUserWalletException(
        message: 'Sunucu yanıtı geçersiz.',
        kind: AdminUserWalletFailureKind.serverError,
      );
    }

    return Map<String, dynamic>.from(item);
  }

  throw AdminUserWalletException(
    message: 'Sunucu yanıtı geçersiz.',
    kind: AdminUserWalletFailureKind.serverError,
  );
}
