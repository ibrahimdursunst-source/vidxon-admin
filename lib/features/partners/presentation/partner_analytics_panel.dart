import 'package:flutter/material.dart';

import '../data/partner_errors.dart';
import '../data/partner_repository.dart';
import '../domain/partner_analytics_report.dart';
import '../domain/partner_metric_copy.dart';
import '../domain/partner_status.dart';
import '../../users/domain/user_parse_helpers.dart';

class PartnerAnalyticsPanel extends StatefulWidget {
  const PartnerAnalyticsPanel({
    required this.partnerId,
    required this.seriesId,
    this.repository,
    super.key,
  });

  final String partnerId;
  final String seriesId;
  final PartnerRepository? repository;

  @override
  State<PartnerAnalyticsPanel> createState() => _PartnerAnalyticsPanelState();
}

class _PartnerAnalyticsPanelState extends State<PartnerAnalyticsPanel> {
  late final PartnerRepository _repository =
      widget.repository ?? PartnerRepository();

  PartnerAnalyticsPreset _preset = PartnerAnalyticsPreset.last7Days;
  DateTime? _customStart;
  DateTime? _customEnd;

  PartnerAnalyticsReport? _report;
  String? _errorMessage;
  String? _pageErrorMessage;
  bool _isLoading = false;
  bool _isLoadingMoreEpisodes = false;
  int _loadGeneration = 0;
  static const _episodePageSize = 500;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PartnerAnalyticsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnerId != widget.partnerId ||
        oldWidget.seriesId != widget.seriesId) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _isLoadingMoreEpisodes = false;
      _errorMessage = null;
      _pageErrorMessage = null;
      _report = null;
    });

    try {
      final report = await _repository.fetchSeriesAnalytics(
        partnerId: widget.partnerId,
        seriesId: widget.seriesId,
        preset: _preset,
        customStart: _customStart,
        customEnd: _customEnd,
        episodeLimit: _episodePageSize,
        episodeOffset: 0,
      );

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _report = report;
        _isLoading = false;
        _errorMessage = null;
        _pageErrorMessage = null;
      });
    } on PartnerException catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _report = null;
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _report = null;
        _errorMessage = 'Analitik raporu yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEpisodes() async {
    final report = _report;
    if (report == null ||
        _isLoading ||
        _isLoadingMoreEpisodes ||
        !report.hasMoreEpisodes) {
      return;
    }
    final generation = _loadGeneration;
    setState(() {
      _isLoadingMoreEpisodes = true;
      _pageErrorMessage = null;
    });
    try {
      final page = await _repository.fetchSeriesAnalytics(
        partnerId: widget.partnerId,
        seriesId: widget.seriesId,
        preset: _preset,
        customStart: _customStart,
        customEnd: _customEnd,
        asOf: report.asOf,
        episodeLimit: _episodePageSize,
        episodeOffset: report.episodes.length,
      );
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      if (page.asOf.toUtc() != report.asOf.toUtc() ||
          page.reportStart.toUtc() != report.reportStart.toUtc() ||
          page.reportEnd.toUtc() != report.reportEnd.toUtc() ||
          page.metricVersion != report.metricVersion) {
        setState(() {
          _isLoadingMoreEpisodes = false;
          _pageErrorMessage = 'Sayfa anlık görüntüsü uyuşmuyor. Yenileyin.';
        });
        return;
      }
      setState(() {
        _report = report.mergeEpisodePage(page);
        _isLoadingMoreEpisodes = false;
      });
    } on PartnerException catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _isLoadingMoreEpisodes = false;
        _pageErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _isLoadingMoreEpisodes = false;
        _pageErrorMessage = 'Bölüm sayfası yüklenemedi.';
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now().toUtc();
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart?.toLocal() ?? now.toLocal(),
      firstDate: DateTime(2020),
      lastDate: now.toLocal().add(const Duration(days: 1)),
      helpText: 'Başlangıç tarihi (UTC günü)',
    );
    if (!mounted || start == null) {
      return;
    }

    final end = await showDatePicker(
      context: context,
      initialDate: _customEnd?.toLocal() ?? start,
      firstDate: start,
      lastDate: now.toLocal().add(const Duration(days: 1)),
      helpText: 'Bitiş tarihi (hariç, UTC)',
    );
    if (!mounted || end == null) {
      return;
    }

    setState(() {
      _preset = PartnerAnalyticsPreset.custom;
      _customStart = DateTime.utc(start.year, start.month, start.day);
      _customEnd = DateTime.utc(end.year, end.month, end.day);
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dizi Analitiği',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Salt okunur · UTC dönem · Kazanç/ödeme yok',
              style: TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in PartnerAnalyticsPreset.values)
                  ChoiceChip(
                    label: Text(preset.label),
                    selected: _preset == preset,
                    onSelected: _isLoading
                        ? null
                        : (_) async {
                            if (preset.requiresCustomDates) {
                              await _pickCustomRange();
                              return;
                            }
                            setState(() {
                              _preset = preset;
                              _customStart = null;
                              _customEnd = null;
                            });
                            await _load();
                          },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _UnavailableBanner(
                message: _errorMessage!,
                onRetry: _load,
              )
            else if (_report != null)
              _ReportBody(
                report: _report!,
                pageErrorMessage: _pageErrorMessage,
                isLoadingMoreEpisodes: _isLoadingMoreEpisodes,
                onLoadMoreEpisodes: _loadMoreEpisodes,
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapor kullanılamıyor',
            style: TextStyle(
              color: Color(0xFFFFB4B4),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFFFFB4B4))),
          const SizedBox(height: 8),
          const Text(
            'Hata durumu sıfır aktivite olarak gösterilmez.',
            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.pageErrorMessage,
    required this.isLoadingMoreEpisodes,
    required this.onLoadMoreEpisodes,
  });

  final PartnerAnalyticsReport report;
  final String? pageErrorMessage;
  final bool isLoadingMoreEpisodes;
  final VoidCallback onLoadMoreEpisodes;

  @override
  Widget build(BuildContext context) {
    final integrity = report.dataIntegrityStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (integrity != null &&
            integrity != PartnerDataIntegrityStatus.healthy) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: integrity == PartnerDataIntegrityStatus.unavailable
                  ? const Color(0xFFE50914).withValues(alpha: 0.12)
                  : const Color(0xFFFFA000).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: integrity == PartnerDataIntegrityStatus.unavailable
                    ? const Color(0xFFE50914).withValues(alpha: 0.45)
                    : const Color(0xFFFFA000).withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              integrity == PartnerDataIntegrityStatus.unavailable
                  ? 'Veri bütünlüğü: Kullanılamıyor. Metrikler güvenilir sonuç '
                      'olarak gösterilmiyor.'
                  : 'Veri bütünlüğü: ${integrity.label}. Bu rapordaki sayılar '
                      'şimdilik yetkili finansal sonuç olarak sunulmaz; Analitik '
                      'Sağlık kontrolünü inceleyin.',
              style: const TextStyle(color: Color(0xFFFFE0B2)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Dönem: ${formatUserDateTime(report.reportStart)} → '
          '${formatUserDateTime(report.reportEnd)} · '
          'as_of ${formatUserDateTime(report.asOf)} · '
          '${report.metricVersion}',
          style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (integrity == PartnerDataIntegrityStatus.unavailable)
          const Text(
            'Rapor şu an güvenilir sayısal sonuç üretmiyor.',
            style: TextStyle(color: Color(0xFFBDBDBD)),
          )
        else
          Opacity(
            opacity: integrity == PartnerDataIntegrityStatus.warning ? 0.55 : 1,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  title: PartnerMetricCopy.qualifiedViewsTitle,
                  value: integrity == PartnerDataIntegrityStatus.warning
                      ? '—'
                      : '${report.qualifiedViews}',
                  help: PartnerMetricCopy.qualifiedViewsHelp,
                ),
                _MetricCard(
                  title: PartnerMetricCopy.uniqueViewersTitle,
                  value: integrity == PartnerDataIntegrityStatus.warning
                      ? '—'
                      : '${report.uniqueViewers}',
                  help: PartnerMetricCopy.uniqueViewersHelp,
                ),
                _MetricCard(
                  title: PartnerMetricCopy.watchTimeTitle,
                  value: integrity == PartnerDataIntegrityStatus.warning
                      ? '—'
                      : PartnerMetricCopy.formatWatchSeconds(
                          report.validatedWatchSeconds,
                        ),
                  help: PartnerMetricCopy.watchTimeHelp,
                ),
                _MetricCard(
                  title: PartnerMetricCopy.completionRateTitle,
                  value: integrity == PartnerDataIntegrityStatus.warning
                      ? '—'
                      : PartnerMetricCopy.formatCompletionRate(
                          report.completionRate,
                        ),
                  help: PartnerMetricCopy.completionRateHelp,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Bölüm Dağılımı',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (integrity == PartnerDataIntegrityStatus.unavailable ||
            integrity == PartnerDataIntegrityStatus.warning)
          const Text(
            'Bölüm dağılımı, bütünlük uyarısı nedeniyle yetkili sonuç olarak gösterilmiyor.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          )
        else if (report.episodes.isEmpty)
          const Text(
            'Bu dönemde bölüme ait kayıt yok.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          )
        else ...[
          for (final episode in report.episodes) ...[
            _EpisodeRow(episode: episode),
            const SizedBox(height: 8),
          ],
          if (report.hasMoreEpisodes) ...[
            if (pageErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  pageErrorMessage!,
                  style: const TextStyle(color: Color(0xFFB3B3B3)),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: isLoadingMoreEpisodes
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: onLoadMoreEpisodes,
                      child: const Text('Daha fazla bölüm yükle'),
                    ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.help,
  });

  final String title;
  final String value;
  final String help;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                  ),
                ),
              ),
              Tooltip(
                message: help,
                child: const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode});

  final PartnerEpisodeAnalyticsRow episode;

  @override
  Widget build(BuildContext context) {
    final label = episode.episodeNumber != null
        ? 'Bölüm ${episode.episodeNumber}${episode.title != null ? ' · ${episode.title}' : ''}'
        : (episode.title ?? episode.episodeId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'NI ${episode.qualifiedViews} · TI ${episode.uniqueViewers} · '
            '${PartnerMetricCopy.formatWatchSeconds(episode.validatedWatchSeconds)} · '
            'TO ${PartnerMetricCopy.formatCompletionRate(episode.completionRate)}',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
