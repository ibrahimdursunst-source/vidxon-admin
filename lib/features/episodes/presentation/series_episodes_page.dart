import 'package:flutter/material.dart';

import '../../content/data/content_errors.dart';
import '../../content/presentation/content_conflict_helper.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../../series/data/series_mutation_repository.dart';
import '../../series/data/series_repository.dart';
import '../../series/domain/admin_series.dart';
import '../data/episode_preview_repository.dart';
import '../data/episode_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/cloudflare_stream_status.dart';
import '../domain/episode_release_at.dart';
import 'episode_form_page.dart';
import 'episode_preview_dialog.dart';
import 'episode_reorder_page.dart';
import 'episode_reorder_result.dart';
import 'episode_video_upload_page.dart';

class SeriesEpisodesPage extends StatefulWidget {
  const SeriesEpisodesPage({
    required this.seriesId,
    required this.seriesTitle,
    this.initialSeries,
    this.episodeRepository,
    this.seriesRepository,
    this.previewRepository,
    this.mutationRepository,
    this.isSeriesArchived = false,
    super.key,
  });

  final String seriesId;
  final String seriesTitle;
  final AdminSeries? initialSeries;
  final EpisodeRepository? episodeRepository;
  final SeriesRepository? seriesRepository;
  final EpisodePreviewRepository? previewRepository;
  final SeriesMutationRepository? mutationRepository;
  final bool isSeriesArchived;

  @override
  State<SeriesEpisodesPage> createState() => _SeriesEpisodesPageState();
}

class _SeriesEpisodesPageState extends State<SeriesEpisodesPage> {
  static const _desktopBreakpoint = 900.0;

  late final EpisodeRepository _repository =
      widget.episodeRepository ?? EpisodeRepository();
  late final SeriesRepository _seriesRepository =
      widget.seriesRepository ?? SeriesRepository();

