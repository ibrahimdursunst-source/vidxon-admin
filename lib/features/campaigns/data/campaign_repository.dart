import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_campaign.dart';

class CampaignException implements Exception {
  CampaignException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CampaignRepository {
  CampaignRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<List<AdminCampaign>> fetchAll() async {
    final response = await _resolvedClient.rpc('admin_list_campaigns_v1');
    final data = response as Map<String, dynamic>;

    if (data['ok'] != true) {
      throw CampaignException('Kampanyalar yüklenemedi.');
    }

    final campaigns = data['campaigns'];
    if (campaigns is! List) return const [];

    return campaigns
        .whereType<Map<String, dynamic>>()
        .map(AdminCampaign.fromMap)
        .toList();
  }

  Future<AdminCampaign> upsert({
    String? id,
    String imagePath = '',
    String destinationType = 'none',
    String? destinationSeriesId,
    String? destinationEpisodeId,
    List<String> targetLocales = const [],
    bool isActive = false,
    int priority = 0,
    required DateTime startsAt,
    DateTime? endsAt,
    required List<AdminCampaignTranslation> translations,
  }) async {
    final params = <String, dynamic>{
      'p_image_path': imagePath,
      'p_destination_type': destinationType,
      'p_destination_series_id': destinationSeriesId,
      'p_destination_episode_id': destinationEpisodeId,
      'p_target_locales': targetLocales,
      'p_is_active': isActive,
      'p_priority': priority,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
      'p_ends_at': endsAt?.toUtc().toIso8601String(),
      'p_translations': translations.map((t) => t.toMap()).toList(),
    };

    if (id != null) {
      params['p_id'] = id;
    }

    final response = await _resolvedClient.rpc(
      'admin_upsert_campaign_v1',
      params: params,
    );

    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      final error = data['error']?.toString() ?? 'unknown';
      throw CampaignException(_humanizeError(error));
    }

    final campaignData = data['campaign'] as Map<String, dynamic>;
    return AdminCampaign.fromMap(campaignData);
  }

  String _humanizeError(String error) {
    if (error.startsWith('missing_translation_for_')) {
      final locale = error.replaceFirst('missing_translation_for_', '');
      return '$locale dili için başlık zorunludur.';
    }
    if (error.startsWith('missing_cta_for_')) {
      final locale = error.replaceFirst('missing_cta_for_', '');
      return '$locale dili için CTA butonu zorunludur.';
    }
    switch (error) {
      case 'target_locales_required':
        return 'En az bir hedef dil seçilmelidir.';
      case 'invalid_locale':
        return 'Geçersiz dil seçimi.';
      case 'invalid_destination_type':
        return 'Geçersiz hedef türü.';
      case 'series_id_required':
        return 'Dizi hedefi seçilmelidir.';
      case 'episode_id_required':
        return 'Bölüm hedefi seçilmelidir.';
      case 'series_not_published':
        return 'Seçilen dizi yayında değil.';
      case 'episode_not_published':
        return 'Seçilen bölüm yayında değil.';
      case 'invalid_date_range':
        return 'Bitiş tarihi, başlangıçtan sonra olmalıdır.';
      default:
        return 'İşlem başarısız: $error';
    }
  }
}
