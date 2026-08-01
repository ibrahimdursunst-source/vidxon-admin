import '../../users/domain/user_parse_helpers.dart';

abstract final class AdminAuditActionType {
  static const walletCredit = 'wallet.admin_coin_credit';
  static const walletDebit = 'wallet.admin_coin_debit';
  static const roleSet = 'admin.role_set';
  static const accessRevoke = 'admin.access_revoke';

  static const seriesUpdated = 'content.series_updated';
  static const seriesPosterReplaced = 'content.series_poster_replaced';
  static const seriesPublished = 'content.series_published';
  static const seriesUnpublished = 'content.series_unpublished';
  static const seriesArchived = 'content.series_archived';
  static const seriesRestored = 'content.series_restored';
  static const episodesReordered = 'content.episodes_reordered';
  static const episodeUpdated = 'content.episode_updated';
  static const episodePublished = 'content.episode_published';
  static const episodeUnpublished = 'content.episode_unpublished';
  static const episodeArchived = 'content.episode_archived';
  static const episodeRestored = 'content.episode_restored';
  static const episodeStreamAttached = 'content.episode_stream_attached';
  static const episodeStreamReplacementRequested =
      'content.episode_stream_replacement_requested';
  static const episodeStreamPromoted = 'content.episode_stream_promoted';
  static const seriesCreated = 'content.series_created';
  static const episodeCreated = 'content.episode_created';

  static const walletActions = {walletCredit, walletDebit};

  static const contentActions = {
    seriesCreated,
    seriesUpdated,
    seriesPosterReplaced,
    seriesPublished,
    seriesUnpublished,
    seriesArchived,
    seriesRestored,
    episodesReordered,
    episodeUpdated,
    episodePublished,
    episodeUnpublished,
    episodeArchived,
    episodeRestored,
    episodeStreamAttached,
    episodeStreamReplacementRequested,
    episodeStreamPromoted,
    episodeCreated,
  };

  static String labelFor(String? actionType) {
    if (actionType == null || actionType.trim().isEmpty) {
      return '—';
    }

    return switch (actionType.trim()) {
      walletCredit => 'Jeton Yükleme',
      walletDebit => 'Jeton Eksiltme',
      roleSet => 'Admin Rolü Değişikliği',
      accessRevoke => 'Admin Erişimi Kaldırma',
      seriesCreated => 'Dizi Oluşturuldu',
      seriesUpdated => 'Dizi Güncellendi',
      seriesPosterReplaced => 'Poster Değiştirildi',
      seriesPublished => 'Dizi Yayınlandı',
      seriesUnpublished => 'Dizi Yayından Kaldırıldı',
      seriesArchived => 'Dizi Arşivlendi',
      seriesRestored => 'Dizi Geri Yüklendi',
      episodesReordered => 'Bölüm Sıralaması Değiştirildi',
      episodeCreated => 'Bölüm Oluşturuldu',
      episodeUpdated => 'Bölüm Güncellendi',
      episodePublished => 'Bölüm Yayınlandı',
      episodeUnpublished => 'Bölüm Yayından Kaldırıldı',
      episodeArchived => 'Bölüm Arşivlendi',
      episodeRestored => 'Bölüm Geri Yüklendi',
      episodeStreamAttached => 'Video Bağlandı',
      episodeStreamReplacementRequested => 'Video Değişimi İstendi',
      episodeStreamPromoted => 'Video Aktif Edildi',
      _ => actionType.trim(),
    };
  }

  static String summaryFor(AdminAuditEntry entry) {
    final metadata = entry.metadata;
    if (metadata == null || metadata.isEmpty) {
      return labelFor(entry.actionType);
    }

    final title = metadataTitle(metadata);
    if (title != null) {
      return '${labelFor(entry.actionType)} · $title';
    }

    return labelFor(entry.actionType);
  }

