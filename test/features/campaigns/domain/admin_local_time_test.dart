import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/time/admin_local_time.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_push_campaign.dart';
import 'package:vidxon_admin/l10n/admin_l10n.dart';

void main() {
  test('parses UTC ISO strings including Z as UTC', () {
    final parsed = AdminLocalTime.parseUtc('2026-09-11T12:15:54.817546Z');
    expect(parsed.isUtc, isTrue);
    expect(parsed.year, 2026);
    expect(parsed.month, 9);
    expect(parsed.day, 11);
    expect(parsed.hour, 12);
    expect(parsed.minute, 15);
  });

  test('timezone-less and +00 values keep UTC wall clock (screenshot 16:06Z)', () {
    for (final raw in [
      '2026-09-11T16:06:00',
      '2026-09-11T16:06:00Z',
      '2026-09-11T16:06:00+00:00',
      '2026-09-11 16:06:00+00',
      '2026-09-11T16:06:00.000Z',
    ]) {
      final parsed = AdminLocalTime.tryParseUtc(raw);
      expect(parsed, isNotNull, reason: raw);
      expect(parsed!.isUtc, isTrue, reason: raw);
      expect(parsed.hour, 16, reason: raw);
      expect(parsed.minute, 6, reason: raw);
      final shown = AdminLocalTime.format(parsed, const Locale('tr'));
      expect(AdminLocalTime.looksLikeRawUtcIso(shown), isFalse, reason: raw);
      expect(shown.contains('T'), isFalse, reason: raw);
      expect(shown.contains('Z'), isFalse, reason: raw);
    }
  });

  test('non-zero offset converts to UTC once', () {
    final parsed = AdminLocalTime.tryParseUtc('2026-09-11T19:06:00+03:00');
    expect(parsed!.isUtc, isTrue);
    expect(parsed.hour, 16);
    expect(parsed.minute, 6);
  });

  test('local picker converts to UTC once and back without a second shift', () {
    final local = DateTime(2026, 9, 11, 19, 30);
    final utc = AdminLocalTime.localToUtc(local);
    expect(utc.isUtc, isTrue);
    final back = AdminLocalTime.utcToLocalPicker(utc);
    expect(back.year, 2026);
    expect(back.month, 9);
    expect(back.day, 11);
    expect(back.hour, 19);
    expect(back.minute, 30);

    final again = AdminLocalTime.utcToLocalPicker(utc.toUtc());
    expect(again, back);
    expect(utc.toUtc(), utc);
  });

  test('display format is locale-aware and never a raw UTC ISO string', () {
    final utc = DateTime.utc(2026, 9, 11, 12, 15, 54);
    final tr = AdminLocalTime.format(utc, const Locale('tr'));
    final en = AdminLocalTime.format(utc, const Locale('en'));

    expect(tr.contains('T'), isFalse);
    expect(tr.contains('Z'), isFalse);
    expect(tr.contains('+00'), isFalse);
    expect(AdminLocalTime.looksLikeRawUtcIso(tr), isFalse);
    expect(tr, matches(RegExp(r'^\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}$')));

    expect(en.contains('T'), isFalse);
    expect(en.contains('Z'), isFalse);
    expect(en.toUpperCase().contains('SEP'), isTrue);
    expect(en.contains('2026'), isTrue);
  });

  test('campaign map parsing keeps UTC storage and exposes Ready internally as draft', () {
    final campaign = AdminPushCampaign.fromMap({
      'id': 'push-1',
      'status': 'draft',
      'destination_type': 'none',
      'target_locales': ['tr'],
      'scheduled_at': '2026-09-11T16:30:00.000Z',
      'sent_at': null,
      'created_at': '2026-09-11T12:15:54.817546Z',
      'updated_at': '2026-09-11T12:15:54.817546Z',
      'translations': [
        {'locale': 'tr', 'title': 'Promo', 'body': 'Body'},
      ],
      'sent_count': 0,
      'failed_count': 0,
    });

    expect(campaign.status, 'draft');
    expect(campaign.canTestSend, isTrue);
    expect(campaign.canSend, isTrue);
    expect(campaign.canSchedule, isTrue);
    expect(campaign.scheduledAt!.isUtc, isTrue);
    expect(campaign.scheduledAt!.hour, 16);
    expect(campaign.createdAt.isUtc, isTrue);
  });

  test('timezone-less scheduled_at from list RPC is UTC not browser-local', () {
    final campaign = AdminPushCampaign.fromMap({
      'id': 'push-2',
      'status': 'scheduled',
      'destination_type': 'coin_purchase',
      'target_locales': ['tr'],
      'scheduled_at': '2026-09-11T16:06:00',
      'sent_at': null,
      'created_at': '2026-09-11 16:05:06.811762+00',
      'updated_at': '2026-09-11 16:05:06.811762+00',
      'translations': [
        {'locale': 'tr', 'title': 'jeton satın alma zamanı', 'body': 'Body'},
      ],
      'sent_count': 0,
      'failed_count': 0,
    });
    expect(campaign.scheduledAt!.isUtc, isTrue);
    expect(campaign.scheduledAt!.hour, 16);
    expect(campaign.scheduledAt!.minute, 6);
    expect(campaign.createdAt.isUtc, isTrue);
    expect(campaign.createdAt.hour, 16);
  });

  test('human push status labels hide draft and keep other states', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(adminPushCampaignStatusLabel(tr, 'draft'), 'Hazır');
    expect(adminPushCampaignStatusLabel(en, 'draft'), 'Ready');
    expect(adminPushCampaignStatusLabel(tr, 'scheduled'), 'Planlanmış');
    expect(adminPushCampaignStatusLabel(en, 'scheduled'), 'Scheduled');
    expect(adminPushCampaignStatusLabel(tr, 'sending'), 'Gönderiliyor');
    expect(adminPushCampaignStatusLabel(en, 'sending'), 'Sending');
    expect(adminPushCampaignStatusLabel(tr, 'sent'), 'Gönderildi');
    expect(adminPushCampaignStatusLabel(en, 'sent'), 'Sent');
    expect(adminPushCampaignStatusLabel(tr, 'failed'), 'Başarısız');
    expect(adminPushCampaignStatusLabel(en, 'failed'), 'Failed');
    expect(adminPushCampaignStatusLabel(tr, 'cancelled'), 'İptal');
    expect(adminPushCampaignStatusLabel(en, 'cancelled'), 'Cancelled');
  });
}
