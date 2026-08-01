import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_coin_credit_dialog.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';
import 'package:vidxon_admin/features/users/presentation/admin_users_page.dart';

class _FakeAdminUserWalletRepository extends AdminUserWalletRepository {
  _FakeAdminUserWalletRepository({
    required this.searchHandler,
    this.detailsHandler,
    this.ledgerHandler,
  }) : super(client: null);

  final Future<List<AdminUserSummary>> Function({
    required String query,
    required int limit,
    required int offset,
  })
  searchHandler;

  final Future<AdminUserDetails> Function({required String userId})?
  detailsHandler;

  final Future<List<AdminWalletLedgerEntry>> Function({
    required String userId,
    required int limit,
    required int offset,
  })?
  ledgerHandler;

  int searchCallCount = 0;
  final List<String> queries = [];

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    searchCallCount += 1;
    queries.add(query);
    return searchHandler(query: query, limit: limit, offset: offset);
  }

  @override
  Future<AdminUserDetails> getUserDetails({required String userId}) async {
    if (detailsHandler == null) {
      throw UnimplementedError();
    }
    return detailsHandler!(userId: userId);
  }

  @override
  Future<List<AdminWalletLedgerEntry>> listUserWalletLedger({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (ledgerHandler == null) {
      return const [];
    }
    return ledgerHandler!(userId: userId, limit: limit, offset: offset);
  }
}

AdminUserSummary _sampleUser({String email = 'user@example.com'}) {
  return AdminUserSummary.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'email': email,
    'display_name': 'Example',
    'account_status': 'active',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': null,
    'wallet_actions_allowed': true,
  });
}

AdminUserSummary _anonymousUser() {
  return AdminUserSummary.fromMap({
    'user_id': '22222222-2222-2222-2222-222222222222',
    'email': null,
    'display_name': null,
    'account_status': 'unconfirmed',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:35:44.396159+00:00',
    'last_sign_in_at': '2026-07-27T17:35:44.430462+00:00',
    'admin_role': null,
    'wallet_actions_allowed': true,
  });
}

AdminUserDetails _anonymousDetails() {
  return AdminUserDetails.fromMap({
    'user_id': '22222222-2222-2222-2222-222222222222',
    'email': null,
    'display_name': null,
    'account_status': 'unconfirmed',
    'coin_balance': 0,
    'ledger_entry_count': 0,
    'total_admin_coin_credited': 0,
    'account_created_at': '2026-07-27T17:35:44.396159+00:00',
    'last_sign_in_at': null,
    'wallet_updated_at': null,
    'admin_role': null,
    'wallet_actions_allowed': true,
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminUsersPage initial load', () {
    testWidgets('loads empty query exactly once on first open', (tester) async {
      final repository = _FakeAdminUserWalletRepository(
        searchHandler:
            ({required query, required limit, required offset}) async {
              return [_sampleUser()];
            },
      );

      await tester.pumpWidget(_wrap(AdminUsersPage(repository: repository)));
      await tester.pumpAndSettle();

      expect(repository.searchCallCount, 1);
      expect(repository.queries, ['']);
      expect(find.text('Example'), findsOneWidget);
    });

    testWidgets('shows mixed list with anonymous user on first load', (
      tester,
    ) async {
      final repository = _FakeAdminUserWalletRepository(
        searchHandler:
            ({required query, required limit, required offset}) async {
              return [_sampleUser(), _anonymousUser()];
            },
      );

      await tester.pumpWidget(_wrap(AdminUsersPage(repository: repository)));
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcı listesi yanıtı geçersiz.'), findsNothing);
      expect(find.text('Kullanıcılar yüklenemedi'), findsNothing);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Anonim Kullanıcı'), findsOneWidget);
      expect(find.text('E-posta yok'), findsOneWidget);
      expect(find.text('Onaylanmamış'), findsOneWidget);
    });

    testWidgets('manual search works after initial load', (tester) async {
      final repository = _FakeAdminUserWalletRepository(
        searchHandler:
            ({required query, required limit, required offset}) async {
              if (query == 'user@example.com') {
                return [_sampleUser(email: 'user@example.com')];
              }
              return [_sampleUser(email: 'other@example.com')];
            },
      );

      await tester.pumpWidget(_wrap(AdminUsersPage(repository: repository)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(repository.queries.last, 'user@example.com');
      expect(find.text('user@example.com'), findsWidgets);
    });

    testWidgets('shows error when repository fails', (tester) async {
      final repository = _FakeAdminUserWalletRepository(
        searchHandler:
            ({required query, required limit, required offset}) async {
              throw Exception('Kullanıcı listesi yanıtı geçersiz.');
            },
      );

      await tester.pumpWidget(_wrap(AdminUsersPage(repository: repository)));
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcılar yüklenemedi'), findsOneWidget);
    });
  });

  group('AdminUserDetailsPage anonymous user', () {
    testWidgets('opens and shows safe fallbacks', (tester) async {
      final repository = _FakeAdminUserWalletRepository(
        searchHandler:
            ({required query, required limit, required offset}) async {
              return const [];
            },
        detailsHandler: ({required userId}) async => _anonymousDetails(),
        ledgerHandler:
            ({required userId, required limit, required offset}) async {
              return const [];
            },
      );

      await tester.pumpWidget(
        _wrap(
          AdminUserDetailsPage(
            userId: '22222222-2222-2222-2222-222222222222',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anonim Kullanıcı'), findsOneWidget);
      expect(find.text('E-posta yok'), findsOneWidget);
      expect(find.text('22222222…'), findsOneWidget);
      expect(find.text('Onaylanmamış'), findsOneWidget);
    });
  });

  group('AdminCoinCreditDialog anonymous user', () {
    testWidgets('form shows safe fallback labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAdminCoinCreditDialog(
                    context: context,
                    user: _anonymousDetails(),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Anonim Kullanıcı (E-posta yok)'), findsOneWidget);
    });
  });
}
