import 'package:flutter/material.dart';

import '../features/admin_locale/domain/admin_ui_locales.dart';
import '../features/audit/domain/admin_audit_entry.dart';
import '../features/campaigns/domain/campaign_destination.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension AdminL10nContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(const Locale(AdminUiLocales.defaultCode));
}

String adminPublishedLabel(AppLocalizations l10n, bool isPublished) {
  return isPublished ? l10n.published : l10n.notPublished;
}

String adminArchivedLabel(AppLocalizations l10n, bool isArchived) {
  return isArchived ? l10n.archived : l10n.active;
}

String adminDestinationTypeLabel(AppLocalizations l10n, String value) {
  return switch (value) {
    CampaignDestinationType.none => l10n.destinationNone,
    CampaignDestinationType.series => l10n.destinationSeries,
    CampaignDestinationType.episode => l10n.destinationEpisode,
    CampaignDestinationType.coinPurchase => l10n.destinationCoinPurchase,
    CampaignDestinationType.membership => l10n.destinationMembership,
    _ => value,
  };
}

String adminCampaignStatusLabel(AppLocalizations l10n, String statusLabel) {
  return switch (statusLabel) {
    'Aktif' => l10n.active,
    'Pasif' => l10n.inactive,
    'Planlanmış' => l10n.scheduled,
    'Süresi Dolmuş' => l10n.expired,
    'Taslak' => l10n.draft,
    'Gönderiliyor' => l10n.pushSending,
    'Gönderildi' => l10n.sent,
    'İptal Edildi' => l10n.pushCancelled,
    'Başarısız' => l10n.failed,
    _ => statusLabel,
  };
}

String adminSeriesStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'ongoing' || 'Devam Ediyor' => l10n.statusOngoing,
    'completed' || 'Tamamlandı' => l10n.statusCompleted,
    'coming_soon' || 'Yakında' => l10n.statusComingSoon,
    _ => status,
  };
}

String adminPublishDisplayLabel(AppLocalizations l10n, String publishLabel) {
  return switch (publishLabel) {
    'Yayında' => l10n.published,
    'Yayında Değil' => l10n.notPublished,
    'Taslak' => l10n.draft,
    _ => publishLabel,
  };
}

String adminArchiveDisplayLabel(AppLocalizations l10n, String archiveLabel) {
  return switch (archiveLabel) {
    'Arşivlenmiş' => l10n.archived,
    'Aktif' => l10n.active,
    'Arşiv' => l10n.archive,
    _ => archiveLabel,
  };
}

String adminVideoStatusLabel(AppLocalizations l10n, String statusLabel) {
  return switch (statusLabel) {
    'Video Yok' => l10n.videoNone,
    'İşleniyor' => l10n.videoProcessing,
    'Video Hazır' => l10n.videoReady,
    'Video Hatası' => l10n.videoError,
    'Değişim: İşleniyor' => l10n.pendingProcessing,
    'Değişim: Hazır' => l10n.pendingReady,
    'Değişim: Hata' => l10n.pendingError,
    'Değişim: Bekliyor' => l10n.pendingWaiting,
    'Hazır' => l10n.ready,
    'Başarısız' => l10n.failed,
    _ => statusLabel,
  };
}

String adminPartnerStatusLabel(AppLocalizations l10n, String valueOrLabel) {
  return switch (valueOrLabel) {
    'active' || 'Aktif' => l10n.active,
    'suspended' || 'Askıda' => l10n.statusSuspended,
    'ended' || 'Sonlandırılmış' => l10n.statusEnded,
    _ => valueOrLabel,
  };
}

String adminIntegrityStatusLabel(AppLocalizations l10n, String valueOrLabel) {
  return switch (valueOrLabel) {
    'healthy' || 'Sağlıklı' => l10n.integrityHealthy,
    'warning' || 'Uyarı' => l10n.integrityWarningLabel,
    'unavailable' || 'Kullanılamıyor' => l10n.integrityUnavailableLabel,
    _ => valueOrLabel,
  };
}

