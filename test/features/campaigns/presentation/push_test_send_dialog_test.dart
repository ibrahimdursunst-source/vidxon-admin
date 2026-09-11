import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/time/admin_local_time.dart';
import 'package:vidxon_admin/features/campaigns/data/push_campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_push_campaign.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_campaigns_tab.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_schedule_dialog.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_test_send_dialog.dart';
import 'package:vidxon_admin/features/users/data/admin_user_wallet_repository.dart';
import 'package:vidxon_admin/features/users/domain/admin_user_summary.dart';
import 'package:vidxon_admin/l10n/generated/app_localizations.dart';

import '../../content/content_test_helpers.dart';

const _testUserId = '03a499ec-638c-4a48-b2b6-32ad49f00fae';

AdminUserSummary _testUser() {
  return AdminUserSummary.fromMap({
    'user_id': _testUserId,
    'email': 'selim@example.com',
    'display_name': 'Selim2',
    'account_status': 'active',
    'coin_balance': 0,
    'account_created_at': '2026-07-27T17:14:20.106837+00:00',
    'admin_role': null,
    'wallet_actions_allowed': true,
  });
}

AdminPushCampaign _campaign({
  String status = 'draft',
  DateTime? scheduledAt,
  DateTime? sentAt,
  DateTime? createdAt,
  int sentCount = 0,
  int failedCount = 0,
  int pendingCount = 0,
}) {
  return AdminPushCampaign(
    id: 'push-1',
    status: status,
    destinationType: 'none',
    targetLocales: const ['tr'],
    scheduledAt: scheduledAt,
    sentAt: sentAt,
    createdAt: createdAt ?? DateTime.utc(2026, 9, 11, 12, 15, 54),
    updatedAt: DateTime.utc(2026, 9, 11, 12, 15, 54),
    translations: const [
      AdminPushTranslation(locale: 'tr', title: 'Promo', body: 'Body'),
    ],
    sentCount: sentCount,
    failedCount: failedCount,
    pendingCount: pendingCount,
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
    this.testSendError,
    this.sendNowError,
    this.testSendGate,
  }) : super(client: null);

  List<AdminPushCampaign> campaigns;
  PushUserReadiness? readiness;
  PushUserReadiness? localeReadiness;
  final Object? testSendError;
  final Object? sendNowError;
  final Completer<void>? testSendGate;
  final List<String> readinessLocales = [];
  int sendNowCalls = 0;
  int testSendCalls = 0;
  int upsertCalls = 0;
  String? lastTestUserId;
  String? lastUpsertStatus;
  DateTime? lastScheduledAt;

  @override
  Future<List<AdminPushCampaign>> fetchAll() async => campaigns;

  @override
  Future<AdminPushCampaign> upsert({
    String? id,
    String status = 'draft',
    String destinationType = 'none',
    String? destinationSeriesId,
    String? destinationEpisodeId,
    List<String> targetLocales = const [],
    DateTime? scheduledAt,
    required List<AdminPushTranslation> translations,
  }) async {
    upsertCalls += 1;
    lastUpsertStatus = status;
    lastScheduledAt = scheduledAt;
    return AdminPushCampaign(
      id: id ?? 'push-1',
      status: status,
      destinationType: destinationType,
      targetLocales: targetLocales,
      scheduledAt: scheduledAt,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      translations: translations,
    );
  }

  @override
  Future<void> sendNow(String campaignId) async {
    sendNowCalls += 1;
    if (sendNowError != null) {
      throw sendNowError!;
    }
  }

  @override
  Future<void> testSend({
    required String campaignId,
    required String testUserId,
  }) async {
    testSendCalls += 1;
    lastTestUserId = testUserId;
    if (testSendGate != null) {
      await testSendGate!.future;
    }
    if (testSendError != null) {
      throw testSendError!;
    }
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

Future<void> _selectUser(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('campaign-test-user-search')),
    'selim@example.com',
  );
  await tester.tap(find.byKey(const Key('campaign-test-user-search-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Selim2'));
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

  testWidgets('specific-user, all-users, and schedule stay separate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign()]);
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Taslak Kaydet'), findsNothing);
    expect(find.text('Save Draft'), findsNothing);
    expect(find.text('Test Gönder'), findsNothing);
    expect(find.text('Şimdi Gönder'), findsNothing);
    expect(find.text('Hazır'), findsOneWidget);
    expect(find.text('İşlemler'), findsOneWidget);
    await tester.tap(find.byKey(const Key('campaign-push-actions')));
    await tester.pumpAndSettle();
    expect(find.text('Belirli Kullanıcıya Gönder'), findsOneWidget);
    expect(find.text('Tüm Kullanıcılara Gönder'), findsOneWidget);
    expect(find.text('Gönderimi Zamanla'), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-test-send')), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-send-now')), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-schedule')), findsOneWidget);
  });

  testWidgets('English labels use the product send actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign()]);
    await tester.pumpWidget(
      _app(PushCampaignsTab(repository: repo), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
    await tester.tap(find.byKey(const Key('campaign-push-actions')));
    await tester.pumpAndSettle();
    expect(find.text('Send to Specific User'), findsOneWidget);
    expect(find.text('Send to All Users'), findsOneWidget);
    expect(find.text('Schedule Send'), findsOneWidget);
  });

  testWidgets('scheduled campaign has all-users and schedule, not specific-user', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign(status: 'scheduled')]);
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Planlanmış'), findsOneWidget);
    await tester.tap(find.byKey(const Key('campaign-push-actions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campaign-push-test-send')), findsNothing);
    expect(find.byKey(const Key('campaign-push-send-now')), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-schedule')), findsOneWidget);
  });

  testWidgets('sent and cancelled states remain localized and not sendable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(
      campaigns: [
        _campaign(status: 'sent'),
        _campaign(status: 'cancelled'),
      ],
    );
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Gönderildi'), findsWidgets);
    expect(find.text('İptal'), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-send-now')), findsNothing);
    expect(find.byKey(const Key('campaign-push-test-send')), findsNothing);
  });

  testWidgets('all-users stays broadcast and does not call testSend', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(campaigns: [_campaign()]);
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('campaign-push-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campaign-push-send-now')));
    await tester.pumpAndSettle();
    expect(find.textContaining('tüm uygun kullanıcılara'), findsWidgets);
    await tester.tap(find.byKey(const Key('campaign-push-send-now-confirm')));
    await tester.pumpAndSettle();

    expect(repo.sendNowCalls, 1);
    expect(repo.testSendCalls, 0);
  });

  testWidgets('list timestamps are local, not raw UTC ISO', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sentAt = DateTime.utc(2026, 9, 11, 12, 15, 54);
    final repo = _FakePushRepo(
      campaigns: [_campaign(status: 'sent', sentAt: sentAt)],
    );
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();

    final formatted = AdminLocalTime.format(sentAt, const Locale('tr'));
    expect(find.byKey(const Key('campaign-plan-or-delivery')), findsOneWidget);
    expect(find.text(formatted), findsOneWidget);
    expect(find.textContaining('2026-09-11T12:15:54'), findsNothing);
    expect(find.textContaining('12:15:54.000Z'), findsNothing);

    final screenshotUtc = AdminLocalTime.tryParseUtc('2026-09-11T16:06:00+00:00')!;
    expect(screenshotUtc.hour, 16);
    expect(
      AdminLocalTime.format(screenshotUtc, const Locale('tr')),
      isNot('11.09.2026 16:06Z'),
    );
  });

  testWidgets('zero eligible devices disables specific-user confirm', (
    tester,
  ) async {
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
    await _selectUser(tester);

    expect(find.byKey(const Key('push-selected-user-name')), findsOneWidget);
    expect(find.text('Selim2'), findsWidgets);
    expect(find.text('selim@example.com'), findsOneWidget);
    expect(find.text(_testUserId), findsOneWidget);
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
    await _selectUser(tester);

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

  testWidgets('eligible android device enables isolated specific-user send', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final lastSeen = DateTime.utc(2026, 9, 11, 12, 15, 54);
    final repo = _FakePushRepo(
      readiness: PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 1,
        androidCount: 1,
        iosCount: 0,
        latestLastSeenAt: lastSeen,
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
    await _selectUser(tester);

    expect(find.text('Selim2'), findsWidgets);
    expect(find.text('selim@example.com'), findsOneWidget);
    expect(find.text(_testUserId), findsOneWidget);
    expect(find.text('Test Gönder'), findsNothing);
    expect(find.byKey(const Key('push-readiness-android')), findsOneWidget);
    expect(
      find.textContaining(AdminLocalTime.format(lastSeen, const Locale('tr'))),
      findsOneWidget,
    );
    expect(find.textContaining('2026-09-11T12:15:54'), findsNothing);
    expect(find.textContaining('fcm_token'), findsNothing);
    await tester.tap(find.byKey(const Key('push-test-send-confirm')));
    await tester.pumpAndSettle();
    expect(repo.testSendCalls, 1);
    expect(repo.lastTestUserId, _testUserId);
    expect(repo.sendNowCalls, 0);
    expect(find.byKey(const Key('push-test-send-error')), findsNothing);
  });

  testWidgets('failed specific-user send shows safe status and summary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const leak =
        'ClientException: Failed to fetch, uri=https://example.supabase.co/functions/v1/send-push-campaign';
    final repo = _FakePushRepo(
      readiness: const PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 1,
        androidCount: 1,
        iosCount: 0,
      ),
      testSendError: PushDeliveryFailure(
        message: leak,
        pendingCount: 1,
        sentCount: 0,
        failedCount: 0,
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
    await _selectUser(tester);
    await tester.tap(find.byKey(const Key('push-test-send-confirm')));
    await tester.pumpAndSettle();

    expect(repo.testSendCalls, 1);
    expect(repo.lastTestUserId, _testUserId);
    expect(repo.sendNowCalls, 0);
    expect(find.text('Bildirim gönderilemedi.'), findsOneWidget);
    expect(find.text('Bekleyen: 1 · Gönderilen: 0 · Başarısız: 0'), findsOneWidget);
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('Failed to fetch'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(find.textContaining('send-push-campaign'), findsNothing);
    expect(find.textContaining('Lütfen tekrar deneyin'), findsNothing);
    expect(find.textContaining('kampanyanın durumunu kontrol edin'), findsNothing);
  });

  testWidgets('failed specific-user English copy stays safe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(
      readiness: const PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 1,
        androidCount: 1,
        iosCount: 0,
      ),
      testSendError: Exception(
        'ClientException: Failed to fetch, uri=https://example.supabase.co/functions/v1/send-push-campaign',
      ),
    );
    await tester.pumpWidget(
      _app(
        PushTestSendDialog(
          campaign: _campaign(),
          repository: repo,
          userRepository: _FakeUsers([_testUser()]),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await _selectUser(tester);
    await tester.tap(find.byKey(const Key('push-test-send-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Notification could not be sent.'), findsOneWidget);
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(find.textContaining('Please try again.'), findsNothing);
  });

  testWidgets('in-flight specific-user confirm cannot double-submit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gate = Completer<void>();
    final repo = _FakePushRepo(
      readiness: const PushUserReadiness(
        userId: _testUserId,
        eligibleDeviceCount: 1,
        androidCount: 1,
        iosCount: 0,
      ),
      testSendGate: gate,
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
    await _selectUser(tester);
    await tester.tap(find.byKey(const Key('push-test-send-confirm')));
    await tester.pump();
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('push-test-send-confirm')),
    );
    expect(confirm.onPressed, isNull);
    await tester.tap(find.byKey(const Key('push-test-send-confirm')));
    await tester.pump();
    expect(repo.testSendCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('failed all-users send shows safe summary, not ClientException', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(2400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo(
      campaigns: [_campaign(pendingCount: 1)],
      sendNowError: PushDeliveryFailure(
        message:
            'ClientException: Failed to fetch, uri=https://example.supabase.co/functions/v1/send-push-campaign',
        pendingCount: 1,
        sentCount: 0,
        failedCount: 0,
      ),
    );
    await tester.pumpWidget(_app(PushCampaignsTab(repository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('campaign-push-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campaign-push-send-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campaign-push-send-now-confirm')));
    await tester.pumpAndSettle();

    expect(repo.sendNowCalls, 1);
    expect(repo.testSendCalls, 0);
    expect(find.text('Bildirim gönderilemedi.'), findsOneWidget);
    expect(find.text('Bekleyen: 1 · Gönderilen: 0 · Başarısız: 0'), findsOneWidget);
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(find.textContaining('send-push-campaign'), findsNothing);
  });

  testWidgets('schedule dialog converts local wall time to UTC once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final existingUtc = DateTime.utc(2026, 9, 11, 16, 30);
    final repo = _FakePushRepo();
    await tester.pumpWidget(
      _app(
        PushScheduleDialog(
          campaign: _campaign(status: 'draft', scheduledAt: existingUtc),
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final preview = AdminLocalTime.format(existingUtc, const Locale('tr'));
    expect(find.text(preview), findsOneWidget);
    expect(find.textContaining('2026-09-11T16:30:00'), findsNothing);
    expect(find.textContaining('16:30:00.000Z'), findsNothing);

    await tester.tap(find.byKey(const Key('push-schedule-confirm')));
    await tester.pumpAndSettle();
    expect(repo.upsertCalls, 1);
    expect(repo.lastUpsertStatus, 'scheduled');
    expect(repo.lastScheduledAt, existingUtc);
    expect(repo.sendNowCalls, 0);
    expect(repo.testSendCalls, 0);
  });
}
