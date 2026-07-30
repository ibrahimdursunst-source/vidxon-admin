import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_input.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_reason.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  AdminCoinCreditInput input({
    int amount = 100,
    String description = 'Destek talebi jeton yüklemesi',
    String? caseReference,
    AdminCoinCreditReason reason = AdminCoinCreditReason.customerSupport,
  }) {
    return AdminCoinCreditInput(
      userId: userId,
      amount: amount,
      reason: reason,
      description: description,
      caseReference: caseReference,
    );
  }

  group('validateCoinAmountText', () {
    test('accepts 1', () {
      expect(validateCoinAmountText('1'), isNull);
    });

    test('accepts 1,000,000', () {
      expect(validateCoinAmountText('1000000'), isNull);
    });

    test('rejects zero', () {
      expect(validateCoinAmountText('0'), isNotNull);
    });

    test('rejects negative sign input', () {
      expect(validateCoinAmountText('-5'), isNotNull);
    });

    test('rejects above limit', () {
      expect(validateCoinAmountText('1000001'), isNotNull);
    });

    test('rejects decimal input', () {
      expect(validateCoinAmountText('10.5'), isNotNull);
    });

    test('rejects letters', () {
      expect(validateCoinAmountText('abc'), isNotNull);
    });
  });

  group('validateCoinCreditDescription', () {
    test('rejects too short description', () {
      expect(validateCoinCreditDescription('abc'), isNotNull);
    });

    test('accepts valid description length', () {
      expect(validateCoinCreditDescription('Geçerli açıklama metni'), isNull);
    });
  });

  group('validateCaseReference', () {
    test('accepts empty case reference', () {
      expect(validateCaseReference(''), isNull);
    });

    test('rejects too long case reference', () {
      expect(validateCaseReference('x' * 101), isNotNull);
    });
  });

  group('buildCreditUserCoinsRpcParams', () {
    test('uses exact RPC payload keys', () {
      final params = buildCreditUserCoinsRpcParams(
        input: input(caseReference: 'CASE-123'),
        idempotencyKey: '22222222-2222-2222-2222-222222222222',
      );

      expect(
        params.keys,
        containsAll([
          'p_user_id',
          'p_amount',
          'p_reason_code',
          'p_description',
          'p_idempotency_key',
          'p_case_reference',
        ]),
      );
      expect(params['p_user_id'], userId);
      expect(params['p_amount'], 100);
      expect(params['p_reason_code'], 'customer_support');
      expect(
        params['p_idempotency_key'],
        '22222222-2222-2222-2222-222222222222',
      );
      expect(params['p_case_reference'], 'CASE-123');
    });
  });

  group('AdminCoinCreditInput.projectedBalance', () {
    test('adds amount safely', () {
      expect(input(amount: 500).projectedBalance(120), 620);
    });
  });
}
