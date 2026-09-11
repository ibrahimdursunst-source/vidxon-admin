import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/data/campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_campaign.dart';
import 'package:vidxon_admin/features/campaigns/presentation/popup_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/campaigns/presentation/popup_campaigns_tab.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';

import '../../content/content_test_helpers.dart';

const _testUserId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

AdminUserSummary _testUser() {
  return AdminUserSummary.fromMap({
    'user_id': _testUserId,
    'email': 'qa@vidxon.test',
    'display_name': 'QA User',
    'account_status': 'active',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': null,
    'wallet_actions_allowed': true,
  });
}

class _FakeUsers extends AdminUserWalletRepository {
  _FakeUsers(this.users) : super(client: null);

  final List<AdminUserSummary> users;
  String? lastQuery;

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    lastQuery = query;
    final needle = query.trim().toLowerCase();
    return users
        .where(
          (user) =>
              user.userId.contains(needle) ||
              (user.email ?? '').toLowerCase().contains(needle) ||
              (user.displayName ?? '').toLowerCase().contains(needle),
        )
        .toList();
  }
}

class _FakeCampaigns extends CampaignRepository {
  _FakeCampaigns({this.campaigns = const []}) : super(client: null);

  final List<AdminCampaign> campaigns;
  int upsertCalls = 0;
  bool? lastTestOnly;
  String? lastTestUserId;
  bool? lastIsActive;
  String? lastDestinationType;

  @override
  Future<List<AdminCampaign>> fetchAll() async => campaigns;

  @override
  Future<AdminCampaign> upsert({
    String? id,
    String imagePath = '',
    String destinationType = 'none',
    String? destinationSeriesId,
    String? destinationEpisodeId,
    List<String> targetLocales = const [],
    bool isActive = false,
    int priority = 0,
    required DateTime startsAt,
    DateTime? endsAt,
    required List<AdminCampaignTranslation> translations,
    bool testOnly = false,
    String? testUserId,
  }) async {
    upsertCalls += 1;
    lastTestOnly = testOnly;
    lastTestUserId = testUserId;
    lastIsActive = isActive;
    lastDestinationType = destinationType;
    return AdminCampaign(
      id: id ?? 'camp-1',
      imagePath: imagePath,
      destinationType: destinationType,
      destinationSeriesId: destinationSeriesId,
      destinationEpisodeId: destinationEpisodeId,
      targetLocales: targetLocales,
      isActive: isActive,
      priority: priority,
      startsAt: startsAt,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      translations: translations,
      testOnly: testOnly,
      testUserId: testUserId,
    );
  }
}

AdminCampaign _campaign({
  required String id,
  required String title,
  bool testOnly = false,
  String? testUserId,
  bool isActive = false,
}) {
  return AdminCampaign(
    id: id,
    imagePath: '',
    destinationType: 'none',
    targetLocales: const ['tr'],
    isActive: isActive,
    priority: 0,
    startsAt: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    translations: [
      AdminCampaignTranslation(locale: 'tr', title: title, description: ''),
    ],
    testOnly: testOnly,
    testUserId: testUserId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  Future<void> pumpForm(
    WidgetTester tester, {
    required _FakeCampaigns repo,
    required _FakeUsers users,
    AdminCampaign? existing,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PopupCampaignFormDialog(
            repository: repo,
            existing: existing,
            userRepository: users,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredTitle(WidgetTester tester) async {
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Başlık (tr) *',
      ),
      'Kampanya',
    );
  }

  testWidgets('test-only cannot save without a selected user', (tester) async {
    final repo = _FakeCampaigns();
    await pumpForm(tester, repo: repo, users: _FakeUsers([_testUser()]));

    await tester.ensureVisible(find.byKey(const Key('campaign-test-only-toggle')));
    await tester.tap(find.byKey(const Key('campaign-test-only-toggle')));
    await tester.pumpAndSettle();

    await fillRequiredTitle(tester);
    await tester.ensureVisible(find.text('Oluştur'));
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Test kampanyası için bir kullanıcı seçilmelidir.'), findsOneWidget);
    expect(repo.upsertCalls, 0);
  });

  testWidgets('selected test user persists to the upsert payload', (tester) async {
    final repo = _FakeCampaigns();
    final users = _FakeUsers([_testUser()]);
    await pumpForm(tester, repo: repo, users: users);

    await tester.ensureVisible(find.byKey(const Key('campaign-test-only-toggle')));
    await tester.tap(find.byKey(const Key('campaign-test-only-toggle')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campaign-test-user-search')),
      'qa@vidxon.test',
    );
    await tester.tap(find.byKey(const Key('campaign-test-user-search-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('QA User'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campaign-test-user-selected')), findsOneWidget);

    await fillRequiredTitle(tester);
    await tester.ensureVisible(find.text('Oluştur'));
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(repo.upsertCalls, 1);
    expect(repo.lastTestOnly, isTrue);
    expect(repo.lastTestUserId, _testUserId);
    expect(repo.lastIsActive, isFalse);
    expect(users.lastQuery, 'qa@vidxon.test');
  });

  testWidgets('disabling test-only clears the test user before save', (
    tester,
  ) async {
    final repo = _FakeCampaigns();
    await pumpForm(
      tester,
      repo: repo,
      users: _FakeUsers([_testUser()]),
      existing: _campaign(
        id: 'camp-edit',
        title: 'Eski',
        testOnly: true,
        testUserId: _testUserId,
      ),
    );

    expect(find.byKey(const Key('campaign-test-user-selected')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('campaign-test-only-toggle')));
    await tester.tap(find.byKey(const Key('campaign-test-only-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campaign-test-user-search')), findsNothing);

    await tester.ensureVisible(find.text('Güncelle'));
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    expect(repo.upsertCalls, 1);
    expect(repo.lastTestOnly, isFalse);
    expect(repo.lastTestUserId, isNull);
  });

  testWidgets('normal campaign form still defaults to inactive broadcast', (
    tester,
  ) async {
    final repo = _FakeCampaigns();
    await pumpForm(tester, repo: repo, users: _FakeUsers([_testUser()]));

    expect(find.byKey(const Key('campaign-test-user-search')), findsNothing);
    await fillRequiredTitle(tester);
    await tester.ensureVisible(find.text('Oluştur'));
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(repo.upsertCalls, 1);
    expect(repo.lastTestOnly, isFalse);
    expect(repo.lastTestUserId, isNull);
    expect(repo.lastIsActive, isFalse);
    expect(repo.lastDestinationType, 'none');
  });

  testWidgets('list marks test-only campaigns', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PopupCampaignsTab(
            repository: _FakeCampaigns(
              campaigns: [
                _campaign(id: 'normal', title: 'Normal'),
                _campaign(
                  id: 'qa',
                  title: 'QA Popup',
                  testOnly: true,
                  testUserId: _testUserId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campaign-test-only-badge-qa')), findsOneWidget);
    expect(find.byKey(const Key('campaign-test-only-badge-normal')), findsNothing);
    expect(find.text('TEST'), findsOneWidget);
    expect(find.text('QA Popup'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
  });
}