String adminAnalyticsPresetLabel(AppLocalizations l10n, String valueOrLabel) {
  return switch (valueOrLabel) {
    'total' || 'Toplam' => l10n.presetTotal,
    'today' || 'Bugün' => l10n.presetToday,
    'yesterday' || 'Dün' => l10n.presetYesterday,
    'last_7_days' || 'Son 7 Gün' => l10n.presetLast7Days,
    'this_week' || 'Bu Hafta' => l10n.presetThisWeek,
    'previous_week' || 'Geçen Hafta' => l10n.presetPreviousWeek,
    'last_30_days' || 'Son 30 Gün' => l10n.presetLast30Days,
    'this_month' || 'Bu Ay' => l10n.presetThisMonth,
    'previous_month' || 'Geçen Ay' => l10n.presetPreviousMonth,
    'custom' || 'Özel Aralık' => l10n.presetCustom,
    _ => valueOrLabel,
  };
}

String adminCoinCreditReasonLabel(AppLocalizations l10n, String storageValue) {
  return switch (storageValue) {
    'event_reward' || 'Etkinlik Ödülü' => l10n.reasonEventReward,
    'customer_support' || 'Müşteri Desteği' => l10n.reasonCustomerSupport,
    'technical_issue' || 'Teknik Sorun' => l10n.reasonTechnicalIssue,
    'promotional' || 'Promosyon' => l10n.reasonPromotional,
    'payment_resolution' || 'Ödeme Çözümü' => l10n.reasonPaymentResolution,
    'test_credit' || 'Test Jetonu' => l10n.reasonTestCredit,
    'other' || 'Diğer' => l10n.reasonOther,
    _ => storageValue,
  };
}

String adminCoinDebitReasonLabel(AppLocalizations l10n, String storageValue) {
  return switch (storageValue) {
    'incorrect_credit_reversal' ||
    'Yanlış Jeton Yüklemesini Geri Alma' => l10n.reasonIncorrectCreditReversal,
    'reward_correction' ||
    'Hatalı Ödül Düzeltmesi' => l10n.reasonRewardCorrection,
    'customer_support' || 'Müşteri Desteği' => l10n.reasonCustomerSupport,
    'abuse_correction' ||
    'Kötüye Kullanım Düzeltmesi' => l10n.reasonAbuseCorrection,
    'payment_resolution' ||
    'Ödeme Sorunu Çözümü' => l10n.reasonPaymentIssueResolution,
    'test_debit' || 'Test Jetonu Eksiltme' => l10n.reasonTestDebit,
    'other' || 'Diğer' => l10n.reasonOther,
    _ => storageValue,
  };
}

String adminWalletTxnLabel(AppLocalizations l10n, String transactionType) {
  return switch (transactionType.trim()) {
    'episode_unlock' || 'Bölüm Açma' => l10n.txnEpisodeUnlock,
    'rewarded_ad' || 'Reklam Ödülü' => l10n.txnRewardedAd,
    'admin_coin_credit' || 'Admin Jeton Yükleme' => l10n.txnAdminCoinCredit,
    'admin_coin_debit' || 'Admin Jeton Eksiltme' => l10n.txnAdminCoinDebit,
    'admin_test_credit' || 'Eski Test Kredisi' => l10n.txnAdminTestCredit,
    _ => transactionType.trim(),
  };
}

String adminWalletReasonLabel(AppLocalizations l10n, String? reasonCode) {
  if (reasonCode == null || reasonCode.trim().isEmpty) {
    return '—';
  }

  final debit = adminCoinDebitReasonLabel(l10n, reasonCode.trim());
  if (debit != reasonCode.trim()) {
    return debit;
  }

  return adminCoinCreditReasonLabel(l10n, reasonCode.trim());
}

String adminActorLabel(AppLocalizations l10n, String? actorAdminUserId) {
  if (actorAdminUserId == null || actorAdminUserId.trim().isEmpty) {
    return l10n.systemActor;
  }

  return actorAdminUserId.trim();
}

String adminUserStatusLabel(AppLocalizations l10n, String statusLabel) {
  return switch (statusLabel) {
    'Onaylanmamış' => l10n.unconfirmed,
    'Askıda' => l10n.statusSuspended,
    'Yasaklı' => l10n.banned,
    'Devre Dışı' => l10n.disabled,
    'Aktif' => l10n.active,
    'Pasif' => l10n.inactive,
    'Bilinmiyor' => l10n.unknownStatus,
    _ => statusLabel,
  };
}

String adminEmailLabel(AppLocalizations l10n, String? email) {
  final trimmed = email?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return l10n.noEmail;
  }

  return trimmed;
}

