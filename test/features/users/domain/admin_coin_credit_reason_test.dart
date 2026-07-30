import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_reason.dart';

void main() {
  group('AdminCoinCreditReason', () {
    test('maps known reason codes', () {
      expect(
        AdminCoinCreditReason.tryParse('event_reward'),
        AdminCoinCreditReason.eventReward,
      );
      expect(AdminCoinCreditReason.eventReward.labelTurkish, 'Etkinlik Ödülü');
    });

    test('returns null for unknown reason code', () {
      expect(AdminCoinCreditReason.tryParse('unknown_reason'), isNull);
    });

    test('labelFor unknown code returns raw value', () {
      expect(AdminCoinCreditReason.labelFor('custom_code'), 'custom_code');
    });

    test('parseRequired throws for unknown code', () {
      expect(
        () => AdminCoinCreditReason.parseRequired('broken'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
