import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';

void main() {
  group('wallet ledger ordering', () {
    test('preserves newest-first order from RPC list', () {
      final entries = [
        AdminWalletLedgerEntry.fromMap({
          'ledger_id': 3,
          'amount': 50,
          'transaction_type': 'credit',
          'reason_code': 'customer_support',
          'balance_before': 100,
          'balance_after': 150,
          'created_at': '2026-07-29T12:00:00.000Z',
        }),
        AdminWalletLedgerEntry.fromMap({
          'ledger_id': 2,
          'amount': 100,
          'transaction_type': 'credit',
          'reason_code': 'promotional',
          'balance_before': 0,
          'balance_after': 100,
          'created_at': '2026-07-28T12:00:00.000Z',
        }),
      ];

      expect(entries.first.ledgerId, 3);
      expect(entries.last.ledgerId, 2);
    });
  });
}
