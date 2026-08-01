import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/admins/data/admin_management_repository.dart';
import 'package:vidxon_admin/features/admins/domain/admin_account_summary.dart';
import 'package:vidxon_admin/features/admins/presentation/admin_management_page.dart';
import 'package:vidxon_admin/features/audit/domain/admin_audit_entry.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';

const _actorId = '11111111-1111-1111-1111-111111111111';
const _targetId = '22222222-2222-2222-2222-222222222222';

Widget _wrapWithContext({
  required AdminContextLoadResult contextResult,
  required Widget child,
}) {
  return MaterialApp(
    home: AdminContextScope(contextResult: contextResult, child: child),
  );
}

AdminCurrentContext _superAdminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': _actorId,
    'role': 'super_admin',
    'is_super_admin': true,
  });
}

AdminCurrentContext _adminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': _actorId,
    'role': 'admin',
    'is_super_admin': false,
  });
}

AdminUserDetails _protectedAdminDetails() {
  return AdminUserDetails.fromMap({
    'user_id': _targetId,
    'email': 'admin@example.com',
    'display_name': 'Panel Admin',
    'account_status': 'active',
    'coin_balance': 0,
    'ledger_entry_count': 0,
    'total_admin_coin_credited': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': 'admin',
    'wallet_actions_allowed': false,
  });
}

class _FakeManagementRepository extends AdminManagementRepository {
  _FakeManagementRepository(this._handler) : super(client: null);

  final Future<List<AdminAccountSummary>> Function() _handler;

  int listCallCount = 0;

  @override
  Future<List<AdminAccountSummary>> listAdminUsers({
    int limit = 50,
    int offset = 0,
  }) {
    listCallCount += 1;
    return _handler();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminHomePage navigation', () {
    test('super admin context enables management nav', () {
      final result = AdminContextLoadResult.loaded(_superAdminContext());
      expect(result.isSuperAdmin, isTrue);
    });

    test('normal admin context hides management nav', () {
      final result = AdminContextLoadResult.loaded(_adminContext());
      expect(result.isSuperAdmin, isFalse);
    });

    test('context error does not grant super admin nav', () {
      const result = AdminContextLoadResult.error('Context failed');
      expect(result.isSuperAdmin, isFalse);
      expect(result.hasContext, isFalse);
    });
  });

  group('AdminUserDetailsPage wallet protection', () {
    testWidgets('disables wallet buttons for admin account', (tester) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          child: AdminUserDetailsPage(
            userId: _targetId,
            repository: _ProtectedDetailsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Admin hesaplarında manuel jeton işlemleri yapılamaz.'),
        findsOneWidget,
      );

      final creditButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Jeton Yükle'),
      );
      final debitButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Jeton Eksilt'),
      );

      expect(creditButton.onPressed, isNull);
      expect(debitButton.onPressed, isNull);
    });
  });

  group('AdminManagementPage access', () {
    testWidgets('blocks normal admin before RPC', (tester) async {
      final repository = _FakeManagementRepository(() async => []);

      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_adminContext()),
          child: AdminManagementPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Bu sayfaya erişim için Super Admin yetkisi gerekiyor.'),
        findsOneWidget,
      );
      expect(repository.listCallCount, 0);
    });

    testWidgets('shows loading while context is loading', (tester) async {
      final repository = _FakeManagementRepository(() async => []);

      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: const AdminContextLoadResult.loading(),
          child: AdminManagementPage(repository: repository),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.listCallCount, 0);
    });

    testWidgets('disables self action buttons', (tester) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          child: AdminManagementPage(
            repository: _FakeManagementRepository(
              () async => [
                AdminAccountSummary.fromMap({
                  'user_id': _actorId,
                  'email': 'self@example.com',
                  'display_name': 'Self Admin',
                  'role': 'super_admin',
                  'admin_created_at': '2026-07-27T17:14:20.106837+00:00',
                  'account_created_at': '2026-07-27T17:14:20.106837+00:00',
                }),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kendi hesabınız'), findsOneWidget);
      expect(find.text('Admin Yap'), findsNothing);
      expect(find.text('Erişimi Kaldır'), findsNothing);
    });
  });

  group('AdminAuditPage filters', () {
    test('invalid target UUID is rejected before RPC params', () {
      expect(
        () => buildListAuditLogRpcParams(
          targetUserId: 'not-a-uuid',
          limit: 50,
          offset: 0,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        validateAuditTargetUserIdFilter('not-a-uuid'),
        'Geçersiz hedef kullanıcı ID.',
      );
      expect(validateAuditTargetUserIdFilter(''), isNull);
    });
  });

  group('AdminAuditEntry', () {
    test('parses wallet debit audit row', () {
      final entry = AdminAuditEntry.fromMap({
        'audit_id': '33333333-3333-3333-3333-333333333333',
        'action_type': 'wallet.admin_coin_debit',
        'actor_admin_user_id': _actorId,
        'actor_email': 'actor@example.com',
        'actor_role': 'admin',
        'target_user_id': _targetId,
        'target_email': 'target@example.com',
        'amount': 50,
        'balance_before': 100,
        'balance_after': 50,
        'reason_code': 'customer_support',
        'description': 'Support correction',
        'case_reference': 'CASE-1',
        'metadata': {'amount': 50},
        'created_at': '2026-07-29T12:00:00.000Z',
      });

      expect(entry.actionTypeLabel, 'Jeton Eksiltme');
      expect(entry.metadata?['amount'], 50);
    });

    test('rejects invalid metadata type', () {
      expect(
        () => AdminAuditEntry.fromMap({
          'audit_id': '33333333-3333-3333-3333-333333333333',
          'action_type': 'wallet.admin_coin_credit',
          'created_at': '2026-07-29T12:00:00.000Z',
          'metadata': 'not-an-object',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

class _ProtectedDetailsRepository extends AdminUserWalletRepository {
  _ProtectedDetailsRepository() : super(client: null);

  @override
  Future<AdminUserDetails> getUserDetails({required String userId}) async {
    return _protectedAdminDetails();
  }

  @override
  Future<List<AdminWalletLedgerEntry>> listUserWalletLedger({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    return const [];
  }
}
