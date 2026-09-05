import 'package:flutter/foundation.dart';

import '../../episodes/data/episode_repository.dart';
import '../../episodes/domain/admin_episode.dart';
import '../../series/data/series_repository.dart';
import '../../series/domain/admin_series.dart';
import '../domain/campaign_destination.dart';

/// Resolves campaign series/episode targets through existing Admin read repos.
///
/// IDs stay internal. A missing/deleted target keeps the stored identifier
/// and never silently retargets.
class CampaignDestinationController extends ChangeNotifier {
  CampaignDestinationController({
    required this._seriesRepository,
    required this._episodeRepository,
    this._destinationType = CampaignDestinationType.none,
    String? initialSeriesId,
    String? initialEpisodeId,
  }) : _preservedSeriesId = _nonEmpty(initialSeriesId),
       _preservedEpisodeId = _nonEmpty(initialEpisodeId);

  final SeriesRepository _seriesRepository;
  final EpisodeRepository _episodeRepository;

  String _destinationType;
  String? _selectedSeriesId;
  String? _selectedEpisodeId;
  String? _preservedSeriesId;
  String? _preservedEpisodeId;

  List<AdminSeries> _series = const [];
  List<AdminEpisode> _episodes = const [];

  bool _catalogLoaded = false;
  bool loadingSeries = false;
  bool loadingEpisodes = false;
  bool seriesUnavailable = false;
  bool episodeUnavailable = false;
  String? loadError;
  String seriesQuery = '';

  String get destinationType => _destinationType;
  String? get selectedSeriesId => _selectedSeriesId;
  String? get selectedEpisodeId => _selectedEpisodeId;
  List<AdminSeries> get series => _series;
  List<AdminEpisode> get episodes => _episodes;

  bool get showSeriesPicker =>
      CampaignDestinationType.needsSeriesPicker(_destinationType);
  bool get showEpisodePicker =>
      CampaignDestinationType.needsEpisodePicker(_destinationType);

  String? get seriesIdForSave {
    if (_destinationType != CampaignDestinationType.series) return null;
    return _selectedSeriesId ?? _preservedSeriesId;
  }

  String? get episodeIdForSave {
    if (_destinationType != CampaignDestinationType.episode) return null;
    return _selectedEpisodeId ?? _preservedEpisodeId;
  }

  AdminSeries? get selectedSeries {
    final id = _selectedSeriesId;
    return id == null ? null : _findSeries(id);
  }

  AdminEpisode? get selectedEpisode {
    final id = _selectedEpisodeId;
    return id == null ? null : _findEpisode(id);
  }

