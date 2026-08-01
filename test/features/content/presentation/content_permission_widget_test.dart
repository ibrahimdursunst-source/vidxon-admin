import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/episodes/domain/cloudflare_stream_status.dart';
import 'package:vidxon_admin/features/episodes/presentation/series_episodes_page.dart';
import 'package:vidxon_admin/features/series/presentation/series_detail_page.dart';
import 'package:vidxon_admin/features/series/presentation/series_list_page.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_details.dart';
import 'package:vidxon_admin/features/users/domain/admin_wallet_ledger_entry.dart';
import 'package:vidxon_admin/features/users/presentation/admin_user_details_page.dart';
import 'package:vidxon_admin/main.dart' show AdminAuthorizationGate;
import '../content_test_helpers.dart';

const _normalUserId = '33333333-3333-3333-3333-333333333333';
const _adminTargetId = '22222222-2222-2222-2222-222222222222';

AdminCurrentContext _adminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'role': 'admin',
    'is_super_admin': false,
  });
}

AdminCurrentContext _superAdminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'role': 'super_admin',
    'is_super_admin': true,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  group('Content permissions', () {
    testWidgets('normal admin can access series list create affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: Scaffold(
              body: SeriesListPage(
                onCreateTap: () {},
                repository: FakeSeriesRepository(
                  (_) async => testSeries(),
                  fetchAllResult: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yeni Dizi'), findsOneWidget);
    });

    testWidgets('super admin can access series list create affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
            child: Scaffold(
              body: SeriesListPage(
                onCreateTap: () {},
                repository: FakeSeriesRepository(
                  (_) async => testSeries(),
                  fetchAllResult: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yeni Dizi'), findsOneWidget);
    });

    testWidgets('episode list remains accessible under admin context', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: SeriesEpisodesPage(
              seriesId: testSeriesId,
              seriesTitle: 'Test',
              episodeRepository: FakeEpisodeRepository([]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yeni Bölüm'), findsOneWidget);
    });
  });

  group('Wallet permission regression with content scope', () {
    testWidgets('normal admin wallet buttons stay disabled for normal user', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_adminContext()),
            child: AdminUserDetailsPage(
              userId: _normalUserId,
              repository: _FakeWalletRepository({
                _normalUserId: _normalUserDetails(),
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final credit = find.widgetWithText(FilledButton, 'Jeton Yükle');
      final debit = find.widgetWithText(OutlinedButton, 'Jeton Eksilt');
      expect(tester.widget<FilledButton>(credit).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(debit).onPressed, isNull);
    });

    testWidgets('super admin wallet buttons active for normal user', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
            child: AdminUserDetailsPage(
              userId: _normalUserId,
              repository: _FakeWalletRepository({
                _normalUserId: _normalUserDetails(),
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final credit = find.widgetWithText(FilledButton, 'Jeton Yükle');
      expect(tester.widget<FilledButton>(credit).onPressed, isNotNull);
    });

    testWidgets('super admin cannot mutate protected admin wallet', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: AdminContextLoadResult.loaded(_superAdminContext()),
            child: AdminUserDetailsPage(
              userId: _adminTargetId,
              repository: _FakeWalletRepository({
                _adminTargetId: _adminTargetDetails(),
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final credit = find.widgetWithText(FilledButton, 'Jeton Yükle');
      expect(tester.widget<FilledButton>(credit).onPressed, isNull);
    });
  });

  group('Content permission edge cases', () {
    testWidgets('context loading disables series create affordance', (
      tester,
    ) async {
      var createTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: const AdminContextLoadResult.loading(),
            child: Scaffold(
              body: SeriesListPage(
                onCreateTap: () => createTapped = true,
                repository: FakeSeriesRepository(
                  (_) async => testSeries(),
                  fetchAllResult: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final createButton = find.widgetWithText(FilledButton, 'Yeni Dizi');
      expect(tester.widget<FilledButton>(createButton).onPressed, isNull);

      await tester.tap(createButton, warnIfMissed: false);
      await tester.pump();

      expect(createTapped, isFalse);
    });

    testWidgets('context error disables series detail lifecycle actions', (
      tester,
    ) async {
      final mutationRepository = FakeSeriesMutationRepository();
      final repository = FakeSeriesRepository(
        (_) async => testSeries(contentVersion: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: const AdminContextLoadResult.error('context failed'),
            child: SeriesDetailPage(
              seriesId: testSeriesId,
              seriesRepository: repository,
              mutationRepository: mutationRepository,
              categoryRepository: FakeCategoryRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      final publishButton = find.widgetWithText(FilledButton, 'Yayınla');
      if (publishButton.evaluate().isNotEmpty) {
        expect(tester.widget<FilledButton>(publishButton).onPressed, isNull);
      }

      await tester.tap(publishButton, warnIfMissed: false);
      await tester.pump();

      expect(mutationRepository.publishCalls, 0);
    });

    testWidgets('context loading blocks episode lifecycle mutation', (
      tester,
    ) async {
      final repository = FakeEpisodeRepository([
        testEpisode(
          streamUid: 'stream-1',
          streamStatus: CloudflareStreamStatus.ready,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminContextScope(
            contextResult: const AdminContextLoadResult.loading(),
            child: SeriesEpisodesPage(
              seriesId: testSeriesId,
              seriesTitle: 'Test',
              episodeRepository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final createButton = find.widgetWithText(FilledButton, 'Yeni Bölüm');
      expect(tester.widget<FilledButton>(createButton).onPressed, isNull);
    });

    testWidgets('non-admin user never sees admin home content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminAuthorizationGate(
            userId: '33333333-3333-3333-3333-333333333333',
            email: 'user@example.com',
            adminCheckOverride: () async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Erişim reddedildi'), findsOneWidget);
      expect(find.text('VIDXON ADMIN'), findsNothing);
      expect(find.text('Diziler'), findsNothing);
    });
  });
}
