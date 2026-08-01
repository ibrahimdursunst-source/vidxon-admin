import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_debit_input.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_debit_reason.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_debit_result.dart';
import 'package:vidxon_admin/features/users/domain/coin_debit_idempotency.dart';
import 'package:vidxon_admin/features/users/domain/coin_credit_idempotency.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  group('AdminCoinDebitInput', () {
    AdminCoinDebitInput input({
      int amount = 50,
      String description = 'Valid debit description',
    }) {
      return AdminCoinDebitInput(
        userId: userId,
        amount: amount,
        reason: AdminCoinDebitReason.customerSupport,
        description: description,
      );
    }

    test('validates positive amount', () {
      input().validate();
    });

    test('rejects zero amount', () {
      expect(
        () => input(amount: 0).validate(),
        throwsA(isA<AdminCoinDebitValidationException>()),
      );
    });

    test('rejects over-limit amount', () {
      expect(
        () => input(amount: 1000001).validate(),
        throwsA(isA<AdminCoinDebitValidationException>()),
      );
    });

    test('rejects short description', () {
      expect(
        () => input(description: 'abc').validate(),
        throwsA(isA<AdminCoinDebitValidationException>()),
      );
    });

    test('projected balance subtracts amount', () {
      expect(input(amount: 30).projectedBalance(100), 70);
    });

    test('projected balance rejects insufficient funds', () {
      expect(
        () => input(amount: 200).projectedBalance(100),
        throwsA(isA<AdminCoinDebitValidationException>()),
      );
    });
  });

  group('AdminCoinDebitReason', () {
    test('maps allowlist labels', () {
      expect(
        AdminCoinDebitReason.testDebit.labelTurkish,
        'Test Jetonu Eksiltme',
      );
    });
  });

  group('AdminCoinDebitResult.fromMap', () {
    Map<String, dynamic> resultMap({int amount = -50}) {
      return {
        'ledger_id': 10,
        'user_id': userId,
        'amount': amount,
        'balance_before': 100,
        'balance_after': 50,
        'transaction_type': 'admin_coin_debit',
        'reason_code': 'customer_support',
        'was_replayed': false,
        'created_at': '2026-07-29T12:00:00.000Z',
      };
    }

    test('parses negative amount', () {
      final result = AdminCoinDebitResult.fromMap(resultMap());
      expect(result.amount, -50);
    });

    test('rejects positive amount', () {
      expect(
        () => AdminCoinDebitResult.fromMap(resultMap(amount: 50)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects negative balanceAfter', () {
      final map = resultMap();
      map['balance_after'] = -1;
      expect(
        () => AdminCoinDebitResult.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects wrong transaction type', () {
      final map = resultMap();
      map['transaction_type'] = 'admin_coin_credit';
      expect(
        () => AdminCoinDebitResult.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('CoinDebitIdempotencyManager', () {
    test('reuses key for same payload', () {
      final manager = CoinDebitIdempotencyManager(generateUuid: () => 'a');
      expect(manager.keyForPayload('payload'), 'a');
      expect(manager.keyForPayload('payload'), 'a');
    });

    test('creates new key when payload changes', () {
      var counter = 0;
      final manager = CoinDebitIdempotencyManager(
        generateUuid: () => 'key-${++counter}',
      );

      expect(manager.keyForPayload('one'), 'key-1');
      expect(manager.keyForPayload('two'), 'key-2');
    });

    test('clears after success', () {
      var counter = 0;
      final manager = CoinDebitIdempotencyManager(
        generateUuid: () => 'key-${++counter}',
      );

      expect(manager.keyForPayload('payload'), 'key-1');
      manager.clear();
      expect(manager.keyForPayload('payload'), 'key-2');
    });

    test('does not share state with credit manager', () {
      final debit = CoinDebitIdempotencyManager(
        generateUuid: () => 'debit-key',
      );
      final credit = CoinCreditIdempotencyManager(
        generateUuid: () => 'credit-key',
      );

      expect(debit.keyForPayload('same'), 'debit-key');
      expect(credit.keyForPayload('same'), 'credit-key');
    });
  });
}
