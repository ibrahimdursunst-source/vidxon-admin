import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_result.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/domain/user_parse_helpers.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';
  const anonymousUserId = '22222222-2222-2222-2222-222222222222';
  const accountCreatedAt = '2026-07-28T08:00:00.000Z';

  Map<String, dynamic> summaryMap({
    String? id = userId,
    Object? email = 'user@example.com',
    Object? displayName = 'Test User',
    String accountStatus = 'active',
    int coinBalance = 120,
    Object? lastSignInAt = '2026-07-29T10:00:00.000Z',
  }) {
    return {
      'user_id': id,
      'email': email,
      'display_name': displayName,
      'account_status': accountStatus,
      'coin_balance': coinBalance,
      'account_created_at': accountCreatedAt,
      'last_sign_in_at': lastSignInAt,
    };
  }

  group('AdminUserSummary.fromMap', () {
    test('parses user with email and display_name', () {
      final user = AdminUserSummary.fromMap(summaryMap());

      expect(user.userId, userId);
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'Test User');
      expect(user.coinBalance, 120);
      expect(user.accountStatusLabel, 'Aktif');
      expect(user.resolvedDisplayName, 'Test User');
      expect(user.resolvedEmailLabel, 'user@example.com');
    });

    test('uses email when display_name is null', () {
      final user = AdminUserSummary.fromMap(summaryMap(displayName: null));

      expect(user.resolvedDisplayName, 'user@example.com');
    });

    test('uses display_name when email is null', () {
      final user = AdminUserSummary.fromMap(
        summaryMap(email: null, displayName: 'Named User'),
      );

      expect(user.resolvedDisplayName, 'Named User');
      expect(user.resolvedEmailLabel, 'E-posta yok');
    });

    test('shows anonymous fallback when email and display_name are null', () {
      final user = AdminUserSummary.fromMap(
        summaryMap(
          id: anonymousUserId,
          email: null,
          displayName: null,
          accountStatus: 'unconfirmed',
          coinBalance: 0,
          lastSignInAt: null,
        ),
      );

      expect(user.resolvedDisplayName, 'Anonim Kullanıcı');
      expect(user.resolvedEmailLabel, 'E-posta yok');
      expect(user.accountStatusLabel, 'Onaylanmamış');
      expect(user.lastSignInAt, isNull);
    });

    test('accepts null last_sign_in_at', () {
      final user = AdminUserSummary.fromMap(summaryMap(lastSignInAt: null));

      expect(user.lastSignInAt, isNull);
    });

    test('trims email and treats empty string as null', () {
      final user = AdminUserSummary.fromMap(
        summaryMap(email: '  user@example.com  ', displayName: null),
      );

      expect(user.email, 'user@example.com');
      expect(user.resolvedDisplayName, 'user@example.com');
    });

    test('treats blank display_name as null and falls back to email', () {
      final user = AdminUserSummary.fromMap(summaryMap(displayName: '   '));

      expect(user.displayName, isNull);
      expect(user.resolvedDisplayName, 'user@example.com');
    });

    test('rejects email with wrong type', () {
      expect(
        () => AdminUserSummary.fromMap(summaryMap(email: 42)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects display_name with wrong type', () {
      expect(
        () => AdminUserSummary.fromMap(summaryMap(displayName: 42)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid user_id', () {
      expect(
        () => AdminUserSummary.fromMap(summaryMap(id: 'not-a-uuid')),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing coin_balance', () {
      final map = summaryMap();
      map.remove('coin_balance');

      expect(
        () => AdminUserSummary.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects wrong coin_balance type', () {
      final map = summaryMap();
      map['coin_balance'] = true;

      expect(
        () => AdminUserSummary.fromMap(map),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses mixed empty-query response without failing entire list', () {
      final users = [
        AdminUserSummary.fromMap(summaryMap()),
        AdminUserSummary.fromMap(
          summaryMap(
            id: anonymousUserId,
            email: null,
            displayName: null,
            accountStatus: 'unconfirmed',
            coinBalance: 0,
            lastSignInAt: '2026-07-27T17:35:44.430462+00:00',
          ),
        ),
      ];

      expect(users, hasLength(2));
      expect(users.first.resolvedDisplayName, 'Test User');
      expect(users.last.resolvedDisplayName, 'Anonim Kullanıcı');
    });
  });

  group('buildSearchUsersRpcParams', () {
    test('uses expected keys', () {
      final params = buildSearchUsersRpcParams(
        query: 'test',
        limit: 50,
        offset: 0,
      );

      expect(params.keys, containsAll(['p_query', 'p_limit', 'p_offset']));
    });
  });

  group('AdminUserDetails.fromMap', () {
    Map<String, dynamic> detailsMap({
      Object? email = 'user@example.com',
      Object? displayName,
      Object? lastSignInAt,
      Object? walletUpdatedAt = '2026-07-29T12:00:00.000Z',
    }) {
      return {
        'user_id': userId,
        'email': email,
        'display_name': displayName,
        'account_status': 'active',
        'coin_balance': 500,
        'ledger_entry_count': 3,
        'total_admin_coin_credited': 200,
        'account_created_at': accountCreatedAt,
        'last_sign_in_at': lastSignInAt,
        'wallet_updated_at': walletUpdatedAt,
      };
    }

    test('parses balance and timestamps', () {
      final details = AdminUserDetails.fromMap(detailsMap());

      expect(details.coinBalance, 500);
      expect(details.walletUpdatedAt?.isUtc, isTrue);
      expect(details.ledgerEntryCount, 3);
    });

    test('supports anonymous identity fields', () {
      final details = AdminUserDetails.fromMap(
        detailsMap(
          email: null,
          displayName: null,
          lastSignInAt: null,
          walletUpdatedAt: null,
        ),
      );

      expect(details.resolvedDisplayName, 'Anonim Kullanıcı');
      expect(details.resolvedEmailLabel, 'E-posta yok');
      expect(details.lastSignInAt, isNull);
      expect(details.walletUpdatedAt, isNull);
    });
  });

  group('buildGetUserDetailsRpcParams', () {
    test('uses p_user_id key', () {
      final params = buildGetUserDetailsRpcParams(userId: userId);
      expect(params.keys, ['p_user_id']);
      expect(params['p_user_id'], userId);
    });
  });

  group('AdminWalletLedgerEntry.fromMap', () {
    test('parses bigint ledger id', () {
      final entry = AdminWalletLedgerEntry.fromMap({
        'ledger_id': 922337203685477580,
        'amount': 100,
        'transaction_type': 'credit',
        'reason_code': 'customer_support',
        'description': 'Destek yüklemesi',
        'case_reference': 'CASE-1',
        'balance_before': 20,
        'balance_after': 120,
        'actor_admin_user_id': '33333333-3333-3333-3333-333333333333',
        'created_at': '2026-07-29T12:00:00.000Z',
      });

      expect(entry.ledgerId, 922337203685477580);
      expect(entry.signedAmountLabel, '+100');
    });
  });

  group('buildListUserWalletLedgerRpcParams', () {
    test('uses pagination keys', () {
      final params = buildListUserWalletLedgerRpcParams(
        userId: userId,
        limit: 50,
        offset: 100,
      );

      expect(params.keys, containsAll(['p_user_id', 'p_limit', 'p_offset']));
    });
  });

  group('AdminCoinCreditResult.fromMap', () {
    test('accepts was_replayed true', () {
      final result = AdminCoinCreditResult.fromMap({
        'ledger_id': 10,
        'user_id': userId,
        'amount': 100,
        'balance_before': 20,
        'balance_after': 120,
        'transaction_type': 'credit',
        'reason_code': 'customer_support',
        'was_replayed': true,
        'created_at': '2026-07-29T12:00:00.000Z',
      });

      expect(result.wasReplayed, isTrue);
    });
  });

  group('UserParseHelpers.requireUserId', () {
    test('rejects invalid uuid', () {
      expect(
        () => UserParseHelpers.requireUserId('not-a-uuid'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('formatUserDisplayName', () {
    test('prefers trimmed display name', () {
      expect(
        formatUserDisplayName(displayName: '  Ada  ', email: 'a@b.com'),
        'Ada',
      );
    });

    test('falls back to email when display name empty', () {
      expect(
        formatUserDisplayName(displayName: '  ', email: 'a@b.com'),
        'a@b.com',
      );
    });

    test('shows anonymous when both identity fields missing', () {
      expect(
        formatUserDisplayName(displayName: null, email: null),
        'Anonim Kullanıcı',
      );
    });
  });

  group('formatUserEmailLabel', () {
    test('shows placeholder when email missing', () {
      expect(formatUserEmailLabel(null), 'E-posta yok');
      expect(formatUserEmailLabel('   '), 'E-posta yok');
    });
  });

  group('formatAccountStatusLabel', () {
    test('maps known statuses', () {
      expect(formatAccountStatusLabel('active'), 'Aktif');
      expect(formatAccountStatusLabel('unconfirmed'), 'Onaylanmamış');
    });

    test('returns raw value for unknown status', () {
      expect(formatAccountStatusLabel('pending_review'), 'pending_review');
    });
  });
}
