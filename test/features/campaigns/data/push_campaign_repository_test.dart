import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/time/admin_local_time.dart';
import 'package:vidxon_admin/features/campaigns/data/push_campaign_repository.dart';

void main() {
  test('specific-user invoke body includes exact auth uid', () {
    const userId = '03a499ec-638c-4a48-b2b6-32ad49f00fae';
    final body = PushCampaignRepository.buildDeliveryInvokeBody(
      campaignId: 'camp-1',
      testUserId: userId,
    );
    expect(body['campaign_id'], 'camp-1');
    expect(body['test_user_id'], userId);
  });

  test('all-users invoke body does not include test_user_id', () {
    final body = PushCampaignRepository.buildDeliveryInvokeBody(
      campaignId: 'camp-1',
    );
    expect(body['campaign_id'], 'camp-1');
    expect(body.containsKey('test_user_id'), isFalse);
  });

  test('empty test user id is omitted so broadcast cannot be spoofed', () {
    final body = PushCampaignRepository.buildDeliveryInvokeBody(
      campaignId: 'camp-1',
      testUserId: '',
    );
    expect(body.containsKey('test_user_id'), isFalse);
  });

  test('safe failure copy has no ClientException, URL, or blind retry', () {
    expect(
      PushCampaignRepository.deliveryStartFailedMessage,
      'Bildirim gönderilemedi.',
    );
    expect(
      PushCampaignRepository.sendNowDeliveryFailedMessage,
      'Bildirim gönderilemedi.',
    );
    expect(
      PushCampaignRepository.deliveryStartFailedMessage.contains(
        'ClientException',
      ),
      isFalse,
    );
    expect(
      PushCampaignRepository.deliveryStartFailedMessage.contains('http'),
      isFalse,
    );
    expect(
      PushCampaignRepository.deliveryStartFailedMessage.contains(
        'Lütfen tekrar deneyin',
      ),
      isFalse,
    );
  });

  test('local schedule converts to UTC ISO for the backend once', () {
    final local = DateTime(2026, 9, 11, 19, 30);
    final utc = AdminLocalTime.localToUtc(local);
    final iso = utc.toUtc().toIso8601String();
    expect(iso.endsWith('Z'), isTrue);
    expect(AdminLocalTime.localToUtc(AdminLocalTime.utcToLocalPicker(utc)), utc);
  });
}
