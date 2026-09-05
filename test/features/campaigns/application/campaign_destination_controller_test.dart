import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/campaigns/application/campaign_destination_controller.dart';
import 'package:vidxon_admin/features/campaigns/domain/campaign_destination.dart';
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
  const seriesA = 'series-a';
  const seriesB = 'series-b';
  const episodeA1 = 'episode-a1';
  const episodeB1 = 'episode-b1';

  late List<AdminSeries> series;
  late List<AdminEpisode> episodes;

  setUp(() {
    series = [
      testSeries(id: seriesA, title: 'Kuzey Yıldızı', isPublished: true),
      testSeries(id: seriesB, title: 'Gölge Avı', isPublished: false),
    ];
    episodes = [
      _episode(id: episodeA1, seriesId: seriesA, episodeNumber: 1, title: 'Başlangıç'),
      _episode(id: episodeB1, seriesId: seriesB, episodeNumber: 1, title: 'Giriş'),
    ];
  });

  test('series destination serializes the selected series UUID', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(series),
      episodeRepository: _EpisodeCatalog(episodes),
      destinationType: CampaignDestinationType.series,
    );
    await controller.initialize();
    await controller.selectSeries(series.first);

    expect(controller.seriesIdForSave, seriesA);
    expect(controller.episodeIdForSave, isNull);
    expect(controller.validate(), isNull);
  });

  test('episode destination serializes the selected episode UUID', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(series),
      episodeRepository: _EpisodeCatalog(episodes),
      destinationType: CampaignDestinationType.episode,
    );
    await controller.initialize();
    await controller.selectSeries(series.first);
    controller.selectEpisode(episodes.first);

    expect(controller.seriesIdForSave, isNull);
    expect(controller.episodeIdForSave, episodeA1);
    expect(controller.validate(), isNull);
  });

  test('changing series clears the previous episode selection', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(series),
      episodeRepository: _EpisodeCatalog(episodes),
      destinationType: CampaignDestinationType.episode,
    );
    await controller.initialize();
    await controller.selectSeries(series.first);
    controller.selectEpisode(episodes.first);
    expect(controller.selectedEpisodeId, episodeA1);

    await controller.selectSeries(series.last);
    expect(controller.selectedEpisodeId, isNull);
    expect(controller.episodeIdForSave, isNull);
    expect(controller.episodes.map((item) => item.id), [episodeB1]);
  });

  test('edit mode resolves stored series UUID to the catalog title', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(series),
      episodeRepository: _EpisodeCatalog(episodes),
      destinationType: CampaignDestinationType.series,
      initialSeriesId: seriesA,
    );
    await controller.initialize();

    expect(controller.selectedSeries?.title, 'Kuzey Yıldızı');
    expect(controller.seriesUnavailable, isFalse);
    expect(controller.seriesIdForSave, seriesA);
  });

  test('edit mode resolves stored episode UUID through its parent series', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(series),
      episodeRepository: _EpisodeCatalog(episodes),
      destinationType: CampaignDestinationType.episode,
      initialEpisodeId: episodeA1,
    );
    await controller.initialize();

    expect(controller.selectedSeries?.id, seriesA);
    expect(controller.selectedEpisode?.title, 'Başlangıç');
    expect(controller.episodeIdForSave, episodeA1);
  });

  test('missing series keeps the stored id and does not retarget', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(const [], missingIds: {seriesA}),
      episodeRepository: _EpisodeCatalog(const []),
      destinationType: CampaignDestinationType.series,
      initialSeriesId: seriesA,
    );
    await controller.initialize();

    expect(controller.selectedSeriesId, isNull);
    expect(controller.seriesUnavailable, isTrue);
    expect(controller.seriesIdForSave, seriesA);
    expect(controller.validate(), isNull);
  });

  test('missing episode keeps the stored id and does not retarget', () async {
    final controller = CampaignDestinationController(
      seriesRepository: _SeriesCatalog(series),
      episodeRepository: _EpisodeCatalog(episodes, missingIds: {episodeA1}),
      destinationType: CampaignDestinationType.episode,
      initialEpisodeId: episodeA1,
    );
    await controller.initialize();

    expect(controller.selectedEpisodeId, isNull);
    expect(controller.episodeUnavailable, isTrue);
    expect(controller.episodeIdForSave, episodeA1);
    expect(controller.validate(), isNull);
  });

  test('fixed destinations do not serialize entity ids', () async {
    for (final type in [
      CampaignDestinationType.none,
      CampaignDestinationType.coinPurchase,
      CampaignDestinationType.membership,
    ]) {
      final controller = CampaignDestinationController(
        seriesRepository: _SeriesCatalog(series),
        episodeRepository: _EpisodeCatalog(episodes),
        destinationType: type,
        initialSeriesId: seriesA,
        initialEpisodeId: episodeA1,
      );
      await controller.initialize();
      expect(controller.showSeriesPicker, isFalse);
      expect(controller.showEpisodePicker, isFalse);
      expect(controller.seriesIdForSave, isNull);
      expect(controller.episodeIdForSave, isNull);
    }
  });

  test('priority helper and default match backend higher-wins semantics', () {
    expect(CampaignPriority.defaultValue, 0);
    expect(CampaignPriority.parseOrDefault(''), 0);
    expect(CampaignPriority.parseOrDefault('not-a-number'), 0);
    expect(CampaignPriority.parseOrDefault('12'), 12);
    expect(
      CampaignPriority.helperText,
      contains('daha yüksek öncelikli kampanya önce gösterilir'),
    );
    expect(CampaignDestinationType.all, isNot(contains('url')));
    expect(CampaignDestinationType.all, isNot(contains('home')));
  });
}
