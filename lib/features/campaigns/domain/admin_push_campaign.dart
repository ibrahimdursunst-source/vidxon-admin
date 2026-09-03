/// Translation for a single locale in a push campaign.
class AdminPushTranslation {
  const AdminPushTranslation({
    required this.locale,
    required this.title,
    required this.body,
  });

  final String locale;
  final String title;
  final String body;

  factory AdminPushTranslation.fromMap(Map<String, dynamic> map) {
    return AdminPushTranslation(
      locale: map['locale']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'locale': locale,
        'title': title,
        'body': body,
      };
}

/// Admin push campaign model.
class AdminPushCampaign {
  const AdminPushCampaign({
    required this.id,
    required this.status,
    required this.destinationType,
    this.destinationSeriesId,
    this.destinationEpisodeId,
    required this.targetLocales,
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
    required this.updatedAt,
    required this.translations,
    this.sentCount = 0,
    this.failedCount = 0,
  });

  final String id;
  final String status;
  final String destinationType;
  final String? destinationSeriesId;
  final String? destinationEpisodeId;
  final List<String> targetLocales;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminPushTranslation> translations;
  final int sentCount;
  final int failedCount;

  /// Display title: first translation title or campaign ID.
  String get displayTitle {
    if (translations.isNotEmpty) return translations.first.title;
    return id;
  }

  factory AdminPushCampaign.fromMap(Map<String, dynamic> map) {
    final rawLocales = map['target_locales'];
    final locales = rawLocales is List
        ? rawLocales.map((e) => e.toString()).toList()
        : <String>[];

    final rawTranslations = map['translations'];
    final translations = rawTranslations is List
        ? rawTranslations
            .whereType<Map<String, dynamic>>()
            .map(AdminPushTranslation.fromMap)
            .toList()
        : <AdminPushTranslation>[];

    return AdminPushCampaign(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      destinationType: map['destination_type']?.toString() ?? 'none',
      destinationSeriesId: map['destination_series_id']?.toString(),
      destinationEpisodeId: map['destination_episode_id']?.toString(),
      targetLocales: locales,
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.tryParse(map['scheduled_at'].toString())
          : null,
      sentAt: map['sent_at'] != null
          ? DateTime.tryParse(map['sent_at'].toString())
          : null,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      translations: translations,
      sentCount: (map['sent_count'] is int) ? map['sent_count'] as int : 0,
      failedCount:
          (map['failed_count'] is int) ? map['failed_count'] as int : 0,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Taslak';
      case 'scheduled':
        return 'Planlanmış';
      case 'sending':
        return 'Gönderiliyor';
      case 'sent':
        return 'Gönderildi';
      case 'cancelled':
        return 'İptal Edildi';
      case 'failed':
        return 'Başarısız';
      default:
        return status;
    }
  }

  String get destinationLabel {
    switch (destinationType) {
      case 'series':
        return 'Dizi';
      case 'episode':
        return 'Bölüm';
      case 'coin_purchase':
        return 'Jeton Satın Al';
      case 'membership':
        return 'Üyelik';
      case 'none':
        return 'Bilgilendirme';
      default:
        return destinationType;
    }
  }

  bool get canEdit => status == 'draft' || status == 'scheduled';
  bool get canSend => status == 'draft' || status == 'scheduled';
  bool get canCancel => status == 'draft' || status == 'scheduled';
}
