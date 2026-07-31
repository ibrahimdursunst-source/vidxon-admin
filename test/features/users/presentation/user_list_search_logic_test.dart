import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/features/users/presentation/user_list_search_logic.dart';

void main() {
  group('shouldSkipDebouncedUserSearch', () {
    test('skips when query already loaded', () {
      expect(
        shouldSkipDebouncedUserSearch(
          query: '',
          activeQuery: '',
          isLoading: false,
          isLoadingMore: false,
        ),
        isTrue,
      );
    });

    test('does not skip when query changed', () {
      expect(
        shouldSkipDebouncedUserSearch(
          query: 'user@example.com',
          activeQuery: '',
          isLoading: false,
          isLoadingMore: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldSkipDuplicateInFlightSearch', () {
    test('skips duplicate in-flight search for same query', () {
      expect(
        shouldSkipDuplicateInFlightSearch(
          query: '',
          inFlightQuery: '',
          isLoading: true,
          reset: true,
        ),
        isTrue,
      );
    });

    test('allows search when previous request finished', () {
      expect(
        shouldSkipDuplicateInFlightSearch(
          query: '',
          inFlightQuery: '',
          isLoading: false,
          reset: true,
        ),
        isFalse,
      );
    });
  });

  group('isAdminAddSearchQueryReady', () {
    test('rejects empty query', () {
      expect(isAdminAddSearchQueryReady(''), isFalse);
      expect(isAdminAddSearchQueryReady('  '), isFalse);
    });

    test('accepts meaningful query', () {
      expect(isAdminAddSearchQueryReady('user@example.com'), isTrue);
    });
  });

  group('canAddUserAsAdmin', () {
    test('allows users without admin role', () {
      final user = AdminUserSummary.fromMap({
        'user_id': '11111111-1111-1111-1111-111111111111',
        'email': 'user@example.com',
        'display_name': 'User',
        'account_status': 'active',
        'coin_balance': 0,
        'account_created_at': '2026-07-27T17:14:20.106837+00:00',
        'admin_role': null,
        'wallet_actions_allowed': true,
      });

      expect(canAddUserAsAdmin(user), isTrue);
    });
  });
}
