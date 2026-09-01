import 'partner_status.dart';

Map<String, dynamic> buildPartnerCreateRpcParams({
  required String displayName,
  String? legalName,
}) {
  final trimmedLegal = legalName?.trim();
  return {
    'p_display_name': displayName.trim(),
    'p_legal_name': trimmedLegal == null || trimmedLegal.isEmpty
        ? null
        : trimmedLegal,
  };
}

Map<String, dynamic> buildPartnerUpdateRpcParams({
  required String partnerId,
  required String displayName,
  required PartnerStatus status,
  String? legalName,
}) {
  final trimmedLegal = legalName?.trim();
  return {
    'p_partner_id': partnerId.trim(),
    'p_display_name': displayName.trim(),
    'p_legal_name': trimmedLegal == null || trimmedLegal.isEmpty
        ? null
        : trimmedLegal,
    'p_status': status.value,
  };
}

Map<String, dynamic> buildPartnerLookupUserRpcParams({required String email}) {
  return {'p_email': email.trim().toLowerCase()};
}

Map<String, dynamic> buildPartnerAddMemberRpcParams({
  required String partnerId,
  required String userId,
}) {
  return {'p_partner_id': partnerId.trim(), 'p_user_id': userId.trim()};
}

Map<String, dynamic> buildPartnerSetMemberStatusRpcParams({
  required String partnerId,
  required String userId,
  required PartnerMemberStatus status,
}) {
  return {
    'p_partner_id': partnerId.trim(),
    'p_user_id': userId.trim(),
    'p_status': status.value,
  };
}

Map<String, dynamic> buildPartnerDetailRpcParams({required String partnerId}) {
  return {'p_partner_id': partnerId.trim()};
}

Map<String, dynamic> buildPartnerAssignmentHistoryRpcParams({
  required String seriesId,
}) {
  return {'p_series_id': seriesId.trim()};
}

Map<String, dynamic> buildSetSeriesPartnerRpcParams({
  required String seriesId,
  required String? partnerId,
  required int expectedContentVersion,
}) {
  return {
    'p_series_id': seriesId.trim(),
    'p_partner_id': partnerId?.trim(),
    'p_expected_content_version': expectedContentVersion,
  };
}

Map<String, dynamic> buildPartnerSeriesAnalyticsRpcParams({
  required String partnerId,
  required String seriesId,
  required PartnerAnalyticsPreset preset,
  DateTime? customStart,
  DateTime? customEnd,
  DateTime? asOf,
  int episodeLimit = 500,
  int episodeOffset = 0,
}) {
  return {
    'p_partner_id': partnerId.trim(),
    'p_series_id': seriesId.trim(),
    'p_preset': preset.value,
    'p_custom_start': customStart?.toUtc().toIso8601String(),
    'p_custom_end': customEnd?.toUtc().toIso8601String(),
    'p_as_of': asOf?.toUtc().toIso8601String(),
    'p_episode_limit': episodeLimit.clamp(1, 500),
    'p_episode_offset': episodeOffset < 0 ? 0 : episodeOffset,
  };
}
