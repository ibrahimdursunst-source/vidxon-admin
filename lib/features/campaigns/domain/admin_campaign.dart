/// Translation for a single locale in a popup campaign.
class AdminCampaignTranslation {
  const AdminCampaignTranslation({
    required this.locale,
    required this.title,
    required this.description,
    this.ctaLabel,
  });

  final String locale;
  final String title;
  final String description;
  final String? ctaLabel;

  factory AdminCampaignTranslation.fromMap(Map<String, dynamic> map) {
    return AdminCampaignTranslation(
      locale: map['locale']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      ctaLabel: map['cta_label']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'locale': locale,
        'title': title,
        'description': description,
        'cta_label': ctaLabel,
      };
}

/// Admin popup campaign model with multi-locale translations.
class AdminCampaign {
  const AdminCampaign({
    required this.id,
    required this.imagePath,
    required this.destinationType,
    this.destinationSeriesId,
    this.destinationEpisodeId,
    required this.targetLocales,
    required this.isActive,
    required this.priority,
    required this.startsAt,
    this.endsAt,
    required this.createdAt,
    required this.updatedAt,
    required this.translations,
  });

  final String id;
  final String imagePath;
  final String destinationType;
  final String? destinationSeriesId;
  final String? destinationEpisodeId;
  final List<String> targetLocales;
  final bool isActive;
  final int priority;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminCampaignTranslation> translations;

  /// Display title: first translation title or campaign ID.
  String get displayTitle {
    if (translations.isNotEmpty) return translations.first.title;
    return id;
  }

  factory AdminCampaign.fromMap(Map<String, dynamic> map) {
    final rawLocales = map['target_locales'];
    final locales = rawLocales is List
        ? rawLocales.map((e) => e.toString()).toList()
        : <String>[];

    final rawTranslations = map['translations'];
    final translations = rawTranslations is List
        ? rawTranslations
            .whereType<Map<String, dynamic>>()
            .map(AdminCampaignTranslation.fromMap)
            .toList()
        : <AdminCampaignTranslation>[];

    return AdminCampaign(
      id: map['id']?.toString() ?? '',
      imagePath: map['image_path']?.toString() ?? '',
      destinationType: map['destination_type']?.toString() ?? 'none',
      destinationSeriesId: map['destination_series_id']?.toString(),
      destinationEpisodeId: map['destination_episode_id']?.toString(),
      targetLocales: locales,
      isActive: map['is_active'] == true,
      priority: (map['priority'] is int) ? map['priority'] as int : 0,
      startsAt: DateTime.tryParse(map['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: map['ends_at'] != null
          ? DateTime.tryParse(map['ends_at'].toString())
          : null,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      translations: translations,
    );
  }

  String get statusLabel {
    if (!isActive) return 'Pasif';
    final now = DateTime.now().toUtc();
    if (startsAt.toUtc().isAfter(now)) return 'Planlanmış';
    if (endsAt != null && endsAt!.toUtc().isBefore(now)) return 'Süresi Dolmuş';
    return 'Aktif';
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
}
