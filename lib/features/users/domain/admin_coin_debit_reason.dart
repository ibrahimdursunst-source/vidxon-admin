enum AdminCoinDebitReason {
  incorrectCreditReversal('incorrect_credit_reversal'),
  rewardCorrection('reward_correction'),
  customerSupport('customer_support'),
  abuseCorrection('abuse_correction'),
  paymentResolution('payment_resolution'),
  testDebit('test_debit'),
  other('other');

  const AdminCoinDebitReason(this.storageValue);

  final String storageValue;

  String get labelTurkish => switch (this) {
    AdminCoinDebitReason.incorrectCreditReversal =>
      'Yanlış Jeton Yüklemesini Geri Alma',
    AdminCoinDebitReason.rewardCorrection => 'Hatalı Ödül Düzeltmesi',
    AdminCoinDebitReason.customerSupport => 'Müşteri Desteği',
    AdminCoinDebitReason.abuseCorrection => 'Kötüye Kullanım Düzeltmesi',
    AdminCoinDebitReason.paymentResolution => 'Ödeme Sorunu Çözümü',
    AdminCoinDebitReason.testDebit => 'Test Jetonu Eksiltme',
    AdminCoinDebitReason.other => 'Diğer',
  };

  static AdminCoinDebitReason? tryParse(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }

    final normalized = code.trim();
    for (final reason in AdminCoinDebitReason.values) {
      if (reason.storageValue == normalized) {
        return reason;
      }
    }

    return null;
  }

  static String labelFor(String? code) {
    final parsed = tryParse(code);
    if (parsed != null) {
      return parsed.labelTurkish;
    }

    if (code == null || code.trim().isEmpty) {
      return '—';
    }

    return code.trim();
  }
}
