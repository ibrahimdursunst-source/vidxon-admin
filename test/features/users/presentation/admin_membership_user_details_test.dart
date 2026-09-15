import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';

class _FakeRepo extends AdminUserWalletRepository {
  _FakeRepo({required this.details, required this.ledger}) : super(client: null);

  final AdminUserDetails details;
  final List<AdminWalletLedgerEntry> ledger;

  @override
  Future<AdminUserDetails> getUserDetails({required String userId}) async {
    return details;
  }

  @override
  Future<List<AdminWalletLedgerEntry>> listUserWalletLedger({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    return ledger;
  }
}

AdminUserDetails _details({String membershipTier = 'none'}) {
  return AdminUserDetails.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'email': 'user@example.com',
    'display_name': 'Ada',
    'account_status': 'active',
    'coin_balance': 3000,
    'ledger_entry_count': 2,
    'total_admin_coin_credited': 0,
    'account_created_at': '2026-07-28T08:00:00.000Z',
    'wallet_actions_allowed': true,
    'membership_tier': membershipTier,
  });
}

AdminWalletLedgerEntry _coinPurchase() {
  return AdminWalletLedgerEntry.fromMap({
    'ledger_id': 10,
    'amount': 3000,
    'transaction_type': 'coin_purchase',
    'reason_code': 'verified',
    'balance_before': 0,
    'balance_after': 3000,
    'created_at': '2026-09-15T11:32:00.000Z',
    'activity_kind': 'wallet',
  });
}

AdminWalletLedgerEntry _membershipChange() {
  return AdminWalletLedgerEntry.fromMap({
    'ledger_id': null,
    'amount': 0,
    'transaction_type': 'membership_change',
    'description': 'plus → max',
    'created_at': '2026-09-22T07:15:00.000Z',
    'activity_kind': 'membership_change',
    'membership_from_tier': 'plus',
    'membership_to_tier': 'max',
    'activity_id': '55555555-5555-4555-8555-555555555555',
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows Yok for none and no membership editor', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AdminUserDetailsPage(
          userId: '11111111-1111-1111-1111-111111111111',
          repository: _FakeRepo(details: _details(), ledger: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Üyelik'), findsOneWidget);
    expect(find.text('Yok'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('shows Plus for plus membership', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AdminUserDetailsPage(
          userId: '11111111-1111-1111-1111-111111111111',
          repository: _FakeRepo(
            details: _details(membershipTier: 'plus'),
            ledger: const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plus'), findsWidgets);
  });

  testWidgets('shows Max and verified purchase plus membership history', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AdminUserDetailsPage(
          userId: '11111111-1111-1111-1111-111111111111',
          repository: _FakeRepo(
            details: _details(membershipTier: 'max'),
            ledger: [_coinPurchase(), _membershipChange()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Max'), findsWidgets);
    expect(find.textContaining('Jeton Satın Alımı'), findsOneWidget);
    expect(find.textContaining('Başarılı'), findsOneWidget);
    expect(find.textContaining('Üyelik Değişikliği'), findsOneWidget);
    expect(find.textContaining('Plus → Max'), findsWidgets);
    expect(find.text('Jeton Yükle'), findsOneWidget);
  });
}
