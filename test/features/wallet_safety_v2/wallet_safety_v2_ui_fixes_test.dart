import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/admins/data/admin_management_repository.dart';
import 'package:vidxon_admin/features/admins/domain/admin_account_summary.dart';
import 'package:vidxon_admin/features/admins/presentation/admin_management_page.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_errors.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_input.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_credit_result.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_debit_input.dart';
import 'package:vidxon_admin/features/users/domain/admin_coin_debit_result.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_coin_credit_dialog.dart';
import 'package:vidxon_admin/features/users/presentation/admin_coin_debit_dialog.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';
import 'package:vidxon_admin/features/users/presentation/admin_wallet_mutation_permission.dart';

const _actorId = '11111111-1111-1111-1111-111111111111';
const _otherAdminId = '22222222-2222-2222-2222-222222222222';
const _normalUserId = '33333333-3333-3333-3333-333333333333';

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

AdminUserDetails _normalUserDetails() {
  return AdminUserDetails.fromMap({
    'user_id': _normalUserId,
    'email': 'user@example.com',
    'display_name': 'Normal User',
    'account_status': 'active',
    'coin_balance': 100,
    'ledger_entry_count': 0,
    'total_admin_coin_credited': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'wallet_actions_allowed': true,
  });
}

AdminUserDetails _protectedAdminDetails() {
  return AdminUserDetails.fromMap({
    'user_id': _otherAdminId,
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

List<AdminAccountSummary> _sampleAdmins() {
  return [
    AdminAccountSummary.fromMap({
      'user_id': _actorId,
      'email': 'self@example.com',
      'display_name': 'Self Admin',
      'role': 'super_admin',
      'admin_created_at': '2026-07-27T17:14:20.106837+00:00',
      'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    }),
    AdminAccountSummary.fromMap({
      'user_id': _otherAdminId,
      'email': 'other@example.com',
      'display_name': 'Other Admin',
      'role': 'admin',
      'admin_created_at': '2026-07-27T17:14:20.106837+00:00',
      'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    }),
  ];
}

class _FakeManagementRepository extends AdminManagementRepository {
  _FakeManagementRepository(this._handler) : super(client: null);

  final Future<List<AdminAccountSummary>> Function() _handler;

  @override
  Future<List<AdminAccountSummary>> listAdminUsers({
    int limit = 50,
    int offset = 0,
  }) {
    return _handler();
  }
}

class _TrackingWalletRepository extends AdminUserWalletRepository {
  _TrackingWalletRepository(this.details) : super(client: null);

  final AdminUserDetails details;
  int creditCallCount = 0;
  int debitCallCount = 0;

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
    return const [];
  }

  @override
  Future<AdminCoinCreditResult> creditUserCoins({
    required AdminCoinCreditInput input,
    required String idempotencyKey,
  }) async {
    creditCallCount += 1;
    return AdminCoinCreditResult.fromMap({
      'user_id': input.userId,
      'amount': input.amount,
      'balance_before': details.coinBalance,
      'balance_after': details.coinBalance + input.amount,
      'was_replayed': false,
    });
  }

  @override
  Future<AdminCoinDebitResult> debitUserCoins({
    required AdminCoinDebitInput input,
    required String idempotencyKey,
  }) async {
    debitCallCount += 1;
    return AdminCoinDebitResult.fromMap({
      'user_id': input.userId,
      'amount': input.amount,
      'balance_before': details.coinBalance,
      'balance_after': details.coinBalance - input.amount,
      'was_replayed': false,
    });
  }
}

Widget _wrapWithContext({
  required AdminContextLoadResult contextResult,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    builder: (context, appChild) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: appChild ?? const SizedBox.shrink(),
      );
    },
    home: AdminContextScope(contextResult: contextResult, child: child),
  );
}

Future<void> _pumpManagementPage(
  WidgetTester tester, {
  required Size surfaceSize,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _wrapWithContext(
      contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
      textScaler: textScaler,
      child: AdminManagementPage(
        repository: _FakeManagementRepository(() async => _sampleAdmins()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpUserDetails(
  WidgetTester tester, {
  required AdminContextLoadResult contextResult,
  required AdminUserDetails details,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    _wrapWithContext(
      contextResult: contextResult,
      textScaler: textScaler,
      child: AdminUserDetailsPage(
        userId: details.userId,
        repository: _TrackingWalletRepository(details),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminManagementPage actions layout', () {
    testWidgets('desktop table actions do not overflow', (tester) async {
      await _pumpManagementPage(tester, surfaceSize: const Size(1600, 900));

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.text('Kendi hesabınız'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1200px layout keeps actions accessible', (tester) async {
      await _pumpManagementPage(tester, surfaceSize: const Size(1200, 900));

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('900px uses card layout without table overflow', (
      tester,
    ) async {
      await _pumpManagementPage(tester, surfaceSize: const Size(900, 900));

      expect(find.byIcon(Icons.more_vert), findsWidgets);
      expect(find.byType(DataTable), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('600px card layout keeps actions visible', (tester) async {
      await _pumpManagementPage(tester, surfaceSize: const Size(600, 900));

      expect(find.byIcon(Icons.more_vert), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text scale avoids overlapping action rows', (
      tester,
    ) async {
      await _pumpManagementPage(
        tester,
        surfaceSize: const Size(1600, 900),
        textScaler: const TextScaler.linear(1.4),
      );

      expect(find.text('Kendi hesabınız'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('self row hides role and revoke actions', (tester) async {
      await _pumpManagementPage(tester, surfaceSize: const Size(1600, 900));

      expect(find.text('Kendi hesabınız'), findsOneWidget);
      expect(find.text('Admin Yap'), findsNothing);
      expect(find.text('Erişimi Kaldır'), findsNothing);
    });

    testWidgets('other admin row exposes operations menu', (tester) async {
      await _pumpManagementPage(tester, surfaceSize: const Size(1600, 900));

      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);
      await tester.ensureVisible(menuButton);
      await tester.pumpAndSettle();
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.text('Super Admin Yap'), findsOneWidget);
      expect(find.text('Erişimi Kaldır'), findsOneWidget);
      expect(find.text('Admin Yap'), findsNothing);
    });
  });

  group('coin dialog cancel', () {
    testWidgets('credit form cancel closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAdminCoinCreditDialog(
                        context: context,
                        user: _normalUserDetails(),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('debit form cancel closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAdminCoinDebitDialog(
                        context: context,
                        user: _normalUserDetails(),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('credit confirm geri returns to form without closing page', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAdminCoinCreditDialog(
                        context: context,
                        user: _normalUserDetails(),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '10');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Test credit note',
      );
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();

      expect(find.text('İşlemi Onayla'), findsOneWidget);

      await tester.tap(find.text('Geri'));
      await tester.pumpAndSettle();

      expect(find.text('Jeton Yükle'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('credit confirm iptal closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAdminCoinCreditDialog(
                        context: context,
                        user: _normalUserDetails(),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '10');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Test credit note',
      );
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(find.text('İşlemi Onayla'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('wallet mutation permissions', () {
    test('normal admin cannot mutate wallet for normal user', () {
      expect(
        canMutateAdminWallet(
          contextResult: AdminContextLoadResult.loaded(_adminContext()),
          walletActionsAllowed: true,
        ),
        isFalse,
      );
      expect(
        adminWalletMutationRestrictionMessage(
          contextResult: AdminContextLoadResult.loaded(_adminContext()),
          walletActionsAllowed: true,
        ),
        'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.',
      );
    });

    test('super admin can mutate wallet for normal user', () {
      expect(
        canMutateAdminWallet(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          walletActionsAllowed: true,
        ),
        isTrue,
      );
    });

    test('super admin cannot mutate protected admin wallet', () {
      expect(
        canMutateAdminWallet(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          walletActionsAllowed: false,
        ),
        isFalse,
      );
      expect(
        adminWalletMutationRestrictionMessage(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          walletActionsAllowed: false,
        ),
        'Admin hesaplarında manuel jeton işlemleri yapılamaz.',
      );
    });

    testWidgets('normal admin sees disabled wallet buttons for normal user', (
      tester,
    ) async {
      await _pumpUserDetails(
        tester,
        contextResult: AdminContextLoadResult.loaded(_adminContext()),
        details: _normalUserDetails(),
      );

      expect(
        find.text(
          'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.',
        ),
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

    testWidgets('super admin sees active wallet buttons for normal user', (
      tester,
    ) async {
      await _pumpUserDetails(
        tester,
        contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
        details: _normalUserDetails(),
      );

      final creditButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Jeton Yükle'),
      );
      final debitButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Jeton Eksilt'),
      );

      expect(creditButton.onPressed, isNotNull);
      expect(debitButton.onPressed, isNotNull);
    });

    testWidgets('super admin cannot open credit for protected admin target', (
      tester,
    ) async {
      final repository = _TrackingWalletRepository(_protectedAdminDetails());

      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          child: AdminUserDetailsPage(
            userId: _otherAdminId,
            repository: repository,
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
      expect(creditButton.onPressed, isNull);
      expect(repository.creditCallCount, 0);
    });

    testWidgets('context loading keeps wallet buttons disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: const AdminContextLoadResult.loading(),
          child: AdminUserDetailsPage(
            userId: _normalUserId,
            repository: _TrackingWalletRepository(_normalUserDetails()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final creditButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Jeton Yükle'),
      );
      expect(creditButton.onPressed, isNull);
    });

    test('wallet mutation error mapping separates super admin message', () {
      final error = AdminUserWalletErrorMapper.fromPostgrestForWalletMutation(
        const PostgrestException(message: 'Super admin access required'),
      );

      expect(
        error.message,
        'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.',
      );
      expect(error.kind, AdminUserWalletFailureKind.superAdminRequired);
    });

    test('protected admin wallet error stays distinct', () {
      final error = AdminUserWalletErrorMapper.fromPostgrestForWalletMutation(
        const PostgrestException(
          message: 'Admin accounts are protected from manual wallet operations',
        ),
      );

      expect(
        error.message,
        'Admin hesaplarında manuel jeton işlemleri yapılamaz.',
      );
      expect(error.kind, AdminUserWalletFailureKind.protectedAdminWallet);
    });
  });
}
