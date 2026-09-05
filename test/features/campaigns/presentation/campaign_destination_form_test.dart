import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/locale/vidxon_product_locales.dart';
import 'package:vidxon_admin/features/campaigns/data/campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/data/push_campaign_repository.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_campaign.dart';
import 'package:vidxon_admin/features/campaigns/domain/admin_push_campaign.dart';
import 'package:vidxon_admin/features/campaigns/domain/campaign_destination.dart';
import 'package:vidxon_admin/features/campaigns/presentation/popup_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/campaigns/presentation/push_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/episodes/data/episode_repository.dart';
import 'package:vidxon_admin/features/episodes/domain/admin_episode.dart';
import 'package:vidxon_admin/features/series/data/series_repository.dart';
import 'package:vidxon_admin/features/series/domain/admin_series.dart';

import '../../content/content_test_helpers.dart';

class _SeriesCatalog extends SeriesRepository {
  _SeriesCatalog(this.items, {this.missingIds = const {}}) : super(client: null);

  final List<AdminSeries> items;
  final Set<String> missingIds;

  @override
  Future<List<AdminSeries>> fetchAll() async => items;

  @override
  Future<AdminSeries> fetchById(String seriesId) async {
    if (missingIds.contains(seriesId)) {
      throw StateError('Series not found');
    }
    return items.firstWhere(
      (item) => item.id == seriesId,
      orElse: () => throw StateError('Series not found'),
    );
  }
}

class _EpisodeCatalog extends EpisodeRepository {
  _EpisodeCatalog(this.items, {this.missingIds = const {}}) : super(client: null);

  final List<AdminEpisode> items;
  final Set<String> missingIds;

  @override
  Future<List<AdminEpisode>> fetchEpisodesForSeries(String seriesId) async {
    return items.where((item) => item.seriesId == seriesId).toList();
  }

  @override
  Future<AdminEpisode> fetchById(String episodeId) async {
    if (missingIds.contains(episodeId)) {
      throw StateError('Episode not found');
    }
    return items.firstWhere((item) => item.id == episodeId);
  }
}

class _FakeCampaignRepository extends CampaignRepository {
  _FakeCampaignRepository() : super(client: null);

  String? lastDestinationType;
  String? lastSeriesId;
  String? lastEpisodeId;
  int? lastPriority;

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
  }) async {
    lastDestinationType = destinationType;
    lastSeriesId = destinationSeriesId;
    lastEpisodeId = destinationEpisodeId;
    lastPriority = priority;
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
    );
  }
}

class _FakePushRepository extends PushCampaignRepository {
  _FakePushRepository() : super(client: null);

  String? lastSeriesId;
  String? lastEpisodeId;

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
    lastSeriesId = destinationSeriesId;
    lastEpisodeId = destinationEpisodeId;
    return AdminPushCampaign(
      id: id ?? 'push-1',
      status: status,
      destinationType: destinationType,
      destinationSeriesId: destinationSeriesId,
      destinationEpisodeId: destinationEpisodeId,
      targetLocales: targetLocales,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      translations: translations,
    );
  }
}

