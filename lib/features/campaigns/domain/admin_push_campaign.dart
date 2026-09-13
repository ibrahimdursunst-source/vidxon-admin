import '../../../core/locale/vidxon_product_locales.dart';
import '../../../core/time/admin_local_time.dart';

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
    this.pendingCount = 0,
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
  final int pendingCount;

  /// Display title: first translation title or campaign ID.
  String get displayTitle {
    if (translations.isNotEmpty) return translations.first.title;
    return id;
  }

  /// Admin list/preview body: UI locale if present, else product-locale order.
  String displayBodyForUi(String uiLocale) {
    final withBody = translations
        .where((item) => item.body.trim().isNotEmpty)
        .toList();
    if (withBody.isEmpty) return '';

    for (final item in withBody) {
      if (item.locale == uiLocale) return item.body;
    }
    for (final locale in VidxonProductLocales.all) {
      for (final item in withBody) {
        if (item.locale == locale) return item.body;
      }
    }
    withBody.sort((a, b) => a.locale.compareTo(b.locale));
    return withBody.first.body;
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
      scheduledAt: AdminLocalTime.tryParseUtc(map['scheduled_at']),
      sentAt: AdminLocalTime.tryParseUtc(map['sent_at']),
      createdAt: AdminLocalTime.tryParseUtc(map['created_at']) ??
          DateTime.now().toUtc(),
      updatedAt: AdminLocalTime.tryParseUtc(map['updated_at']) ??
          DateTime.now().toUtc(),
      translations: translations,
      sentCount: _asInt(map['sent_count']),
      failedCount: _asInt(map['failed_count']),
      pendingCount: _asInt(map['pending_count']),
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
  bool get canTestSend => status == 'draft';
  bool get canSchedule => status == 'draft' || status == 'scheduled';
  bool get canCancel => status == 'draft' || status == 'scheduled';

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
