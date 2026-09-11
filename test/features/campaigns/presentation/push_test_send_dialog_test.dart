import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/data/push_campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_push_campaign.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_campaigns_tab.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_test_send_dialog.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/l10n/generated/app_localizations.dart';

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

AdminPushCampaign _campaign({String status = 'draft'}) {
  return AdminPushCampaign(
    id: 'push-1',
    status: status,
    destinationType: 'none',
    targetLocales: const ['tr'],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    translations: const [
      AdminPushTranslation(locale: 'tr', title: 'Promo', body: 'Body'),
    ],
  );
}

class _FakeUsers extends AdminUserWalletRepository {
  _FakeUsers(this.users) : super(client: null);

  final List<AdminUserSummary> users;

  @override
  Future<List<AdminUserSummary>> searchUsers({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    return users;
  }
}

class _FakePushRepo extends PushCampaignRepository {
  _FakePushRepo({
    this.campaigns = const [],
    this.readiness,
    this.localeReadiness,
  }) : super(client: null);

  final List<AdminPushCampaign> campaigns;
  PushUserReadiness? readiness;
  PushUserReadiness? localeReadiness;
  final List<String> readinessLocales = [];
  int sendNowCalls = 0;
  int testSendCalls = 0;
  String? lastTestUserId;

  @override
  Future<List<AdminPushCampaign>> fetchAll() async => campaigns;

  @override
  Future<void> sendNow(String campaignId) async {
    sendNowCalls += 1;
  }

  @override
  Future<void> testSend({
    required String campaignId,
    required String testUserId,
  }) async {
    testSendCalls += 1;
    lastTestUserId = testUserId;
  }

  @override
  Future<PushUserReadiness> fetchUserReadiness({
    required String userId,
    String? locale,
  }) async {
    readinessLocales.add(locale ?? '');
    if (locale != null && locale.isNotEmpty) {
      return localeReadiness ??
          readiness ??
          PushUserReadiness(
            userId: userId,
            eligibleDeviceCount: 0,
            androidCount: 0,
            iosCount: 0,
          );
    }
    return readiness ??
        PushUserReadiness(
          userId: userId,
          eligibleDeviceCount: 0,
          androidCount: 0,
          iosCount: 0,
        );
  }
}

Widget _app(Widget child, {Locale locale = const Locale('tr')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('tr'), Locale('en')],
    localeResolutionCallback: (proposed, supported) => locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

Future<void> _selectQaUser(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('campaign-test-user-search')),
    'qa@vidxon.test',
  );
  await tester.tap(find.byKey(const Key('campaign-test-user-search-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('QA User'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  test('safe readiness payload rejects raw tokens and secrets', () {
    expect(
      () => PushCampaignRepository.assertSafeReadinessPayload({
        'ok': true,
        'fcm_token': 'secret-token-a-android-tr',
      }),
      throwsA(isA<PushCampaignException>()),
    );
    expect(
      () => PushCampaignRepository.assertSafeReadinessPayload({
        'ok': true,
        'user_id': _testUserId,
        'eligible_device_count': 1,
        'android_count': 1,
        'ios_count': 0,
      }),
      returnsNormally,
    );
  });

  testWidgets('Test Gönder and Şimdi Gönder are separate actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign()]);
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campaign-push-test-send')), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-send-now')), findsOneWidget);
    expect(find.byTooltip('Test Gönder'), findsOneWidget);
    expect(find.byTooltip('Şimdi Gönder'), findsOneWidget);
  });

  testWidgets('scheduled campaign has Send Now but not Test Send', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign(status: 'scheduled')]);
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campaign-push-test-send')), findsNothing);
    expect(find.byKey(const Key('campaign-push-send-now')), findsOneWidget);
  });

  testWidgets('Send Now stays broadcast and does not call testSend', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign()]);
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('campaign-push-send-now')));
    await tester.tap(find.byKey(const Key('campaign-push-send-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campaign-push-send-now-confirm')));
    await tester.pumpAndSettle();

    expect(repo.sendNowCalls, 1);
    expect(repo.testSendCalls, 0);
  });

  testWidgets('zero eligible devices disables test send confirm', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(
      readiness: const PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 0,
        androidCount: 0,
        iosCount: 0,
      ),
    );
    await tester.pumpWidget(
      _app(
        PushTestSendDialog(
          campaign: _campaign(),
          repository: repo,
          userRepository: _FakeUsers([_testUser()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _selectQaUser(tester);

    expect(find.byKey(const Key('push-readiness-eligible-count')), findsOneWidget);
    expect(find.byKey(const Key('push-readiness-blocked')), findsOneWidget);
    expect(find.textContaining('fcm'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('push-test-send-confirm')),
    );
    expect(confirm.onPressed, isNull);
    expect(repo.testSendCalls, 0);
  });

  testWidgets('locale mismatch warns and blocks confirm', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(
      readiness: const PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 1,
        androidCount: 1,
        iosCount: 0,
      ),
      localeReadiness: const PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 0,
        androidCount: 0,
        iosCount: 0,
      ),
    );
    await tester.pumpWidget(
      _app(
        PushTestSendDialog(
          campaign: _campaign(),
          repository: repo,
          userRepository: _FakeUsers([_testUser()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _selectQaUser(tester);

    expect(find.byKey(const Key('push-readiness-blocked')), findsOneWidget);
    expect(
      find.text(
        'Kullanıcının uygun cihaz dilleri bu kampanyanın hedef dilleriyle eşleşmiyor.',
      ),
      findsOneWidget,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('push-test-send-confirm')),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('eligible android device enables isolated test send', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(
      readiness: PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 1,
        androidCount: 1,
        iosCount: 0,
        latestLastSeenAt: DateTime.utc(2026, 9, 11),
      ),
    );
    await tester.pumpWidget(
      _app(
        PushTestSendDialog(
          campaign: _campaign(),
          repository: repo,
          userRepository: _FakeUsers([_testUser()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _selectQaUser(tester);

    expect(find.byKey(const Key('push-test-send-campaign-title')), findsOneWidget);
    expect(find.text('Promo'), findsWidgets);
    expect(find.byKey(const Key('push-test-send-campaign-locales')), findsOneWidget);
    expect(find.byKey(const Key('push-readiness-android')), findsOneWidget);
    expect(find.textContaining('fcm_token'), findsNothing);
    await tester.tap(find.byKey(const Key('push-test-send-confirm')));
    await tester.pumpAndSettle();
    expect(repo.testSendCalls, 1);
    expect(repo.lastTestUserId, _testUserId);
    expect(repo.sendNowCalls, 0);
  });

  testWidgets('English copy uses Send Test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign()]);
    await tester.pumpWidget(
      _app(PushCampaignsTab(repository: repo), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send Test'), findsOneWidget);
    expect(find.byTooltip('Send Now'), findsOneWidget);
  });
}
