import 'admin_coin_credit_reason.dart';

abstract final class WalletLedgerDisplay {
  static String transactionTypeLabel(String transactionType) {
    return switch (transactionType.trim()) {
      'episode_unlock' => 'Bölüm Açma',
      'rewarded_ad' => 'Reklam Ödülü',
      'admin_coin_credit' => 'Admin Jeton Yükleme',
      'admin_test_credit' => 'Eski Test Kredisi',
      _ => transactionType.trim(),
    };
  }

  static String reasonLabel(String? reasonCode) {
    if (reasonCode == null || reasonCode.trim().isEmpty) {
      return '—';
    }

    return AdminCoinCreditReason.labelFor(reasonCode);
  }

  static String optionalText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '—';
    }

    return value.trim();
  }

  static String balanceBeforeLabel(int? balanceBefore) {
    if (balanceBefore == null) {
      return '—';
    }

    return balanceBefore.toString();
  }

  static String actorLabel(String? actorAdminUserId) {
    if (actorAdminUserId == null || actorAdminUserId.trim().isEmpty) {
      return 'Sistem';
    }

    return actorAdminUserId.trim();
  }
}
