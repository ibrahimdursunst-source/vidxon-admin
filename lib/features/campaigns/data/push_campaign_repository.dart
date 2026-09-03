import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_push_campaign.dart';

class PushCampaignException implements Exception {
  PushCampaignException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PushCampaignRepository {
  PushCampaignRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AdminPushCampaign>> fetchAll() async {
    final response = await _client.rpc('admin_list_push_campaigns_v1');
    final data = response as Map<String, dynamic>;

    if (data['ok'] != true) {
      throw PushCampaignException('Push kampanyalar yüklenemedi.');
    }

    final campaigns = data['campaigns'];
    if (campaigns is! List) return const [];

    return campaigns
        .whereType<Map<String, dynamic>>()
        .map(AdminPushCampaign.fromMap)
        .toList();
  }

  Future<AdminPushCampaign> upsert({
    String? id,
    String status = 'draft',
    String destinationType = 'none',
    String? destinationSeriesId,
    String? destinationEpisodeId,
    List<String> targetLocales = const [],
    DateTime? scheduledAt,
    required List<AdminPushTranslation> translations,
  }) async {
    final params = <String, dynamic>{
      'p_status': status,
      'p_destination_type': destinationType,
      'p_destination_series_id': destinationSeriesId,
      'p_destination_episode_id': destinationEpisodeId,
      'p_target_locales': targetLocales,
      'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'p_translations': translations.map((t) => t.toMap()).toList(),
    };

    if (id != null) {
      params['p_id'] = id;
    }

    final response = await _client.rpc(
      'admin_upsert_push_campaign_v1',
      params: params,
    );

    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      final error = data['error']?.toString() ?? 'unknown';
      throw PushCampaignException(_humanizeError(error));
    }

    final campaignData = data['campaign'] as Map<String, dynamic>;
    return AdminPushCampaign.fromMap(campaignData);
  }

  Future<void> sendNow(String campaignId) async {
    final response = await _client.rpc(
      'admin_send_push_campaign_v1',
      params: {'p_campaign_id': campaignId},
    );
    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw PushCampaignException(
        _humanizeError(data['error']?.toString() ?? 'unknown'),
      );
    }
    await _invokeFcmDelivery(campaignId);
  }

  Future<void> testSend({
    required String campaignId,
    required String testUserId,
  }) async {
    final response = await _client.rpc(
      'admin_send_push_campaign_v1',
      params: {
        'p_campaign_id': campaignId,
        'p_test_user_id': testUserId,
      },
    );
    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw PushCampaignException(
        _humanizeError(data['error']?.toString() ?? 'unknown'),
      );
    }
    await _invokeFcmDelivery(campaignId);
  }

  Future<void> cancel(String campaignId) async {
    final response = await _client.rpc(
      'admin_cancel_push_campaign_v1',
      params: {'p_campaign_id': campaignId},
    );
    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw PushCampaignException('İptal işlemi başarısız.');
    }
  }

  Future<void> _invokeFcmDelivery(String campaignId) async {
    final response = await _client.functions.invoke(
      'send-push-campaign',
      body: {'campaign_id': campaignId},
    );
    if (response.status != 200) {
      throw PushCampaignException(
        'Bildirim gönderimi başlatılamadı. Lütfen tekrar deneyin.',
      );
    }
  }

  String _humanizeError(String error) {
    if (error.startsWith('missing_title_for_')) {
      final locale = error.replaceFirst('missing_title_for_', '');
      return '$locale dili için başlık zorunludur.';
    }
    if (error.startsWith('missing_body_for_')) {
      final locale = error.replaceFirst('missing_body_for_', '');
      return '$locale dili için mesaj zorunludur.';
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
      case 'campaign_not_found':
        return 'Kampanya bulunamadı.';
      case 'campaign_not_sendable':
        return 'Kampanya gönderilebilir durumda değil.';
      case 'invalid_status':
        return 'Geçersiz durum.';
      default:
        return 'İşlem başarısız: $error';
    }
  }
}
