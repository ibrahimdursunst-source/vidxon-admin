import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_root_navigator.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';
import 'package:vidxon_admin/features/users/presentation/admin_users_page.dart';

const _actorId = '11111111-1111-1111-1111-111111111111';
const _normalUserId = '33333333-3333-3333-3333-333333333333';
const _adminTargetId = '22222222-2222-2222-2222-222222222222';
const _superAdminTargetId = '44444444-4444-4444-4444-444444444444';

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

AdminUserDetails _adminTargetDetails() {
  return AdminUserDetails.fromMap({
    'user_id': _adminTargetId,
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

AdminUserDetails _superAdminTargetDetails() {
  return AdminUserDetails.fromMap({
    'user_id': _superAdminTargetId,
    'email': 'super@example.com',
    'display_name': 'Other Super Admin',
    'account_status': 'active',
    'coin_balance': 0,
    'ledger_entry_count': 0,
    'total_admin_coin_credited': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': 'super_admin',
    'wallet_actions_allowed': false,
  });
}

AdminUserSummary _normalUserSummary() {
  return AdminUserSummary.fromMap({
    'user_id': _normalUserId,
    'email': 'user@example.com',
    'display_name': 'Normal User',
    'account_status': 'active',
    'coin_balance': 100,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'wallet_actions_allowed': true,
  });
}

class _FakeWalletRepository extends AdminUserWalletRepository {
  _FakeWalletRepository(this._detailsById) : super(client: null);

  final Map<String, AdminUserDetails> _detailsById;

  @override
  Future<AdminUserDetails> getUserDetails({required String userId}) async {
    final details = _detailsById[userId];
    if (details == null) {
      throw StateError('Unknown user: $userId');
    }
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
}

class _FakeUsersListRepository extends AdminUserWalletRepository {
  _FakeUsersListRepository(this.users) : super(client: null);

  final List<AdminUserSummary> users;

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    return users;
  }

  @override
  Future<AdminUserDetails> getUserDetails({required String userId}) async {
    return _normalUserDetails();
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

Future<void> _pumpScopedNavigatorDetails({
  required WidgetTester tester,
  required AdminContextLoadResult contextResult,
  required AdminUserDetails details,
}) async {
  final repository = _FakeWalletRepository({details.userId: details});

  await tester.pumpWidget(
    MaterialApp(
      home: AdminContextScope(
        contextResult: contextResult,
        child: Navigator(
          onGenerateRoute: (settings) {
            if (settings.name == '/details') {
              return MaterialPageRoute<void>(
                builder: (_) => AdminUserDetailsPage(
                  userId: details.userId,
                  repository: repository,
                ),
              );
            }

            return MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/details');
                    },
                    child: const Text('Open Details'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open Details'));
  await tester.pumpAndSettle();
}

class _ContextTransitionHarness extends StatefulWidget {
  const _ContextTransitionHarness({required this.details});

  final AdminUserDetails details;

  @override
  State<_ContextTransitionHarness> createState() =>
      _ContextTransitionHarnessState();
}

class _ContextTransitionHarnessState extends State<_ContextTransitionHarness> {
  AdminContextLoadResult _result = const AdminContextLoadResult.loading();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration.zero, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _result = AdminContextLoadResult.loaded(_superAdminContext());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = _FakeWalletRepository({
      widget.details.userId: widget.details,
    });

    return MaterialApp(
      home: AdminContextScope(
        contextResult: _result,
        child: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              builder: (_) => AdminUserDetailsPage(
                userId: widget.details.userId,
                repository: repository,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContextKeyHarness extends StatefulWidget {
  const _ContextKeyHarness({
    required this.userId,
    required this.contextResult,
    required this.details,
  });

  final String userId;
  final AdminContextLoadResult contextResult;
  final AdminUserDetails details;

  @override
  State<_ContextKeyHarness> createState() => _ContextKeyHarnessState();
}

class _ContextKeyHarnessState extends State<_ContextKeyHarness> {
  late AdminContextLoadResult _contextResult;

  @override
  void initState() {
    super.initState();
    _contextResult = widget.contextResult;
  }

  @override
  void didUpdateWidget(covariant _ContextKeyHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _contextResult = widget.contextResult;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = _FakeWalletRepository({
      widget.details.userId: widget.details,
    });

    return MaterialApp(
      home: AdminContextScope(
        key: ValueKey(widget.userId),
        contextResult: _contextResult,
        child: AdminUserDetailsPage(
          userId: widget.details.userId,
          repository: repository,
        ),
      ),
    );
  }
}

FilledButton _creditButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Jeton Yükle'),
  );
}

OutlinedButton _debitButton(WidgetTester tester) {
  return tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, 'Jeton Eksilt'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminUserDetailsPage navigation scope', () {
    testWidgets('navigator push keeps AdminContextScope accessible', (
      tester,
    ) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
        details: _normalUserDetails(),
      );

      expect(_creditButton(tester).onPressed, isNotNull);
      expect(_debitButton(tester).onPressed, isNotNull);
    });

    testWidgets('root material navigator push without scope disables buttons', (
      tester,
    ) async {
      final repository = _FakeWalletRepository({
        _normalUserId: _normalUserDetails(),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminUserDetailsPage(
                            userId: _normalUserId,
                            repository: repository,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Details'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
    });

    testWidgets('AdminRootNavigator is a nested navigator widget', (
      tester,
    ) async {
      const navigator = AdminRootNavigator(email: 'actor@example.com');
      expect(navigator, isA<StatelessWidget>());
      expect(navigator.email, 'actor@example.com');
    });

    testWidgets('super admin credit button opens dialog', (tester) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
        details: _normalUserDetails(),
      );

      await tester.tap(find.text('Jeton Yükle'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Jeton Yükle'), findsWidgets);
    });

    testWidgets('super admin debit button opens dialog', (tester) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
        details: _normalUserDetails(),
      );

      await tester.tap(find.text('Jeton Eksilt'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Jeton Eksilt'), findsWidgets);
    });

    testWidgets('loaded admin context keeps wallet buttons disabled', (
      tester,
    ) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_adminContext()),
        details: _normalUserDetails(),
      );

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
      expect(
        find.text(
          'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('normal admin callback guard does not open credit dialog', (
      tester,
    ) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_adminContext()),
        details: _normalUserDetails(),
      );

      expect(_creditButton(tester).onPressed, isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('super admin admin target keeps buttons disabled', (
      tester,
    ) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
        details: _adminTargetDetails(),
      );

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
      expect(
        find.text('Admin hesaplarında manuel jeton işlemleri yapılamaz.'),
        findsOneWidget,
      );
    });

    testWidgets('super admin super admin target keeps buttons disabled', (
      tester,
    ) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
        details: _superAdminTargetDetails(),
      );

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
    });

    testWidgets('context loading keeps buttons fail-closed', (tester) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: const AdminContextLoadResult.loading(),
        details: _normalUserDetails(),
      );

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
    });

    testWidgets('context error keeps buttons fail-closed', (tester) async {
      await _pumpScopedNavigatorDetails(
        tester: tester,
        contextResult: const AdminContextLoadResult.error('Context failed'),
        details: _normalUserDetails(),
      );

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
    });

    testWidgets('context loaded rebuild activates wallet buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ContextTransitionHarness(details: _normalUserDetails()),
      );
      await tester.pump();

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);

      await tester.pumpAndSettle();

      expect(_creditButton(tester).onPressed, isNotNull);
      expect(_debitButton(tester).onPressed, isNotNull);
    });

    testWidgets('context key change resets super admin access', (tester) async {
      await tester.pumpWidget(
        _ContextKeyHarness(
          userId: _actorId,
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          details: _normalUserDetails(),
        ),
      );
      await tester.pumpAndSettle();

      expect(_creditButton(tester).onPressed, isNotNull);

      await tester.pumpWidget(
        _ContextKeyHarness(
          userId: '99999999-9999-9999-9999-999999999999',
          contextResult: AdminContextLoadResult.loaded(_adminContext()),
          details: _normalUserDetails(),
        ),
      );
      await tester.pumpAndSettle();

      expect(_creditButton(tester).onPressed, isNull);
      expect(_debitButton(tester).onPressed, isNull);
    });

    testWidgets(
      'walletActionsAllowed false cannot be bypassed by super admin',
      (tester) async {
        await _pumpScopedNavigatorDetails(
          tester: tester,
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          details: _adminTargetDetails(),
        );

        expect(_creditButton(tester).onPressed, isNull);
        expect(_debitButton(tester).onPressed, isNull);
      },
    );

    testWidgets('AdminUsersPage push keeps scope for wallet buttons', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final listRepository = _FakeUsersListRepository([_normalUserSummary()]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
            child: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: AdminUsersPage(repository: listRepository),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final detailButton = find.text('Detay');
      expect(detailButton, findsOneWidget);
      await tester.ensureVisible(detailButton);
      await tester.pumpAndSettle();
      await tester.tap(detailButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminUserDetailsPage), findsOneWidget);
      expect(_creditButton(tester).onPressed, isNotNull);
      expect(_debitButton(tester).onPressed, isNotNull);
    });
  });
}