String adminResolvedEmailLabel(AppLocalizations l10n, String label) {
  return label == 'E-posta yok' ? l10n.noEmail : label;
}

String adminAgeRatingLabel(AppLocalizations l10n, int? age) {
  return switch (age) {
    13 => '13+',
    16 => '16+',
    18 => '18+',
    _ => l10n.ageNotSpecified,
  };
}

String adminDescriptorLabel(AppLocalizations l10n, String id) {
  return switch (id) {
    'violence' => l10n.descriptorViolence,
    'strong_violence' => l10n.descriptorStrongViolence,
    'profanity' => l10n.descriptorProfanity,
    'mature_themes' => l10n.descriptorMatureThemes,
    'sexual_content' => l10n.descriptorSexualContent,
    'substance_references' => l10n.descriptorSubstance,
    'fear_horror' => l10n.descriptorFearHorror,
    _ => id,
  };
}

String adminAuditActionLabel(AppLocalizations l10n, String? actionType) {
  if (actionType == null || actionType.trim().isEmpty) {
    return '—';
  }

  return switch (actionType.trim()) {
    AdminAuditActionType.walletCredit => l10n.filterWalletCredit,
    AdminAuditActionType.walletDebit => l10n.filterWalletDebitExact,
    AdminAuditActionType.roleSet => l10n.filterAdminRoleChange,
    AdminAuditActionType.accessRevoke => l10n.filterAdminAccessRevoke,
    AdminAuditActionType.seriesCreated => l10n.auditSeriesCreated,
    AdminAuditActionType.seriesUpdated => l10n.filterSeriesUpdated,
    AdminAuditActionType.seriesPosterReplaced => l10n.filterPosterReplaced,
    AdminAuditActionType.seriesPublished => l10n.filterSeriesPublished,
    AdminAuditActionType.seriesUnpublished => l10n.auditSeriesUnpublished,
    AdminAuditActionType.seriesArchived => l10n.filterSeriesArchived,
    AdminAuditActionType.seriesRestored => l10n.auditSeriesRestored,
    AdminAuditActionType.episodesReordered => l10n.auditEpisodesReordered,
    AdminAuditActionType.episodeCreated => l10n.auditEpisodeCreated,
    AdminAuditActionType.episodeUpdated => l10n.filterEpisodeUpdated,
    AdminAuditActionType.episodePublished => l10n.auditEpisodePublished,
    AdminAuditActionType.episodeUnpublished => l10n.auditEpisodeUnpublished,
    AdminAuditActionType.episodeArchived => l10n.auditEpisodeArchived,
    AdminAuditActionType.episodeRestored => l10n.auditEpisodeRestored,
    AdminAuditActionType.episodeStreamAttached => l10n.auditVideoAttached,
    AdminAuditActionType.episodeStreamReplacementRequested =>
      l10n.auditVideoReplacementRequested,
    AdminAuditActionType.episodeStreamPromoted => l10n.auditVideoPromoted,
    _ => actionType.trim(),
  };
}

String adminWalletRestrictionLabel(AppLocalizations l10n, String message) {
  return switch (message) {
    'Admin hesaplarında manuel jeton işlemleri yapılamaz.' =>
      l10n.adminAccountsNoManualCoins,
    'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.' =>
      l10n.coinsSuperAdminOnly,
    _ => message,
  };
}

String adminPublishBlockReasonLabel(AppLocalizations l10n, String? reason) {
  if (reason == null || reason.isEmpty) {
    return '';
  }

  return switch (reason) {
    'Arşivlenmiş bir dizinin bölümü yayınlanamaz.' =>
      l10n.publishBlockedSeriesArchived,
    'Arşivlenmiş bölüm yayınlanamaz.' => l10n.publishBlockedEpisodeArchived,
    'Yayınlamak için aktif video gerekir.' => l10n.publishBlockedNeedsVideo,
    'Video işleniyor.' => l10n.publishBlockedVideoProcessing,
    'Video hatası giderilmelidir.' => l10n.publishBlockedVideoError,
    'Video henüz hazır değil.' => l10n.publishBlockedVideoNotReady,
    'Ücretli bölümde coin fiyatı 0\'dan büyük olmalıdır.' =>
      l10n.publishBlockedPaidCoinPrice,
    _ => reason,
  };
}
