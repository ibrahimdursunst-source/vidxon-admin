import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_role.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/admins/data/admin_management_repository.dart';
import 'package:vidxon_admin/features/admins/domain/admin_account_summary.dart';
import 'package:vidxon_admin/features/admins/presentation/admin_add_admin_dialog.dart';
import 'package:vidxon_admin/features/admins/presentation/admin_management_page.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_errors.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/features/users/presentation/user_list_search_logic.dart';

const _actorId = '11111111-1111-1111-1111-111111111111';
const _normalUserId = '22222222-2222-2222-2222-222222222222';
const _adminUserId = '33333333-3333-3333-3333-333333333333';
const _superAdminUserId = '44444444-4444-4444-4444-444444444444';

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

AdminUserSummary _normalUser({String? email, String? displayName}) {
  return AdminUserSummary.fromMap({
    'user_id': _normalUserId,
    'email': email,
    'display_name': displayName,
    'account_status': 'active',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': null,
    'wallet_actions_allowed': true,
  });
}

AdminUserSummary _existingAdminUser() {
  return AdminUserSummary.fromMap({
    'user_id': _adminUserId,
    'email': 'admin@example.com',
    'display_name': 'Existing Admin',
    'account_status': 'active',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': 'admin',
    'wallet_actions_allowed': false,
  });
}

AdminUserSummary _existingSuperAdminUser() {
  return AdminUserSummary.fromMap({
    'user_id': _superAdminUserId,
    'email': 'super@example.com',
    'display_name': 'Existing Super Admin',
    'account_status': 'active',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': 'super_admin',
    'wallet_actions_allowed': false,
  });
}

class _FakeSearchRepository extends AdminUserWalletRepository {
  _FakeSearchRepository(this._handler) : super(client: null);

  final Future<List<AdminUserSummary>> Function(String query) _handler;

  int searchCallCount = 0;
  String? lastQuery;
  int? lastLimit;

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) {
    searchCallCount += 1;
    lastQuery = query;
    lastLimit = limit;
    return _handler(query);
  }
}

class _DelayedSearchRepository extends AdminUserWalletRepository {
  _DelayedSearchRepository(this._responses) : super(client: null);

  final Map<String, Future<List<AdminUserSummary>>> _responses;

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) {
    return _responses[query] ?? Future.value(const []);
  }
}

class _FakeManagementRepository extends AdminManagementRepository {
  _FakeManagementRepository({
    Future<List<AdminAccountSummary>> Function()? listHandler,
    Future<void> Function(String userId, AdminRole role)? setRoleHandler,
  }) : super(client: null) {
    _listHandler = listHandler ?? (() async => []);
    _setRoleHandler =
        setRoleHandler ??
        ((_, _) async {
          return;
        });
  }

  late final Future<List<AdminAccountSummary>> Function() _listHandler;
  late final Future<void> Function(String userId, AdminRole role)
  _setRoleHandler;

  int listCallCount = 0;
  int setRoleCallCount = 0;
  String? lastSetRoleUserId;
  AdminRole? lastSetRole;

  @override
  Future<List<AdminAccountSummary>> listAdminUsers({
    int limit = 50,
    int offset = 0,
  }) {
    listCallCount += 1;
    return _listHandler();
  }

  @override
  Future<void> setAdminRole({required String userId, required AdminRole role}) {
    setRoleCallCount += 1;
    lastSetRoleUserId = userId;
    lastSetRole = role;
    return _setRoleHandler(userId, role);
  }
}

Future<void> tapDialogSearchButton(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ),
  );
}

