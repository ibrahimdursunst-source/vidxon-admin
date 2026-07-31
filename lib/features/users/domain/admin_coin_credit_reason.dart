enum AdminCoinCreditReason {
  eventReward('event_reward', 'Etkinlik Ödülü'),
  customerSupport('customer_support', 'Müşteri Desteği'),
  technicalIssue('technical_issue', 'Teknik Sorun'),
  promotional('promotional', 'Promosyon'),
  paymentResolution('payment_resolution', 'Ödeme Çözümü'),
  testCredit('test_credit', 'Test Jetonu'),
  other('other', 'Diğer');

  const AdminCoinCreditReason(this.storageValue, this.labelTurkish);

  final String storageValue;
  final String labelTurkish;

  static AdminCoinCreditReason? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim().toLowerCase();
    for (final reason in AdminCoinCreditReason.values) {
      if (reason.storageValue == normalized) {
        return reason;
      }
    }

    return null;
  }

  static AdminCoinCreditReason parseRequired(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Unknown reason code: $value');
    }

    return parsed;
  }

  static String labelFor(String? value) {
    final parsed = tryParse(value);
    if (parsed != null) {
      return parsed.labelTurkish;
    }

    if (value == null || value.trim().isEmpty) {
      return '—';
    }

    return value.trim();
  }
}
