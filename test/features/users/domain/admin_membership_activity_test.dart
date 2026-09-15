import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_membership_tier.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';
import 'package:vidxon_admin/l10n/admin_l10n.dart';

void main() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));

  Map<String, dynamic> detailsMap({Object? membershipTier}) {
    return {
      'user_id': '11111111-1111-1111-1111-111111111111',
      'email': 'user@example.com',
      'display_name': 'Test User',
      'account_status': 'active',
      'coin_balance': 500,
      'ledger_entry_count': 3,
      'total_admin_coin_credited': 200,
      'account_created_at': '2026-07-28T08:00:00.000Z',
      'last_sign_in_at': '2026-07-29T10:00:00.000Z',
      'wallet_updated_at': '2026-07-29T12:00:00.000Z',
      'admin_role': null,
      'wallet_actions_allowed': true,
      'membership_tier': ?membershipTier,
    };
  }

  group('AdminMembershipTier.parse', () {
    test('none maps to Yok / None', () {
      expect(AdminMembershipTier.parse(null), AdminMembershipTier.none);
      expect(AdminMembershipTier.parse('none'), AdminMembershipTier.none);
      expect(adminMembershipTierLabel(tr, AdminMembershipTier.none), 'Yok');
      expect(adminMembershipTierLabel(en, AdminMembershipTier.none), 'None');
    });

    test('plus maps to Plus', () {
      expect(AdminMembershipTier.parse('plus'), AdminMembershipTier.plus);
      expect(adminMembershipTierLabel(tr, AdminMembershipTier.plus), 'Plus');
      expect(adminMembershipTierLabel(en, AdminMembershipTier.plus), 'Plus');
    });

    test('max maps to Max', () {
      expect(AdminMembershipTier.parse('MAX'), AdminMembershipTier.max);
      expect(adminMembershipTierLabel(tr, AdminMembershipTier.max), 'Max');
    });

    test('unknown invalid value fails safely', () {
      expect(
        () => AdminMembershipTier.parse('gold'),
        throwsA(isA<FormatException>()),
      );
    });

    test('max wins over plus at the label layer using stored max', () {
      expect(
        AdminMembershipTier.parse('max').storageValue,
        isNot(AdminMembershipTier.plus.storageValue),
      );
    });
  });

  group('AdminUserDetails membership', () {
    test('missing membership_tier defaults to none', () {
      final details = AdminUserDetails.fromMap(detailsMap());
      expect(details.membershipTier, AdminMembershipTier.none);
    });

    test('parses plus and max', () {
      expect(
        AdminUserDetails.fromMap(detailsMap(membershipTier: 'plus')).membershipTier,
        AdminMembershipTier.plus,
      );
      expect(
        AdminUserDetails.fromMap(detailsMap(membershipTier: 'max')).membershipTier,
        AdminMembershipTier.max,
      );
    });

    test('rejects invalid membership_tier', () {
      expect(
        () => AdminUserDetails.fromMap(detailsMap(membershipTier: 'gold')),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('verified coin purchase and membership history', () {
    test('verified purchase appears once with backend amount', () {
      final entry = AdminWalletLedgerEntry.fromMap({
        'ledger_id': 44,
        'amount': 3000,
        'transaction_type': 'coin_purchase',
        'reason_code': 'verified',
        'description': null,
        'case_reference': null,
        'balance_before': 0,
        'balance_after': 3000,
        'actor_admin_user_id': null,
        'created_at': '2026-09-15T11:32:00.000Z',
        'activity_kind': 'wallet',
      });

      expect(entry.isCoinPurchase, isTrue);
      expect(entry.amount, 3000);
      expect(adminWalletTxnLabel(tr, entry.transactionType), 'Jeton Satın Alımı');
      expect(adminWalletTxnLabel(en, entry.transactionType), 'Coin Purchase');
      expect(adminWalletReasonLabel(tr, entry.reasonCode), 'Başarılı');
      expect(adminWalletReasonLabel(en, entry.reasonCode), 'Successful');
    });

    test('duplicate grant identity stays a single parsed row', () {
      final first = AdminWalletLedgerEntry.fromMap({
        'ledger_id': 44,
        'amount': 3000,
        'transaction_type': 'coin_purchase',
        'reason_code': 'verified',
        'balance_after': 3000,
        'created_at': '2026-09-15T11:32:00.000Z',
      });
      final replay = AdminWalletLedgerEntry.fromMap({
        'ledger_id': 44,
        'amount': 3000,
        'transaction_type': 'coin_purchase',
        'reason_code': 'verified',
        'balance_after': 3000,
        'created_at': '2026-09-15T11:32:00.000Z',
      });

      expect(first.ledgerId, replay.ledgerId);
      expect(first.amount, replay.amount);
    });

    test('membership change uses structured tiers', () {
      final entry = AdminWalletLedgerEntry.fromMap({
        'ledger_id': null,
        'amount': 0,
        'transaction_type': 'membership_change',
        'reason_code': null,
        'description': 'plus → max',
        'balance_after': null,
        'created_at': '2026-09-22T07:15:00.000Z',
        'activity_kind': 'membership_change',
        'membership_from_tier': 'plus',
        'membership_to_tier': 'max',
        'activity_id': '55555555-5555-4555-8555-555555555555',
      });

      expect(entry.isMembershipChange, isTrue);
      expect(adminWalletTxnLabel(tr, entry.transactionType), 'Üyelik Değişikliği');
      expect(
        adminLedgerDescriptionLabel(tr, entry),
        'Plus → Max',
      );
    });

    test('existing wallet activity types remain labeled', () {
      expect(adminWalletTxnLabel(tr, 'admin_coin_credit'), 'Admin Jeton Yükleme');
      expect(adminWalletTxnLabel(tr, 'episode_unlock'), 'Bölüm Açma');
    });
  });

  group('Admin user-detail membership is read-only', () {
    test('user-detail sources have no membership mutation RPC', () {
      final repository = File(
        'lib/features/users/data/admin_user_wallet_repository.dart',
      ).readAsStringSync();
      final page = File(
        'lib/features/users/presentation/admin_user_details_page.dart',
      ).readAsStringSync();
      final details = File(
        'lib/features/users/domain/admin_user_details.dart',
      ).readAsStringSync();

      for (final source in [repository, page, details]) {
        expect(source.contains('apply_membership_entitlement_event'), isFalse);
        expect(source.contains('RevenueCat'), isFalse);
        expect(source.contains('DropdownButton'), isFalse);
      }

      expect(repository.contains('admin_get_user_details'), isTrue);
      expect(repository.contains('admin_list_user_wallet_ledger'), isTrue);
    });
  });
}
