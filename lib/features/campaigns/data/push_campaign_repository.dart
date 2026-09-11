import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_push_campaign.dart';

class PushCampaignException implements Exception {
  PushCampaignException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PushUserReadiness {
  const PushUserReadiness({
    required this.userId,
    required this.eligibleDeviceCount,
    required this.androidCount,
    required this.iosCount,
    this.latestLastSeenAt,
  });

  final String userId;
  final int eligibleDeviceCount;
  final int androidCount;
  final int iosCount;
  final DateTime? latestLastSeenAt;

  factory PushUserReadiness.fromMap(Map<String, dynamic> map) {
    return PushUserReadiness(
      userId: map['user_id']?.toString() ?? '',
      eligibleDeviceCount: _asInt(map['eligible_device_count']),
      androidCount: _asInt(map['android_count']),
      iosCount: _asInt(map['ios_count']),
      latestLastSeenAt: map['latest_last_seen_at'] != null
          ? DateTime.tryParse(map['latest_last_seen_at'].toString())
          : null,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PushCampaignRepository {
  PushCampaignRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<List<AdminPushCampaign>> fetchAll() async {
    final response = await _resolvedClient.rpc('admin_list_push_campaigns_v1');
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

    final response = await _resolvedClient.rpc(
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
    final response = await _resolvedClient.rpc(
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

  Future<PushUserReadiness> fetchUserReadiness({
    required String userId,
    String? locale,
  }) async {
    final params = <String, dynamic>{'p_user_id': userId};
    if (locale != null && locale.isNotEmpty) {
      params['p_locale'] = locale;
    }
    final response = await _resolvedClient.rpc(
      'admin_get_push_user_readiness_v1',
      params: params,
    );
    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw PushCampaignException(
        _humanizeError(data['error']?.toString() ?? 'unknown'),
      );
    }
    assertSafeReadinessPayload(data);
    return PushUserReadiness.fromMap(data);
  }

  @visibleForTesting
  static void assertSafeReadinessPayload(Map<String, dynamic> data) {
    final encoded = jsonEncode(data).toLowerCase();
    const forbidden = [
      'fcm_token',
      'fcmtoken',
      'access_token',
      'service_role',
      'private_key',
      'authorization',
    ];
    for (final needle in forbidden) {
      if (encoded.contains(needle)) {
        throw PushCampaignException('Güvenli olmayan cihaz yanıtı.');
      }
    }
  }

  Future<void> testSend({
    required String campaignId,
    required String testUserId,
  }) async {
    final response = await _resolvedClient.rpc(
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
    await _invokeFcmDelivery(campaignId, testUserId: testUserId);
  }

  Future<void> cancel(String campaignId) async {
    final response = await _resolvedClient.rpc(
      'admin_cancel_push_campaign_v1',
      params: {'p_campaign_id': campaignId},
    );
    final data = response as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw PushCampaignException('İptal işlemi başarısız.');
    }
  }

  Future<void> _invokeFcmDelivery(
    String campaignId, {
    String? testUserId,
  }) async {
    final body = <String, dynamic>{'campaign_id': campaignId};
    if (testUserId != null && testUserId.isNotEmpty) {
      body['test_user_id'] = testUserId;
    }
    final response = await _resolvedClient.functions.invoke(
      'send-push-campaign',
      body: body,
    );
    if (response.status != 200) {
      throw PushCampaignException(
        testUserId != null && testUserId.isNotEmpty
            ? deliveryStartFailedMessage
            : sendNowDeliveryFailedMessage,
      );
    }
  }

  @visibleForTesting
  static const deliveryStartFailedMessage =
      'Bildirim gönderimi başlatılamadı. Lütfen tekrar denemeden önce gönderim durumunu kontrol edin.';

  @visibleForTesting
  static const sendNowDeliveryFailedMessage =
      'Bildirim gönderimi tamamlanamadı. Tekrar göndermeden önce kampanyanın gönderim durumunu kontrol edin.';

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
