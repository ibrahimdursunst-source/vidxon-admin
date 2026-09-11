import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/domain/campaign_test_targeting.dart';

void main() {
  test('normal campaigns do not require a test user', () {
    expect(
      CampaignTestTargeting.validate(testOnly: false, testUserId: null),
      isNull,
    );
    expect(
      CampaignTestTargeting.persist(testOnly: false, testUserId: ' leftover '),
      (testOnly: false, testUserId: null),
    );
  });

  test('test-only without a user is rejected and never becomes broadcast', () {
    expect(
      CampaignTestTargeting.validate(testOnly: true, testUserId: null),
      'test_user_required',
    );
    expect(
      CampaignTestTargeting.validate(testOnly: true, testUserId: '   '),
      'test_user_required',
    );
    expect(
      CampaignTestTargeting.persist(testOnly: true, testUserId: '  '),
      (testOnly: true, testUserId: null),
    );
  });

  test('test-only persists the selected user id', () {
    const userId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    expect(
      CampaignTestTargeting.validate(testOnly: true, testUserId: ' $userId '),
      isNull,
    );
    expect(
      CampaignTestTargeting.persist(testOnly: true, testUserId: ' $userId '),
      (testOnly: true, testUserId: userId),
    );
  });
}
