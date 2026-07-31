import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_errors.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_result.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  Map<dynamic, dynamic> sampleUserRow() {
    return {
      'user_id': userId,
      'email': 'user@example.com',
      'display_name': 'Example',
      'account_created_at': '2026-07-27T17:14:20.106837+00:00',
      'last_sign_in_at': '2026-07-27T17:15:27.458491+00:00',
      'account_status': 'active',
      'coin_balance': 0,
      'admin_role': null,
      'wallet_actions_allowed': true,
    };
  }

  group('parseRpcListResult', () {
    test('parses List with Map<dynamic, dynamic> rows', () {
      final rows = parseRpcListResult([sampleUserRow()]);

      expect(rows, hasLength(1));
      expect(rows.first['email'], 'user@example.com');

      final users = rows.map(AdminUserSummary.fromMap).toList(growable: false);
      expect(users.first.userId, userId);
      expect(users.first.coinBalance, 0);
    });

    test('rejects non-list top-level response', () {
      expect(
        () => parseRpcListResult({'user_id': userId}),
        throwsA(isA<AdminUserWalletException>()),
      );
    });

    test('rejects non-map list elements', () {
      expect(
        () => parseRpcListResult(['not-a-map']),
        throwsA(isA<AdminUserWalletException>()),
      );
    });

    test('accepts empty list', () {
      final rows = parseRpcListResult([]);
      expect(rows, isEmpty);
    });
  });

  group('parseRpcMapResult', () {
    test('parses Map<dynamic, dynamic> response', () {
      final map = parseRpcMapResult({
        'ledger_id': 10,
        'user_id': userId,
        'amount': 100,
        'balance_before': 0,
        'balance_after': 100,
        'transaction_type': 'credit',
        'reason_code': 'customer_support',
        'was_replayed': false,
      });

      final result = AdminCoinCreditResult.fromMap(map);
      expect(result.wasReplayed, isFalse);
    });

    test('parses single-item list response', () {
      final map = parseRpcMapResult([
        {
          'user_id': userId,
          'email': 'user@example.com',
          'display_name': null,
          'account_status': 'active',
          'coin_balance': 120,
          'ledger_entry_count': 1,
          'total_admin_coin_credited': 100,
          'account_created_at': '2026-07-27T17:14:20.106837+00:00',
          'wallet_actions_allowed': true,
          'admin_role': null,
        },
      ]);

      expect(map['coin_balance'], 120);
    });

    test('empty list uses configured failure for details contract', () {
      expect(
        () => parseRpcMapResult(
          [],
          emptyResultKind: AdminUserWalletFailureKind.userNotFound,
          emptyResultMessage: 'Kullanıcı bulunamadı.',
        ),
        throwsA(
          isA<AdminUserWalletException>().having(
            (error) => error.kind,
            'kind',
            AdminUserWalletFailureKind.userNotFound,
          ),
        ),
      );
    });
  });

  group('parseRpcVoidResult', () {
    test('accepts null response', () {
      expect(() => parseRpcVoidResult(null), returnsNormally);
    });

    test('accepts empty list response', () {
      expect(() => parseRpcVoidResult([]), returnsNormally);
    });
  });

  group('ledger list normalization', () {
    test('parses ledger rows from dynamic maps', () {
      final rows = parseRpcListResult([
        {
          'ledger_id': 3,
          'amount': 50,
          'transaction_type': 'credit',
          'reason_code': 'customer_support',
          'balance_before': 100,
          'balance_after': 150,
          'created_at': '2026-07-29T12:00:00.000Z',
        },
      ]);

      final entries = rows
          .map(AdminWalletLedgerEntry.fromMap)
          .toList(growable: false);

      expect(entries.first.ledgerId, 3);
      expect(entries.first.signedAmountLabel, '+50');
    });
  });
}
