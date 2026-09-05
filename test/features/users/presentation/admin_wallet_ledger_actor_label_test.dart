import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';
import 'package:vidxon_admin/l10n/admin_l10n.dart';

void main() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));

  AdminWalletLedgerEntry entry({String? actorId, String? actorEmail}) {
    return AdminWalletLedgerEntry(
      ledgerId: 1,
      amount: 10,
      transactionType: 'admin_coin_credit',
      balanceAfter: 10,
      createdAt: DateTime.utc(2026, 7, 29),
      actorAdminUserId: actorId,
      actorAdminEmail: actorEmail,
    );
  }

  test('null actor displays localized System', () {
    expect(adminLedgerActorLabel(tr, entry()), 'Sistem');
    expect(adminLedgerActorLabel(en, entry()), 'System');
  });

  test('actor and email displays email', () {
    const actorId = '33333333-3333-3333-3333-333333333333';
    final labeled = entry(actorId: actorId, actorEmail: 'actor@example.com');

    expect(adminLedgerActorLabel(tr, labeled), 'actor@example.com');
    expect(adminLedgerActorLabel(en, labeled), 'actor@example.com');
    expect(labeled.actorAdminUserId, actorId);
  });

  test('actor without email falls back to shortened UID', () {
    const actorId = '33333333-3333-3333-3333-333333333333';
    final labeled = entry(actorId: actorId);

    expect(adminLedgerActorLabel(tr, labeled), '33333333…');
    expect(labeled.actorAdminUserId, actorId);
    expect(labeled.actorAdminEmail, isNull);
  });

  test('wallet history code does not query auth.users or use service_role', () {
    final repository = File(
      'lib/features/users/data/admin_user_wallet_repository.dart',
    ).readAsStringSync();
    final page = File(
      'lib/features/users/presentation/admin_user_details_page.dart',
    ).readAsStringSync();
    final model = File(
      'lib/features/users/domain/admin_wallet_ledger_entry.dart',
    ).readAsStringSync();

    for (final source in [repository, page, model]) {
      expect(source.contains("from('auth.users')"), isFalse);
      expect(source.contains('service_role'), isFalse);
    }

    expect(repository.contains('admin_list_user_wallet_ledger'), isTrue);
  });
}