Future<void> _openAddAdminDialog(
  WidgetTester tester, {
  AdminUserWalletRepository? searchRepository,
  _FakeManagementRepository? managementRepository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showAdminAddAdminDialog(
                    context: context,
                    userRepository: searchRepository,
                    managementRepository: managementRepository,
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('admin add search logic', () {
    test('empty query is not ready', () {
      expect(isAdminAddSearchQueryReady(''), isFalse);
      expect(isAdminAddSearchQueryReady('   '), isFalse);
    });

    test('non-empty query is ready', () {
      expect(isAdminAddSearchQueryReady('user'), isTrue);
    });

    test('canAddUserAsAdmin allows normal users only', () {
      expect(canAddUserAsAdmin(_normalUser()), isTrue);
      expect(canAddUserAsAdmin(_existingAdminUser()), isFalse);
      expect(canAddUserAsAdmin(_existingSuperAdminUser()), isFalse);
    });

    test('buildAdminAddSuccessMessage uses role labels', () {
      expect(
        buildAdminAddSuccessMessage(
          displayName: 'Test User',
          role: AdminRole.admin,
        ),
        'Test User Admin olarak eklendi.',
      );
      expect(
        buildAdminAddSuccessMessage(
          displayName: 'Test User',
          role: AdminRole.superAdmin,
        ),
        'Test User Super Admin olarak eklendi.',
      );
    });

    test('adminRolePermissionDescription includes super admin warning', () {
      expect(
        adminRolePermissionDescription(AdminRole.superAdmin),
        contains('yönetici rollerini değiştirebilir'),
      );
      expect(
        adminRolePermissionDescription(AdminRole.admin),
        contains('cüzdan işlemlerini yönetebilir'),
      );
    });
  });

  group('AdminManagementPage add button', () {
    testWidgets('super admin sees Yönetici Ekle button', (tester) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          child: AdminManagementPage(
            repository: _FakeManagementRepository(listHandler: () async => []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yönetici Ekle'), findsOneWidget);
    });

    testWidgets('normal admin cannot see add button or page', (tester) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_adminContext()),
          child: AdminManagementPage(
            repository: _FakeManagementRepository(listHandler: () async => []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yönetici Ekle'), findsNothing);
      expect(
        find.text('Bu sayfaya erişim için Super Admin yetkisi gerekiyor.'),
        findsOneWidget,
      );
    });

    testWidgets('context loading keeps add button hidden', (tester) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: const AdminContextLoadResult.loading(),
          child: AdminManagementPage(
            repository: _FakeManagementRepository(listHandler: () async => []),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Yönetici Ekle'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('context error keeps add button hidden', (tester) async {
      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: const AdminContextLoadResult.error('Context failed'),
          child: AdminManagementPage(
            repository: _FakeManagementRepository(listHandler: () async => []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yönetici Ekle'), findsNothing);
    });
  });

  group('AdminAddAdminDialog search', () {
    testWidgets('empty query does not auto-load users on open', (tester) async {
      final searchRepository = _FakeSearchRepository((_) async => []);

      await _openAddAdminDialog(tester, searchRepository: searchRepository);

      expect(find.text('Yönetici Ekle'), findsOneWidget);
      expect(searchRepository.searchCallCount, 0);
    });

    testWidgets('manual search loads users', (tester) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_normalUser()],
      );

      await _openAddAdminDialog(tester, searchRepository: searchRepository);

      await tester.enterText(find.byType(TextField), 'normal');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(searchRepository.searchCallCount, 1);
      expect(searchRepository.lastQuery, 'normal');
      expect(find.text('Yönetici Yap'), findsOneWidget);
    });

    testWidgets('debounce and Ara do not duplicate same query RPC', (
      tester,
    ) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_normalUser()],
      );

      await _openAddAdminDialog(tester, searchRepository: searchRepository);

      await tester.enterText(find.byType(TextField), 'normal');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(searchRepository.searchCallCount, 1);

      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(searchRepository.searchCallCount, 1);
    });

    testWidgets('stale response does not overwrite newer search', (
      tester,
    ) async {
      final firstCompleter = Completer<List<AdminUserSummary>>();
      final secondCompleter = Completer<List<AdminUserSummary>>();

      final searchRepository = _DelayedSearchRepository({
        'first': firstCompleter.future,
        'second': secondCompleter.future,
      });

      await _openAddAdminDialog(tester, searchRepository: searchRepository);

      await tester.enterText(find.byType(TextField), 'first');
      await tapDialogSearchButton(tester);
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'second');
      await tapDialogSearchButton(tester);
      await tester.pump();

      secondCompleter.complete([_normalUser(displayName: 'Fresh Result')]);
      await tester.pumpAndSettle();

      firstCompleter.complete([_normalUser(displayName: 'Stale Result')]);
      await tester.pumpAndSettle();

      expect(find.text('Fresh Result'), findsOneWidget);
      expect(find.text('Stale Result'), findsNothing);
    });

    testWidgets('nullable email and display_name use fallbacks', (
      tester,
    ) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_normalUser(email: null, displayName: null)],
      );

      await _openAddAdminDialog(tester, searchRepository: searchRepository);

      await tester.enterText(find.byType(TextField), 'anon');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(find.text('Anonim Kullanıcı'), findsOneWidget);
      expect(find.text('E-posta yok'), findsOneWidget);
    });
  });

  group('AdminAddAdminDialog selection and role', () {
    Future<void> selectNormalUser(WidgetTester tester) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_normalUser(displayName: 'New Admin')],
      );

      await _openAddAdminDialog(tester, searchRepository: searchRepository);
      await tester.enterText(find.byType(TextField), 'new');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yönetici Yap'));
      await tester.pumpAndSettle();
    }

    testWidgets('existing admin cannot be re-added', (tester) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_existingAdminUser()],
      );

      await _openAddAdminDialog(tester, searchRepository: searchRepository);
      await tester.enterText(find.byType(TextField), 'admin');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Yönetici Yap'), findsNothing);
    });

    testWidgets('existing super admin cannot be re-added', (tester) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_existingSuperAdminUser()],
      );

      await _openAddAdminDialog(tester, searchRepository: searchRepository);
      await tester.enterText(find.byType(TextField), 'super');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();

      expect(find.text('Super Admin'), findsWidgets);
      expect(find.text('Yönetici Yap'), findsNothing);
    });

    testWidgets('default role is Admin', (tester) async {
      await selectNormalUser(tester);

      final segmentedButton = tester.widget<SegmentedButton<AdminRole>>(
        find.byType(SegmentedButton<AdminRole>),
      );
      expect(segmentedButton.selected, {AdminRole.admin});
    });

    testWidgets('super admin selection shows permission warning', (
      tester,
    ) async {
      await selectNormalUser(tester);

      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('yönetici rollerini değiştirebilir'),
        findsOneWidget,
      );
    });
  });

  group('AdminAddAdminDialog submit', () {
    Future<void> goToConfirm(
      WidgetTester tester, {
      AdminRole role = AdminRole.admin,
      _FakeManagementRepository? managementRepository,
    }) async {
      final searchRepository = _FakeSearchRepository(
        (_) async => [_normalUser(displayName: 'New Admin')],
      );

      await _openAddAdminDialog(
        tester,
        searchRepository: searchRepository,
        managementRepository: managementRepository,
      );
      await tester.enterText(find.byType(TextField), 'new');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yönetici Yap'));
      await tester.pumpAndSettle();

      if (role == AdminRole.superAdmin) {
        await tester.tap(find.text('Super Admin'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
    }

    testWidgets('sends exact p_user_id and p_role to repository', (
      tester,
    ) async {
      final managementRepository = _FakeManagementRepository();

      await goToConfirm(tester, managementRepository: managementRepository);
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();

      expect(managementRepository.setRoleCallCount, 1);
      expect(managementRepository.lastSetRoleUserId, _normalUserId);
      expect(managementRepository.lastSetRole, AdminRole.admin);
    });

    testWidgets('double submit creates single RPC call', (tester) async {
      final completer = Completer<void>();
      final managementRepository = _FakeManagementRepository(
        setRoleHandler: (_, _) => completer.future,
      );

      await goToConfirm(tester, managementRepository: managementRepository);

      await tester.tap(find.text('Onayla'));
      await tester.pump();

      expect(managementRepository.setRoleCallCount, 1);

      final confirmButtons = tester.widgetList<FilledButton>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      expect(confirmButtons, hasLength(1));
      expect(confirmButtons.first.onPressed, isNull);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('success closes dialog and refreshes admin list', (
      tester,
    ) async {
      var listCalls = 0;
      final searchRepository = _FakeSearchRepository(
        (_) async => [_normalUser(displayName: 'New Admin')],
      );
      final managementRepository = _FakeManagementRepository(
        listHandler: () async {
          listCalls += 1;
          if (listCalls == 1) {
            return [];
          }
          return [
            AdminAccountSummary.fromMap({
              'user_id': _normalUserId,
              'email': 'new@example.com',
              'display_name': 'New Admin',
              'role': 'admin',
              'admin_created_at': '2026-07-27T17:14:20.106837+00:00',
              'account_created_at': '2026-07-27T17:14:20.106837+00:00',
            }),
          ];
        },
      );

      await tester.pumpWidget(
        _wrapWithContext(
          contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
          child: Scaffold(
            body: AdminManagementPage(
              repository: managementRepository,
              userSearchRepository: searchRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(listCalls, 1);

      await tester.tap(find.text('Yönetici Ekle'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'new');
      await tester.tap(find.text('Ara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yönetici Yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();

      expect(find.text('Yönetici Ekle'), findsOneWidget);
      expect(find.text('New Admin'), findsWidgets);
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('New Admin Admin olarak eklendi.'), findsOneWidget);
      expect(listCalls, greaterThan(1));
    });

    testWidgets('super admin role is sent to repository', (tester) async {
      final managementRepository = _FakeManagementRepository();

      await goToConfirm(
        tester,
        role: AdminRole.superAdmin,
        managementRepository: managementRepository,
      );
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();

      expect(managementRepository.setRoleCallCount, 1);
      expect(managementRepository.lastSetRole, AdminRole.superAdmin);
      expect(find.text('Rol Seç'), findsNothing);
    });

    testWidgets('RPC error shows safe Turkish message', (tester) async {
      final managementRepository = _FakeManagementRepository(
        setRoleHandler: (_, _) async {
          throw AdminUserWalletException(
            message: 'Kullanıcı bulunamadı.',
            kind: AdminUserWalletFailureKind.userNotFound,
          );
        },
      );

      await goToConfirm(tester, managementRepository: managementRepository);
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcı bulunamadı.'), findsOneWidget);
    });
  });

  group('setAdminRole RPC params', () {
    test('buildSetAdminRoleRpcParams uses backend values', () {
      final params = buildSetAdminRoleRpcParams(
        userId: _normalUserId,
        role: AdminRole.superAdmin,
      );

      expect(params['p_user_id'], _normalUserId);
      expect(params['p_role'], 'super_admin');
    });
  });
}