  late Future<List<AdminEpisode>> _episodesFuture;
  int? _seriesContentVersion;
  bool _lifecycleBusy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSeries;
    if (initial != null) {
      _seriesContentVersion = initial.contentVersion;
    }
    _episodesFuture = _repository.fetchEpisodesForSeries(widget.seriesId);
    _syncSeriesContentVersion();
  }

  Future<void> _syncSeriesContentVersion() async {
    try {
      final series = await _seriesRepository.fetchById(widget.seriesId);
      if (!mounted) {
        return;
      }

      setState(() => _seriesContentVersion = series.contentVersion);
    } catch (_) {
      // Keep the last known version when sync fails.
    }
  }

  Future<void> refresh() async {
    setState(() {
      _episodesFuture = _repository.fetchEpisodesForSeries(widget.seriesId);
    });
    await Future.wait([_episodesFuture, _syncSeriesContentVersion()]);
  }

  Future<void> _openCreateForm() async {
    final result = await Navigator.of(context).push<AdminEpisode>(
      MaterialPageRoute(
        builder: (context) => EpisodeFormPage(seriesId: widget.seriesId),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    refresh();
  }

  Future<void> _openEditForm(AdminEpisode episode) async {
    final result = await Navigator.of(context).push<AdminEpisode>(
      MaterialPageRoute(
        builder: (context) =>
            EpisodeFormPage(seriesId: widget.seriesId, episode: episode),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    refresh();
  }

  Future<void> _openReorder(List<AdminEpisode> episodes) async {
    final active = activeEpisodes(episodes);
    if (active.length < 2) {
      return;
    }

    await _syncSeriesContentVersion();
    if (!mounted) {
      return;
    }

    final version = _seriesContentVersion ?? 0;
    final navigator = Navigator.of(context);
    final result = await navigator.push<EpisodeReorderPageResult>(
      MaterialPageRoute(
        builder: (context) => EpisodeReorderPage(
          seriesId: widget.seriesId,
          episodes: active,
          expectedSeriesVersion: version,
          episodeRepository: _repository,
          seriesRepository: _seriesRepository,
          mutationRepository: widget.mutationRepository,
        ),
      ),
    );

    if (!mounted || result == null) {
      await _syncSeriesContentVersion();
      return;
    }

    if (result is EpisodeReorderSuccess) {
      setState(() => _seriesContentVersion = result.seriesContentVersion);
    }

    await refresh();
  }

  Future<void> _openVideoUpload(
    AdminEpisode episode, {
    required bool replace,
  }) async {
    if (replace &&
        !episode.allowsReplacementRequest &&
        !episode.allowsReplacementRetry) {
      return;
    }
    if (!replace && !episode.allowsInitialVideoUpload) {
      return;
    }

    final result = await Navigator.of(context).push<AdminEpisode>(
      MaterialPageRoute(
        builder: (context) => EpisodeVideoUploadPage(
          episode: episode,
          seriesTitle: widget.seriesTitle,
          isReplacement: replace,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    refresh();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          replace
              ? 'Yeni video yüklendi. Mevcut video yayında kalmaya devam eder; '
                    'hazır olduğunda otomatik devreye alınır.'
              : 'Video yüklendi ve bölüme bağlandı. Cloudflare Stream videoyu '
                    'işlemeye devam ediyor.',
        ),
      ),
    );
  }

  Future<void> _openPreview(
    AdminEpisode episode, {
    required String source,
  }) async {
    await showEpisodePreviewDialog(
      context: context,
      episode: episode,
      videoSource: source,
      repository: widget.previewRepository ?? EpisodePreviewRepository(),
    );
  }

  Future<void> _runLifecycle({
    required AdminEpisode episode,
    required String title,
    required String message,
    required String confirmLabel,
    required Future<AdminEpisode> Function() action,
    required String successMessage,
  }) async {
    if (_lifecycleBusy || !contentMutationsEnabled(context)) {
      return;
    }

    final confirmed = await confirmContentAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _lifecycleBusy = true);

    try {
      await action();
      if (!mounted) {
        return;
      }

      showContentSuccessSnackBar(context, successMessage);
      refresh();
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isConflict) {
        await handleContentConflict<AdminEpisode>(
          context: context,
          error: error,
          reloadFresh: () => _repository.fetchById(episode.id),
          onFreshLoaded: (_) {},
        );
        refresh();
      } else {
        showContentErrorSnackBar(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        showContentErrorSnackBar(context, 'İşlem tamamlanamadı.');
      }
    } finally {
      if (mounted) {
        setState(() => _lifecycleBusy = false);
      }
    }
  }

  Future<void> _handleAction(
    EpisodeMenuAction action,
    AdminEpisode episode,
  ) async {
    switch (action) {
      case EpisodeMenuAction.edit:
        await _openEditForm(episode);
      case EpisodeMenuAction.upload:
        await _openVideoUpload(episode, replace: false);
      case EpisodeMenuAction.replaceVideo:
        final confirmed = await confirmContentAction(
          context,
          title: 'Videoyu Değiştir',
          message:
              'Yeni video hazır olana kadar mevcut video yayında kalmaya devam eder.',
          confirmLabel: 'Devam Et',
        );
        if (confirmed && mounted) {
          await _openVideoUpload(episode, replace: true);
        }
      case EpisodeMenuAction.previewActive:
        await _openPreview(episode, source: 'active');
      case EpisodeMenuAction.previewPending:
        await _openPreview(episode, source: 'pending');
      case EpisodeMenuAction.publish:
        await _runLifecycle(
          episode: episode,
          title: 'Yayınla',
          message: 'Bu bölüm yayına alınsın mı?',
          confirmLabel: 'Yayınla',
          successMessage: 'Bölüm yayınlandı.',
          action: () => _repository.publishEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
      case EpisodeMenuAction.unpublish:
        await _runLifecycle(
          episode: episode,
          title: 'Yayından Kaldır',
          message: 'Bu bölüm yayından kaldırılsın mı?',
          confirmLabel: 'Yayından Kaldır',
          successMessage: 'Bölüm yayından kaldırıldı.',
          action: () => _repository.unpublishEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
      case EpisodeMenuAction.archive:
        await _runLifecycle(
          episode: episode,
          title: 'Arşivle',
          message: 'Bu bölüm arşivlenecek.',
          confirmLabel: 'Arşivle',
          successMessage: 'Bölüm arşivlendi.',
          action: () => _repository.archiveEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
      case EpisodeMenuAction.restore:
        await _runLifecycle(
          episode: episode,
          title: 'Geri Yükle',
          message: 'Bu bölüm arşivden geri yüklensin mi?',
          confirmLabel: 'Geri Yükle',
          successMessage: 'Bölüm geri yüklendi.',
          action: () => _repository.restoreEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(widget.seriesTitle),
      ),
      body: FutureBuilder<List<AdminEpisode>>(
        future: _episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: refresh,
            );
          }

          final allEpisodes = snapshot.data ?? const [];
          final active = activeEpisodes(allEpisodes);
          final archived = archivedEpisodes(allEpisodes);

          return RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(
                    onCreate: contentMutationsEnabled(context)
                        ? _openCreateForm
                        : () {},
                    onRefresh: refresh,
                    onReorder:
                        contentMutationsEnabled(context) && active.length >= 2
                        ? () => _openReorder(allEpisodes)
                        : null,
                    createEnabled: contentMutationsEnabled(context),
                  ),
                  const SizedBox(height: 24),
                  if (allEpisodes.isEmpty)
                    const _EmptyState()
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= _desktopBreakpoint) {
                          return _EpisodesDataTable(
                            episodes: active,
                            onAction: _handleAction,
                            parentSeriesArchived: widget.isSeriesArchived,
                          );
                        }

                        return _EpisodesCardList(
                          episodes: active,
                          onAction: _handleAction,
                          parentSeriesArchived: widget.isSeriesArchived,
                        );
                      },
                    ),
                    if (archived.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Text(
                        'Arşivlenmiş Bölümler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= _desktopBreakpoint) {
                            return _EpisodesDataTable(
                              episodes: archived,
                              onAction: _handleAction,
                              archived: true,
                            );
                          }

                          return _EpisodesCardList(
                            episodes: archived,
                            onAction: _handleAction,
                            archived: true,
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum EpisodeMenuAction {
  edit,
  upload,
  replaceVideo,
  previewActive,
  previewPending,
  publish,
  unpublish,
  archive,
  restore,
}

List<PopupMenuEntry<EpisodeMenuAction>> episodeMenuItems(
  AdminEpisode episode, {
  bool parentSeriesArchived = false,
}) {
  final items = <PopupMenuEntry<EpisodeMenuAction>>[
    const PopupMenuItem(value: EpisodeMenuAction.edit, child: Text('Düzenle')),
  ];

  if (episode.allowsInitialVideoUpload) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.upload,
        child: Text('Video Yükle'),
      ),
    );
  }

  if (episode.allowsReplacementRequest || episode.allowsReplacementRetry) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.replaceVideo,
        child: Text('Videoyu Değiştir'),
      ),
    );
  }

  if (episode.hasActiveVideo &&
      episode.cloudflareStreamStatus == CloudflareStreamStatus.ready) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.previewActive,
        child: Text('Aktif Videoyu Önizle'),
      ),
    );
  }

  if (episode.hasPendingReplacement &&
      episode.cloudflareStreamPendingStatus == CloudflareStreamStatus.ready) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.previewPending,
        child: Text('Bekleyen Videoyu Önizle'),
      ),
    );
  }

  if (!parentSeriesArchived &&
      !episode.isArchived &&
      !episode.isPublished &&
      episode.canPublish) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.publish,
        child: Text('Yayınla'),
      ),
    );
  }

  if (!episode.isArchived && episode.isPublished) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.unpublish,
        child: Text('Yayından Kaldır'),
      ),
    );
  }

  if (!episode.isArchived) {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.archive,
        child: Text('Arşivle'),
      ),
    );
  } else {
    items.add(
      const PopupMenuItem(
        value: EpisodeMenuAction.restore,
        child: Text('Geri Yükle'),
      ),
    );
  }

  return items;
}