  List<AdminSeries> get filteredSeries {
    final query = seriesQuery.trim().toLowerCase();
    if (query.isEmpty) return _series;
    return _series.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.slug.toLowerCase().contains(query);
    }).toList();
  }

  String? validate() {
    if (_destinationType == CampaignDestinationType.series &&
        seriesIdForSave == null) {
      return 'Dizi seçin';
    }
    if (_destinationType == CampaignDestinationType.episode &&
        episodeIdForSave == null) {
      return 'Bölüm seçin';
    }
    return null;
  }

  Future<void> initialize() async {
    if (!showSeriesPicker) return;
    await _ensureCatalogLoaded();
    await _resolveInitialTargets();
  }

  Future<void> setDestinationType(String type) async {
    if (_destinationType == type) return;
    _destinationType = type;
    loadError = null;
    notifyListeners();
    if (showSeriesPicker) {
      await _ensureCatalogLoaded();
      if (showEpisodePicker &&
          _selectedSeriesId != null &&
          _episodes.isEmpty) {
        await _loadEpisodesForSelectedSeries();
      }
      if (_selectedSeriesId == null &&
          _selectedEpisodeId == null &&
          (_preservedSeriesId != null || _preservedEpisodeId != null)) {
        await _resolveInitialTargets();
      }
    }
  }

  void setSeriesQuery(String value) {
    seriesQuery = value;
    notifyListeners();
  }

  Future<void> selectSeries(AdminSeries series) async {
    final seriesChanged = _selectedSeriesId != series.id;
    _selectedSeriesId = series.id;
    _preservedSeriesId = null;
    seriesUnavailable = false;
    seriesQuery = '';
    if (showEpisodePicker && seriesChanged) {
      _selectedEpisodeId = null;
      _preservedEpisodeId = null;
      episodeUnavailable = false;
      _episodes = const [];
    }
    notifyListeners();
    if (showEpisodePicker && seriesChanged) {
      await _loadEpisodesForSelectedSeries();
    }
  }

  void selectEpisode(AdminEpisode episode) {
    _selectedEpisodeId = episode.id;
    _preservedEpisodeId = null;
    episodeUnavailable = false;
    notifyListeners();
  }

  Future<void> _ensureCatalogLoaded() async {
    if (_catalogLoaded || loadingSeries) return;
    loadingSeries = true;
    loadError = null;
    notifyListeners();
    try {
      _series = await _seriesRepository.fetchAll();
      _catalogLoaded = true;
    } catch (_) {
      loadError = 'Diziler yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      loadingSeries = false;
      notifyListeners();
    }
  }

  Future<void> _resolveInitialTargets() async {
    if (_destinationType == CampaignDestinationType.series) {
      await _resolveSeries(_preservedSeriesId);
      return;
    }
    if (_destinationType == CampaignDestinationType.episode) {
      await _resolveEpisode(_preservedEpisodeId);
    }
  }

  Future<void> _resolveSeries(String? seriesId) async {
    if (seriesId == null) return;
    final inCatalog = _findSeries(seriesId);
    if (inCatalog != null) {
      _selectedSeriesId = inCatalog.id;
      _preservedSeriesId = null;
      seriesUnavailable = false;
      notifyListeners();
      return;
    }
    try {
      final fetched = await _seriesRepository.fetchById(seriesId);
      _series = [fetched, ..._series.where((item) => item.id != fetched.id)];
      _selectedSeriesId = fetched.id;
      _preservedSeriesId = null;
      seriesUnavailable = false;
    } catch (_) {
      _selectedSeriesId = null;
      _preservedSeriesId = seriesId;
      seriesUnavailable = true;
    }
    notifyListeners();
  }

  Future<void> _resolveEpisode(String? episodeId) async {
    if (episodeId == null) return;
    try {
      final fetched = await _episodeRepository.fetchById(episodeId);
      await _resolveSeries(fetched.seriesId);
      if (_selectedSeriesId == null) {
        _episodes = [fetched];
        _selectedEpisodeId = fetched.id;
        _preservedEpisodeId = null;
        episodeUnavailable = false;
        notifyListeners();
        return;
      }
      await _loadEpisodesForSelectedSeries();
      final inList = _findEpisode(fetched.id);
      if (inList == null) {
        _episodes = [fetched, ..._episodes];
      }
      _selectedEpisodeId = fetched.id;
      _preservedEpisodeId = null;
      episodeUnavailable = false;
    } catch (_) {
      _selectedEpisodeId = null;
      _preservedEpisodeId = episodeId;
      episodeUnavailable = true;
      if (_preservedSeriesId != null && _selectedSeriesId == null) {
        await _resolveSeries(_preservedSeriesId);
      }
    }
    notifyListeners();
  }

  Future<void> _loadEpisodesForSelectedSeries() async {
    final seriesId = _selectedSeriesId;
    if (seriesId == null) {
      _episodes = const [];
      notifyListeners();
      return;
    }
    loadingEpisodes = true;
    notifyListeners();
    try {
      _episodes = await _episodeRepository.fetchEpisodesForSeries(seriesId);
    } catch (_) {
      loadError = 'Bölümler yüklenemedi. Lütfen tekrar deneyin.';
      _episodes = const [];
    } finally {
      loadingEpisodes = false;
      notifyListeners();
    }
  }

  AdminSeries? _findSeries(String id) {
    for (final item in _series) {
      if (item.id == id) return item;
    }
    return null;
  }

  AdminEpisode? _findEpisode(String id) {
    for (final item in _episodes) {
      if (item.id == id) return item;
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