AdminEpisode _episode({
  required String id,
  required String seriesId,
  int episodeNumber = 1,
  String title = 'Pilot',
}) {
  return AdminEpisode.fromMap({
    'id': id,
    'series_id': seriesId,
    'episode_number': episodeNumber,
    'title': title,
    'synopsis': '',
    'cloudflare_stream_status': 'none',
    'cloudflare_stream_pending_status': 'none',
    'is_free': true,
    'coin_price': 0,
    'is_published': true,
    'is_archived': false,
    'content_version': 0,
    'total_views': 0,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  const seriesA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const seriesB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  const episodeA1 = '11111111-1111-1111-1111-111111111111';
  const episodeB1 = '22222222-2222-2222-2222-222222222222';

  late List<AdminSeries> series;
  late List<AdminEpisode> episodes;

  setUp(() {
    series = [
      testSeries(id: seriesA, title: 'Kuzey Yıldızı', isPublished: true),
      testSeries(id: seriesB, title: 'Gölge Avı', isPublished: true),
    ];
    episodes = [
      _episode(id: episodeA1, seriesId: seriesA, title: 'Başlangıç'),
      _episode(id: episodeB1, seriesId: seriesB, title: 'Giriş'),
    ];
  });

  Future<void> pumpPopup(
    WidgetTester tester, {
    required _FakeCampaignRepository repo,
    AdminCampaign? existing,
    SeriesRepository? seriesRepository,
    EpisodeRepository? episodeRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PopupCampaignFormDialog(
            repository: repo,
            existing: existing,
            seriesRepository: seriesRepository ?? _SeriesCatalog(series),
            episodeRepository: episodeRepository ?? _EpisodeCatalog(episodes),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectDestination(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('campaign-destination-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('series destination shows series picker, not raw UUID input', (
    tester,
  ) async {
    await pumpPopup(tester, repo: _FakeCampaignRepository());
    await selectDestination(tester, 'Dizi');

    expect(find.byKey(const Key('campaign-series-picker')), findsOneWidget);
    expect(find.byKey(const Key('campaign-series-search')), findsOneWidget);
    expect(find.text('Kuzey Yıldızı'), findsWidgets);
    expect(find.text('Dizi ID *'), findsNothing);
    expect(find.text('UUID'), findsNothing);
    expect(find.byKey(const Key('campaign-episode-picker')), findsNothing);
  });

  testWidgets('episode destination shows series then episode pickers', (
    tester,
  ) async {
    await pumpPopup(tester, repo: _FakeCampaignRepository());
    await selectDestination(tester, 'Bölüm');

    expect(find.byKey(const Key('campaign-series-picker')), findsOneWidget);
    expect(find.byKey(const Key('campaign-episode-picker')), findsOneWidget);
    expect(find.text('Bölüm ID *'), findsNothing);
    expect(find.text('UUID'), findsNothing);
    expect(find.text('Önce bir dizi seçin, ardından bölümü seçin.'), findsOneWidget);

    await tester.tap(find.byKey(Key('campaign-series-option-$seriesA')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('Bölüm 1 · Başlangıç'), findsWidgets);

    await tester.tap(find.text('Bölüm 1 · Başlangıç').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('campaign-series-option-$seriesB')));
    await tester.pumpAndSettle();
    expect(find.text('Bölüm 1 · Başlangıç'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('Bölüm 1 · Giriş'), findsWidgets);
  });

  testWidgets('selected series serializes its UUID on save', (tester) async {
    final repo = _FakeCampaignRepository();
    await pumpPopup(tester, repo: repo);
    await selectDestination(tester, 'Dizi');
    await tester.tap(find.byKey(Key('campaign-series-option-$seriesA')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Başlık (tr) *',
      ),
      'Kampanya',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'CTA Butonu (tr) *',
      ),
      'İzle',
    );
    await tester.ensureVisible(find.text('Oluştur'));
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(repo.lastDestinationType, 'series');
    expect(repo.lastSeriesId, seriesA);
    expect(repo.lastEpisodeId, isNull);
  });

  testWidgets('edit form resolves stored series UUID to the title', (tester) async {
    await pumpPopup(
      tester,
      repo: _FakeCampaignRepository(),
      existing: AdminCampaign(
        id: 'camp-edit',
        imagePath: '',
        destinationType: 'series',
        destinationSeriesId: seriesA,
        targetLocales: const ['tr'],
        isActive: false,
        priority: 0,
        startsAt: DateTime.utc(2026, 1, 1),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        translations: const [
          AdminCampaignTranslation(locale: 'tr', title: 'Eski', description: ''),
        ],
      ),
    );

    expect(find.text('Kuzey Yıldızı'), findsWidgets);
    expect(find.text('Yayında'), findsWidgets);
    expect(find.text(seriesA), findsNothing);
  });

  testWidgets('missing series target stays preserved and visible as unavailable', (
    tester,
  ) async {
    final repo = _FakeCampaignRepository();
    await pumpPopup(
      tester,
      repo: repo,
      seriesRepository: _SeriesCatalog(const [], missingIds: {seriesA}),
      existing: AdminCampaign(
        id: 'camp-missing',
        imagePath: '',
        destinationType: 'series',
        destinationSeriesId: seriesA,
        targetLocales: const ['tr'],
        isActive: false,
        priority: 0,
        startsAt: DateTime.utc(2026, 1, 1),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        translations: const [
          AdminCampaignTranslation(
            locale: 'tr',
            title: 'Eski',
            description: '',
            ctaLabel: 'İzle',
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('campaign-series-unavailable')), findsOneWidget);
    expect(find.textContaining('artık kullanılamıyor'), findsOneWidget);

    await tester.ensureVisible(find.text('Güncelle'));
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(repo.lastSeriesId, seriesA);
  });

  testWidgets('missing episode target stays preserved and visible as unavailable', (
    tester,
  ) async {
    final repo = _FakeCampaignRepository();
    await pumpPopup(
      tester,
      repo: repo,
      episodeRepository: _EpisodeCatalog(episodes, missingIds: {episodeA1}),
      existing: AdminCampaign(
        id: 'camp-missing-ep',
        imagePath: '',
        destinationType: 'episode',
        destinationEpisodeId: episodeA1,
        targetLocales: const ['tr'],
        isActive: false,
        priority: 0,
        startsAt: DateTime.utc(2026, 1, 1),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        translations: const [
          AdminCampaignTranslation(
            locale: 'tr',
            title: 'Eski',
            description: '',
            ctaLabel: 'İzle',
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('campaign-episode-unavailable')), findsOneWidget);
    await tester.ensureVisible(find.text('Güncelle'));
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(repo.lastEpisodeId, episodeA1);
  });

  testWidgets('fixed destinations hide entity pickers and id fields', (
    tester,
  ) async {
    await pumpPopup(tester, repo: _FakeCampaignRepository());
    expect(find.byKey(const Key('campaign-series-picker')), findsNothing);
    expect(find.byKey(const Key('campaign-episode-picker')), findsNothing);

    await selectDestination(tester, 'Jeton Satın Al');
    expect(find.byKey(const Key('campaign-series-picker')), findsNothing);
    expect(find.text('Dizi ID *'), findsNothing);
    expect(find.text('UUID'), findsNothing);
    expect(find.textContaining('URL'), findsNothing);

    await selectDestination(tester, 'Üyelik');
    expect(find.byKey(const Key('campaign-series-picker')), findsNothing);
  });

  testWidgets('campaign destinations do not include Home or URL', (tester) async {
    await pumpPopup(tester, repo: _FakeCampaignRepository());
    await tester.tap(find.byKey(const Key('campaign-destination-type')));
    await tester.pumpAndSettle();

    expect(find.text('Bilgilendirme'), findsWidgets);
    expect(find.text('Dizi'), findsWidgets);
    expect(find.text('Bölüm'), findsWidgets);
    expect(find.text('Jeton Satın Al'), findsOneWidget);
    expect(find.text('Üyelik'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('URL'), findsNothing);
    expect(find.text('Ana Sayfa'), findsNothing);
  });

  testWidgets('priority helper and default match backend semantics', (
    tester,
  ) async {
    await pumpPopup(tester, repo: _FakeCampaignRepository());

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('campaign-priority-field')),
    );
    expect(field.controller?.text, '0');
    expect(find.text(CampaignPriority.label), findsOneWidget);
    expect(find.text(CampaignPriority.helperText), findsOneWidget);
  });

  testWidgets('all 14 campaign locales remain available', (tester) async {
    await pumpPopup(tester, repo: _FakeCampaignRepository());
    for (final locale in VidxonProductLocales.all) {
      expect(find.text(VidxonProductLocales.displayName(locale)), findsWidgets);
    }
    expect(VidxonProductLocales.all, hasLength(14));
  });

  testWidgets('push form uses the same pickers and no raw UUID field', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PushCampaignFormDialog(
            repository: _FakePushRepository(),
            seriesRepository: _SeriesCatalog(series),
            episodeRepository: _EpisodeCatalog(episodes),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await selectDestination(tester, 'Dizi');
    expect(find.byKey(const Key('campaign-series-picker')), findsOneWidget);
    expect(find.text('UUID'), findsNothing);
    expect(find.text('Dizi ID *'), findsNothing);
    expect(find.byKey(const Key('campaign-priority-field')), findsNothing);
  });
}
