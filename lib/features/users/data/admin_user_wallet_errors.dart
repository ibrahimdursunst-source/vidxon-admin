import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminUserWalletFailureKind {
  sessionExpired,
  adminRequired,
  superAdminRequired,
  userNotFound,
  invalidAmount,
  invalidDescription,
  invalidReason,
  transactionLimitExceeded,
  idempotencyConflict,
  protectedAdminWallet,
  insufficientBalance,
  invalidRole,
  selfDemotion,
  selfRevoke,
  lastSuperAdmin,
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
        message: 'Oturumunuz doğrulanamadı. Yeniden giriş yapın.',
        kind: AdminUserWalletFailureKind.sessionExpired,
      );
    }

    if (message.contains('super admin access required')) {
      return AdminUserWalletException(
        message: 'Bu işlem için Super Admin yetkisi gerekiyor.',
        kind: AdminUserWalletFailureKind.superAdminRequired,
      );
    }

    if (message.contains('admin access required') ||
        message.contains('forbidden')) {
      return AdminUserWalletException(
        message: 'Bu işlem için admin yetkisi gerekiyor.',
        kind: AdminUserWalletFailureKind.adminRequired,
      );
    }

    if (message.contains('admin accounts are protected')) {
      return AdminUserWalletException(
        message: 'Admin hesaplarında manuel jeton işlemleri yapılamaz.',
        kind: AdminUserWalletFailureKind.protectedAdminWallet,
      );
    }

    if (message.contains('insufficient wallet balance') ||
        message.contains('insufficient balance')) {
      return AdminUserWalletException(
        message: 'Kullanıcının bakiyesi bu işlem için yetersiz.',
        kind: AdminUserWalletFailureKind.insufficientBalance,
      );
    }

    if (message.contains('cannot remove the last super admin')) {
      return AdminUserWalletException(
        message: 'Son Super Admin kaldırılamaz.',
        kind: AdminUserWalletFailureKind.lastSuperAdmin,
      );
    }

    if (message.contains('cannot demote their own role') ||
        message.contains('cannot revoke their own access')) {
      if (message.contains('revoke')) {
        return AdminUserWalletException(
          message: 'Kendi admin erişiminizi kaldıramazsınız.',
          kind: AdminUserWalletFailureKind.selfRevoke,
        );
      }

      return AdminUserWalletException(
        message: 'Kendi rolünüzü düşüremezsiniz.',
        kind: AdminUserWalletFailureKind.selfDemotion,
      );
    }

    if (message.contains('invalid admin role')) {
      return AdminUserWalletException(
        message: 'Geçersiz admin rolü.',
        kind: AdminUserWalletFailureKind.invalidRole,
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
        message: 'İşlem isteği çakıştı. Formu kontrol edip yeniden deneyin.',
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

  static AdminUserWalletException fromPostgrestForWalletMutation(
    PostgrestException error,
  ) {
    final mapped = fromPostgrest(error);

    if (mapped.kind == AdminUserWalletFailureKind.superAdminRequired) {
      return AdminUserWalletException(
        message: 'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.',
        kind: mapped.kind,
      );
    }

    return mapped;
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

void parseRpcVoidResult(dynamic result) {
  if (result == null) {
    return;
  }

  if (result is List && result.isEmpty) {
    return;
  }
}