  static String? metadataTitle(Map<String, dynamic> metadata) {
    for (final key in ['new_title', 'title', 'slug']) {
      final value = metadata[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.auditId,
    required this.actionType,
    required this.createdAt,
    this.actorAdminUserId,
    this.actorEmail,
    this.actorRole,
    this.targetUserId,
    this.targetEmail,
    this.amount,
    this.balanceBefore,
    this.balanceAfter,
    this.reasonCode,
    this.description,
    this.caseReference,
    this.metadata,
  });

  final String auditId;
  final String actionType;
  final String? actorAdminUserId;
  final String? actorEmail;
  final String? actorRole;
  final String? targetUserId;
  final String? targetEmail;
  final int? amount;
  final int? balanceBefore;
  final int? balanceAfter;
  final String? reasonCode;
  final String? description;
  final String? caseReference;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  String get actionTypeLabel => AdminAuditActionType.labelFor(actionType);

  String get summaryLabel => AdminAuditActionType.summaryFor(this);

  bool get isContentAction =>
      AdminAuditActionType.contentActions.contains(actionType);

  String get actorLabel {
    final email = actorEmail?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    if (actorAdminUserId != null && actorAdminUserId!.isNotEmpty) {
      return shortenUserId(actorAdminUserId!);
    }

    return '—';
  }

  String get targetLabel {
    final email = targetEmail?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    if (targetUserId != null && targetUserId!.isNotEmpty) {
      return shortenUserId(targetUserId!);
    }

    if (isContentAction) {
      return _contentTargetFromMetadata(metadata) ?? '—';
    }

    return '—';
  }

  factory AdminAuditEntry.fromMap(Map<String, dynamic> map) {
    return AdminAuditEntry(
      auditId: UserParseHelpers.requireUserId(
        map['audit_id'],
        fieldName: 'audit_id',
      ),
      actionType: UserParseHelpers.requireString(
        map['action_type'],
        fieldName: 'action_type',
      ),
      actorAdminUserId: UserParseHelpers.parseOptionalUserId(
        map['actor_admin_user_id'],
        fieldName: 'actor_admin_user_id',
      ),
      actorEmail: UserParseHelpers.parseNullableEmail(map['actor_email']),
      actorRole: UserParseHelpers.nullableString(map['actor_role']),
      targetUserId: UserParseHelpers.parseOptionalUserId(
        map['target_user_id'],
        fieldName: 'target_user_id',
      ),
      targetEmail: UserParseHelpers.parseNullableEmail(map['target_email']),
      amount: UserParseHelpers.parseNullableInt(
        map['amount'],
        fieldName: 'amount',
      ),
      balanceBefore: UserParseHelpers.parseNullableInt(
        map['balance_before'],
        fieldName: 'balance_before',
      ),
      balanceAfter: UserParseHelpers.parseNullableInt(
        map['balance_after'],
        fieldName: 'balance_after',
      ),
      reasonCode: UserParseHelpers.nullableString(map['reason_code']),
      description: UserParseHelpers.nullableString(map['description']),
      caseReference: UserParseHelpers.nullableString(map['case_reference']),
      metadata: _parseMetadata(map['metadata']),
      createdAt: UserParseHelpers.requireUtcDateTime(
        map['created_at'],
        fieldName: 'created_at',
      ),
    );
  }
}

String? _contentTargetFromMetadata(Map<String, dynamic>? metadata) {
  if (metadata == null || metadata.isEmpty) {
    return null;
  }

  return AdminAuditActionType.metadataTitle(metadata);
}

Map<String, dynamic>? _parseMetadata(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw FormatException('metadata is invalid.');
}

Map<String, dynamic> buildListAuditLogRpcParams({
  String? actionType,
  String? targetUserId,
  required int limit,
  required int offset,
}) {
  final validationError = validateAuditTargetUserIdFilter(targetUserId);
  if (validationError != null) {
    throw FormatException(validationError);
  }

  final trimmedTarget = targetUserId?.trim();
  final parsedTarget = trimmedTarget == null || trimmedTarget.isEmpty
      ? null
      : UserParseHelpers.requireUserId(
          trimmedTarget,
          fieldName: 'p_target_user_id',
        );

  final trimmedAction = actionType?.trim();

  return {
    'p_action_type': trimmedAction == null || trimmedAction.isEmpty
        ? null
        : trimmedAction,
    'p_target_user_id': parsedTarget,
    'p_limit': limit,
    'p_offset': offset,
  };
}

String? validateAuditTargetUserIdFilter(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    UserParseHelpers.requireUserId(trimmed, fieldName: 'p_target_user_id');
    return null;
  } on FormatException {
    return 'Geçersiz hedef kullanıcı ID.';
  }
}