/// Returns menu labels for lifecycle and action visibility tests.
List<String> episodeMenuLabels(
  AdminEpisode episode, {
  bool parentSeriesArchived = false,
}) {
  return episodeMenuItems(episode, parentSeriesArchived: parentSeriesArchived)
      .map((entry) {
        if (entry is PopupMenuItem<EpisodeMenuAction>) {
          final child = entry.child;
          if (child is Text) {
            return child.data ?? '';
          }
        }
        return '';
      })
      .where((label) => label.isNotEmpty)
      .toList();
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onCreate,
    required this.onRefresh,
    this.onReorder,
    this.createEnabled = true,
  });

  final VoidCallback onCreate;
  final VoidCallback onRefresh;
  final VoidCallback? onReorder;
  final bool createEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bölümler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seçili dizinin bölümlerini yönetin',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (onReorder != null)
              OutlinedButton.icon(
                onPressed: onReorder,
                icon: const Icon(Icons.swap_vert, size: 18),
                label: const Text('Sıralamayı Düzenle'),
              ),
            FilledButton.icon(
              onPressed: createEnabled ? onCreate : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Yeni Bölüm'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yenile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EpisodesDataTable extends StatelessWidget {
  const _EpisodesDataTable({
    required this.episodes,
    required this.onAction,
    this.archived = false,
    this.parentSeriesArchived = false,
  });

  final List<AdminEpisode> episodes;
  final Future<void> Function(EpisodeMenuAction action, AdminEpisode episode)
  onAction;
  final bool archived;
  final bool parentSeriesArchived;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF181818)),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Başlık')),
              DataColumn(label: Text('Erişim')),
              DataColumn(label: Text('Yayın')),
              DataColumn(label: Text('Video')),
              DataColumn(label: Text('Bekleyen')),
              DataColumn(label: Text('Yayın Tarihi')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: [
              for (final episode in episodes)
                DataRow(
                  cells: [
                    DataCell(Text(episode.episodeNumber.toString())),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(episode.title),
                          if (archived)
                            const Text(
                              'Arşivlenmiş',
                              style: TextStyle(
                                color: Color(0xFFE5A000),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(episode.priceLabel)),
                    DataCell(Text(episode.publishLabel)),
                    DataCell(Text(episode.videoStatusLabel)),
                    DataCell(Text(episode.pendingVideoStatusLabel)),
                    DataCell(Text(formatEpisodeDateTime(episode.releaseAt))),
                    DataCell(
                      PopupMenuButton<EpisodeMenuAction>(
                        tooltip: 'İşlemler',
                        onSelected: (action) => onAction(action, episode),
                        itemBuilder: (context) => episodeMenuItems(
                          episode,
                          parentSeriesArchived: parentSeriesArchived,
                        ),
                        child: const Icon(Icons.more_vert),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodesCardList extends StatelessWidget {
  const _EpisodesCardList({
    required this.episodes,
    required this.onAction,
    this.archived = false,
    this.parentSeriesArchived = false,
  });

  final List<AdminEpisode> episodes;
  final Future<void> Function(EpisodeMenuAction action, AdminEpisode episode)
  onAction;
  final bool archived;
  final bool parentSeriesArchived;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final episode in episodes) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${episode.episodeNumber} · ${episode.title}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<EpisodeMenuAction>(
                        onSelected: (action) => onAction(action, episode),
                        itemBuilder: (context) => episodeMenuItems(
                          episode,
                          parentSeriesArchived: parentSeriesArchived,
                        ),
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: episode.priceLabel),
                      _InfoChip(label: episode.publishLabel),
                      if (archived) const _InfoChip(label: 'Arşivlenmiş'),
                      _InfoChip(label: episode.videoStatusLabel),
                      if (episode.hasPendingReplacement)
                        _InfoChip(label: episode.pendingVideoStatusLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yayın: ${formatEpisodeDateTime(episode.releaseAt)}',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  if (episode.publishBlockReason != null &&
                      !episode.isPublished &&
                      !episode.isArchived)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        episode.publishBlockReason!,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.playlist_play_outlined,
              size: 56,
              color: Color(0xFF555555),
            ),
            SizedBox(height: 16),
            Text('Henüz bölüm yok'),
            SizedBox(height: 8),
            Text(
              'Bu dizi için ilk bölümü oluşturabilirsiniz.',
              style: TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Color(0xFFE50914),
              ),
              const SizedBox(height: 16),
              const Text('Bölümler yüklenemedi'),
              const SizedBox(height: 8),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFFE50914),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
