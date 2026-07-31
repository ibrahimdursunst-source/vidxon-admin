import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_errors.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/domain/wallet_ledger_display.dart';

void main() {
  Map<String, dynamic> legacyRow({
    String transactionType = 'episode_unlock',
    int ledgerId = 3,
  }) {
    return {
      'ledger_id': ledgerId,
      'amount': transactionType == 'admin_test_credit' ? 100 : -30,
      'transaction_type': transactionType,
      'reason_code': null,
      'description': null,
      'case_reference': null,
      'balance_before': null,
      'balance_after': transactionType == 'admin_test_credit' ? 100 : 40,
      'actor_admin_user_id': null,
      'created_at': '2026-07-26T18:57:08.574001+00:00',
    };
  }

  group('legacy AdminWalletLedgerEntry.fromMap', () {
    test('parses episode_unlock with nullable legacy fields', () {
      final entry = AdminWalletLedgerEntry.fromMap(legacyRow());

      expect(entry.transactionType, 'episode_unlock');
      expect(entry.reasonCode, isNull);
      expect(entry.balanceBefore, isNull);
      expect(entry.actorAdminUserId, isNull);
      expect(entry.balanceAfter, 40);
    });

    test('parses admin_test_credit legacy row', () {
      final entry = AdminWalletLedgerEntry.fromMap(
        legacyRow(transactionType: 'admin_test_credit', ledgerId: 1),
      );

      expect(entry.transactionTypeLabel, 'Eski Test Kredisi');
      expect(entry.amount, 100);
    });

    test('parses rewarded_ad legacy row', () {
      final entry = AdminWalletLedgerEntry.fromMap(
        legacyRow(transactionType: 'rewarded_ad', ledgerId: 4),
      );

      expect(entry.transactionTypeLabel, 'Reklam Ödülü');
    });

    test('rejects missing balance_after', () {
      final row = legacyRow()..remove('balance_after');

      expect(
        () => AdminWalletLedgerEntry.fromMap(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing ledger_id', () {
      final row = legacyRow()..remove('ledger_id');

      expect(
        () => AdminWalletLedgerEntry.fromMap(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid amount type', () {
      final row = legacyRow()..['amount'] = 'invalid';

      expect(
        () => AdminWalletLedgerEntry.fromMap(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid created_at', () {
      final row = legacyRow()..['created_at'] = 'not-a-date';

      expect(
        () => AdminWalletLedgerEntry.fromMap(row),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('admin_coin_credit ledger row', () {
    test('parses full admin_coin_credit row', () {
      final rows = parseRpcListResult([
        {
          'ledger_id': 10,
          'amount': 500,
          'transaction_type': 'admin_coin_credit',
          'reason_code': 'customer_support',
          'description': 'Destek talebi jeton yüklemesi',
          'case_reference': 'CASE-123',
          'balance_before': 120,
          'balance_after': 620,
          'actor_admin_user_id': '33333333-3333-3333-3333-333333333333',
          'created_at': '2026-07-29T12:00:00.000Z',
        },
      ]);

      final entry = AdminWalletLedgerEntry.fromMap(rows.first);

      expect(entry.transactionTypeLabel, 'Admin Jeton Yükleme');
      expect(entry.reasonLabel, 'Müşteri Desteği');
      expect(entry.descriptionLabel, 'Destek talebi jeton yüklemesi');
      expect(entry.balanceBefore, 120);
    });
  });

  group('WalletLedgerDisplay', () {
    test('shows em dash and Sistem for null legacy fields', () {
      final entry = AdminWalletLedgerEntry.fromMap(legacyRow());

      expect(entry.reasonLabel, '—');
      expect(entry.descriptionLabel, '—');
      expect(entry.caseReferenceLabel, '—');
      expect(entry.balanceBeforeLabel, '—');
      expect(entry.actorLabel, 'Sistem');
    });

    test('keeps unknown transaction type readable', () {
      expect(
        WalletLedgerDisplay.transactionTypeLabel('custom_event'),
        'custom_event',
      );
    });
  });
}
