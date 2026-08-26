enum PartnerStatus {
  active('active', 'Aktif'),
  suspended('suspended', 'Askıda'),
  ended('ended', 'Sonlandırılmış');

  const PartnerStatus(this.value, this.label);

  final String value;
  final String label;

  static PartnerStatus parse(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'active' => PartnerStatus.active,
      'suspended' => PartnerStatus.suspended,
      'ended' => PartnerStatus.ended,
      _ => throw FormatException('partner status is invalid.'),
    };
  }

  static PartnerStatus? tryParse(dynamic value) {
    try {
      return parse(value);
    } on FormatException {
      return null;
    }
  }
}

enum PartnerMemberStatus {
  active('active', 'Aktif'),
  suspended('suspended', 'Askıda'),
  ended('ended', 'Sonlandırılmış');

  const PartnerMemberStatus(this.value, this.label);

  final String value;
  final String label;

  static PartnerMemberStatus parse(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'active' => PartnerMemberStatus.active,
      'suspended' => PartnerMemberStatus.suspended,
      'ended' => PartnerMemberStatus.ended,
      _ => throw FormatException('member status is invalid.'),
    };
  }
}

enum PartnerAnalyticsPreset {
  total('total', 'Toplam'),
  today('today', 'Bugün'),
  yesterday('yesterday', 'Dün'),
  last7Days('last_7_days', 'Son 7 Gün'),
  thisWeek('this_week', 'Bu Hafta'),
  previousWeek('previous_week', 'Geçen Hafta'),
  last30Days('last_30_days', 'Son 30 Gün'),
  thisMonth('this_month', 'Bu Ay'),
  previousMonth('previous_month', 'Geçen Ay'),
  custom('custom', 'Özel Aralık');

  const PartnerAnalyticsPreset(this.value, this.label);

  final String value;
  final String label;

  bool get requiresCustomDates => this == PartnerAnalyticsPreset.custom;
}

enum PartnerDataIntegrityStatus {
  healthy('healthy', 'Sağlıklı'),
  warning('warning', 'Uyarı'),
  unavailable('unavailable', 'Kullanılamıyor');

  const PartnerDataIntegrityStatus(this.value, this.label);

  final String value;
  final String label;

  static PartnerDataIntegrityStatus parse(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'healthy' => PartnerDataIntegrityStatus.healthy,
      'warning' => PartnerDataIntegrityStatus.warning,
      'unavailable' => PartnerDataIntegrityStatus.unavailable,
      _ => throw FormatException('data_integrity_status is invalid.'),
    };
  }

  static PartnerDataIntegrityStatus? tryParse(dynamic value) {
    if (value == null) {
      return null;
    }
    return parse(value);
  }
}
