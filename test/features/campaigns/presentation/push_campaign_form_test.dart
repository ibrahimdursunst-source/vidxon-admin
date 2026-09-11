import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/data/push_campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_push_campaign.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/episodes/data/episode_repository.dart';
import 'package:vidxon_admin/features/series/data/series_repository.dart';
import 'package:vidxon_admin/l10n/generated/app_localizations.dart';

import '../../content/content_test_helpers.dart';

class _FakePushRepo extends PushCampaignRepository {
  _FakePushRepo() : super(client: null);

  int upsertCalls = 0;
  int sendNowCalls = 0;
  int testSendCalls = 0;
  String? lastStatus;
  DateTime? lastScheduledAt;

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
    lastStatus = status;
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
  }

  @override
  Future<void> testSend({
    required String campaignId,
    required String testUserId,
  }) async {
    testSendCalls += 1;
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

AdminPushCampaign _existing({String status = 'draft'}) {
  return AdminPushCampaign(
    id: 'push-1',
    status: status,
    destinationType: 'none',
    targetLocales: const ['tr'],
    scheduledAt: status == 'scheduled'
        ? DateTime.utc(2026, 9, 11, 16, 30)
        : null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    translations: const [
      AdminPushTranslation(locale: 'tr', title: 'Promo', body: 'Body'),
    ],
  );
}

Future<void> _fillRequired(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Promo');
  await tester.enterText(fields.at(1), 'Body');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  testWidgets('create uses Kampanyayı Oluştur and never sends', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo();
    await tester.pumpWidget(
      _app(
        PushCampaignFormDialog(
          repository: repo,
          seriesRepository: SeriesRepository(client: null),
          episodeRepository: EpisodeRepository(client: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taslak Kaydet'), findsNothing);
    expect(find.text('Save Draft'), findsNothing);
    expect(find.text('Kampanyayı Oluştur'), findsOneWidget);
    expect(find.byKey(const Key('campaign-push-create')), findsOneWidget);

    await _fillRequired(tester);
    await tester.tap(find.byKey(const Key('campaign-push-create')));
    await tester.pumpAndSettle();

    expect(repo.upsertCalls, 1);
    expect(repo.lastStatus, 'draft');
    expect(repo.lastScheduledAt, isNull);
    expect(repo.sendNowCalls, 0);
    expect(repo.testSendCalls, 0);
  });

  testWidgets('edit uses Save Changes and does not send', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo();
    await tester.pumpWidget(
      _app(
        PushCampaignFormDialog(
          repository: repo,
          existing: _existing(),
          seriesRepository: SeriesRepository(client: null),
          episodeRepository: EpisodeRepository(client: null),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save Draft'), findsNothing);
    expect(find.text('Taslak Kaydet'), findsNothing);
    expect(find.text('Save Changes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('campaign-push-save-changes')));
    await tester.pumpAndSettle();
    expect(repo.upsertCalls, 1);
    expect(repo.lastStatus, 'draft');
    expect(repo.sendNowCalls, 0);
    expect(repo.testSendCalls, 0);
  });

  testWidgets('editing a scheduled campaign keeps scheduled state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakePushRepo();
    await tester.pumpWidget(
      _app(
        PushCampaignFormDialog(
          repository: repo,
          existing: _existing(status: 'scheduled'),
          seriesRepository: SeriesRepository(client: null),
          episodeRepository: EpisodeRepository(client: null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('campaign-push-save-changes')));
    await tester.pumpAndSettle();
    expect(repo.lastStatus, 'scheduled');
    expect(repo.lastScheduledAt, DateTime.utc(2026, 9, 11, 16, 30));
    expect(repo.sendNowCalls, 0);
  });
}
