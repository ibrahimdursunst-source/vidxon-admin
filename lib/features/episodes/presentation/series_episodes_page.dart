import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../../content/data/content_errors.dart';
import '../../content/presentation/content_conflict_helper.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../../content_rating/presentation/synopsis_preview.dart';
import '../../series/data/series_mutation_repository.dart';
import '../../series/domain/admin_series.dart';
import '../data/episode_preview_repository.dart';
import '../data/episode_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/cloudflare_stream_status.dart';
import '../domain/episode_release_at.dart';
import 'episode_form_page.dart';
import 'episode_media_tracks_page.dart';
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
    this.previewRepository,
    this.mutationRepository,
    this.isSeriesArchived = false,
    super.key,
  });

  final String seriesId;
  final String seriesTitle;
  final AdminSeries? initialSeries;
  final EpisodeRepository? episodeRepository;
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

  late Future<List<AdminEpisode>> _episodesFuture;
  bool _lifecycleBusy = false;
  bool _reorderNavigationOpen = false;

  @override
  void initState() {
    super.initState();
    _episodesFuture = _repository.fetchEpisodesForSeries(widget.seriesId);
  }

  Future<void> refresh() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _episodesFuture = _repository.fetchEpisodesForSeries(widget.seriesId);
    });
    await _episodesFuture;
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

  Future<void> _openReorder() async {
    if (_reorderNavigationOpen) {
      return;
    }

    _reorderNavigationOpen = true;
    try {
      final snapshot = await _repository.loadReorderSnapshot(widget.seriesId);

      if (!mounted) {
        return;
      }

      if (snapshot.activeEpisodes.length < 2) {
        return;
      }

      final navigator = Navigator.of(context);
      final result = await navigator.push<EpisodeReorderPageResult>(
        MaterialPageRoute(
          builder: (context) => EpisodeReorderPage(
            seriesId: widget.seriesId,
            episodes: snapshot.activeEpisodes,
            expectedSeriesVersion: snapshot.contentVersion,
            episodeRepository: _repository,
            mutationRepository: widget.mutationRepository,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result is EpisodeReorderSuccess) {
        await refresh();
        return;
      }
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      _reorderNavigationOpen = false;
    }
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

    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          replace
              ? l10n.videoReplacementUploaded
              : l10n.videoAttachedProcessing,
        ),
      ),
    );
  }

  Future<void> _openMediaTracks(AdminEpisode episode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpisodeMediaTracksPage(
          episode: episode,
          seriesTitle: widget.seriesTitle,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    refresh();
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
    String? cancelLabel,
  }) async {
    if (_lifecycleBusy || !contentMutationsEnabled(context)) {
      return;
    }

    final confirmed = await confirmContentAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? context.l10n.dismiss,
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
        showContentErrorSnackBar(context, context.l10n.actionIncomplete);
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
    final l10n = context.l10n;
    switch (action) {
      case EpisodeMenuAction.edit:
        await _openEditForm(episode);
      case EpisodeMenuAction.upload:
        await _openVideoUpload(episode, replace: false);
      case EpisodeMenuAction.replaceVideo:
        final confirmed = await confirmContentAction(
          context,
          title: l10n.replaceVideo,
          message: l10n.replaceVideoConfirm,
          confirmLabel: l10n.continueAction,
        );
        if (confirmed && mounted) {
          await _openVideoUpload(episode, replace: true);
        }
      case EpisodeMenuAction.mediaTracks:
        await _openMediaTracks(episode);
      case EpisodeMenuAction.previewActive:
        await _openPreview(episode, source: 'active');
      case EpisodeMenuAction.previewPending:
        await _openPreview(episode, source: 'pending');
      case EpisodeMenuAction.publish:
        await _runLifecycle(
          episode: episode,
          title: l10n.publishSeries,
          message: l10n.publishEpisodeConfirm,
          confirmLabel: l10n.publishSeries,
          successMessage: l10n.episodePublished,
          action: () => _repository.publishEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
      case EpisodeMenuAction.unpublish:
        await _runLifecycle(
          episode: episode,
          title: l10n.unpublishEpisodeTitle,
          message: l10n.unpublishEpisodeConfirm,
          confirmLabel: l10n.unpublish,
          cancelLabel: l10n.cancel,
          successMessage: l10n.episodeUnpublished,
          action: () => _repository.unpublishEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
      case EpisodeMenuAction.archive:
        await _runLifecycle(
          episode: episode,
          title: l10n.archiveAction,
          message: l10n.archiveEpisodeConfirm,
          confirmLabel: l10n.archiveAction,
          successMessage: l10n.episodeArchived,
          action: () => _repository.archiveEpisode(
            episodeId: episode.id,
            expectedContentVersion: episode.contentVersion,
          ),
        );
      case EpisodeMenuAction.restore:
        await _runLifecycle(
          episode: episode,
          title: l10n.restore,
          message: l10n.restoreEpisodeConfirm,
          confirmLabel: l10n.restore,
          successMessage: l10n.episodeRestored,
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
                    onReorder: contentMutationsEnabled(context)
                        ? _openReorder
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
                      Text(
                        context.l10n.archivedEpisodes,
                        style: const TextStyle(
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
  mediaTracks,
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
  AppLocalizations? l10n,
}) {
  final copy = l10n ?? lookupAppLocalizations(const Locale('tr'));
  final items = <PopupMenuEntry<EpisodeMenuAction>>[
    PopupMenuItem(value: EpisodeMenuAction.edit, child: Text(copy.edit)),
  ];

  if (episode.allowsInitialVideoUpload) {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.upload,
        child: Text(copy.uploadVideo),
      ),
    );
  }

  if (episode.allowsReplacementRequest || episode.allowsReplacementRetry) {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.replaceVideo,
        child: Text(copy.replaceVideo),
      ),
    );
  }

  if (episode.hasActiveVideo &&
      episode.cloudflareStreamStatus == CloudflareStreamStatus.ready) {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.mediaTracks,
        child: Text(copy.audioSubtitles),
      ),
    );
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.previewActive,
        child: Text(copy.previewActiveVideo),
      ),
    );
  }

  if (episode.hasPendingReplacement &&
      episode.cloudflareStreamPendingStatus == CloudflareStreamStatus.ready) {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.previewPending,
        child: Text(copy.previewPendingVideo),
      ),
    );
  }

  if (!episode.isArchived && !episode.isPublished) {
    final publishEnabled = episode.canPublishFromMenu(
      parentSeriesArchived: parentSeriesArchived,
    );
    final blockReason = publishEnabled
        ? null
        : episode.publishMenuBlockReason(
            parentSeriesArchived: parentSeriesArchived,
          );
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.publish,
        enabled: publishEnabled,
        child: _EpisodePublishMenuLabel(
          enabled: publishEnabled,
          reason: blockReason,
        ),
      ),
    );
  }

  if (!episode.isArchived && episode.isPublished) {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.unpublish,
        child: Text(copy.unpublish),
      ),
    );
  }

  if (!episode.isArchived) {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.archive,
        child: Text(copy.archiveAction),
      ),
    );
  } else {
    items.add(
      PopupMenuItem(
        value: EpisodeMenuAction.restore,
        child: Text(copy.restore),
      ),
    );
  }

  return items;
}

/// Returns primary menu labels for lifecycle and action visibility tests.
List<String> episodeMenuLabels(
  AdminEpisode episode, {
  bool parentSeriesArchived = false,
}) {
  return episodeMenuItems(episode, parentSeriesArchived: parentSeriesArchived)
      .map((entry) {
        if (entry is PopupMenuItem<EpisodeMenuAction>) {
          return _primaryMenuLabel(entry.child);
        }
        return '';
      })
      .where((label) => label.isNotEmpty)
      .toList();
}

/// Publish menu visibility/enabled state for tests.
PopupMenuItem<EpisodeMenuAction>? episodeMenuPublishItem(
  AdminEpisode episode, {
  bool parentSeriesArchived = false,
}) {
  for (final entry in episodeMenuItems(
    episode,
    parentSeriesArchived: parentSeriesArchived,
  )) {
    if (entry is PopupMenuItem<EpisodeMenuAction> &&
        entry.value == EpisodeMenuAction.publish) {
      return entry;
    }
  }
  return null;
}

String? episodeMenuPublishReason(
  AdminEpisode episode, {
  bool parentSeriesArchived = false,
}) {
  final item = episodeMenuPublishItem(
    episode,
    parentSeriesArchived: parentSeriesArchived,
  );
  final child = item?.child;
  if (child is _EpisodePublishMenuLabel) {
    return child.reason;
  }
  return null;
}

String _primaryMenuLabel(Widget? child) {
  if (child is Text) {
    return child.data ?? '';
  }
  if (child is _EpisodePublishMenuLabel) {
    return _EpisodePublishMenuLabel.label;
  }
  return '';
}

/// Publish row: primary label + optional secondary block reason.
class _EpisodePublishMenuLabel extends StatelessWidget {
  const _EpisodePublishMenuLabel({required this.enabled, this.reason});

  static const label = 'Yayınla';

  final bool enabled;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    // Explicit colors so disabled PopupMenuItem still keeps the reason legible.
    final titleColor = enabled
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFD0D0D0);
    final reasonColor = const Color(0xFFB3B3B3);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.publishSeries,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              adminPublishBlockReasonLabel(context.l10n, reason),
              style: TextStyle(
                color: reasonColor,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
                context.l10n.navEpisodes,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.manageSeriesEpisodes,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
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
                label: Text(context.l10n.editOrder),
              ),
            FilledButton.icon(
              onPressed: createEnabled ? onCreate : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.newEpisode),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.refresh),
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
    final l10n = context.l10n;
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
            dataRowMaxHeight: 110,
            columns: [
              const DataColumn(label: Text('No')),
              DataColumn(label: Text(l10n.title)),
              DataColumn(label: Text(l10n.access)),
              DataColumn(label: Text(l10n.publish)),
              DataColumn(label: Text(l10n.qualified)),
              DataColumn(label: Text(l10n.video)),
              DataColumn(label: Text(l10n.pending)),
              DataColumn(label: Text(l10n.releaseDate)),
              DataColumn(label: Text(l10n.actions)),
            ],
            rows: [
              for (final episode in episodes)
                DataRow(
                  cells: [
                    DataCell(Text(episode.episodeNumber.toString())),
                    DataCell(
                      SizedBox(
                        width: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(episode.title),
                            if (archived)
                              Text(
                                adminArchiveDisplayLabel(
                                  l10n,
                                  episode.archiveLabel,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFE5A000),
                                  fontSize: 12,
                                ),
                              ),
                            SynopsisPreview(synopsis: episode.synopsis),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        episode.isFree
                            ? l10n.free
                            : l10n.coinsAmount(episode.coinPrice),
                      ),
                    ),
                    DataCell(
                      Text(
                        adminPublishDisplayLabel(l10n, episode.publishLabel),
                      ),
                    ),
                    DataCell(Text('${episode.qualifiedViewsTotal}')),
                    DataCell(
                      Text(
                        adminVideoStatusLabel(l10n, episode.videoStatusLabel),
                      ),
                    ),
                    DataCell(
                      Text(
                        adminVideoStatusLabel(
                          l10n,
                          episode.pendingVideoStatusLabel,
                        ),
                      ),
                    ),
                    DataCell(Text(formatEpisodeDateTime(episode.releaseAt))),
                    DataCell(
                      PopupMenuButton<EpisodeMenuAction>(
                        tooltip: l10n.actions,
                        onSelected: (action) => onAction(action, episode),
                        itemBuilder: (context) => episodeMenuItems(
                          episode,
                          parentSeriesArchived: parentSeriesArchived,
                          l10n: context.l10n,
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
    final l10n = context.l10n;
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
                          l10n: context.l10n,
                        ),
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  SynopsisPreview(synopsis: episode.synopsis),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: episode.isFree
                            ? l10n.free
                            : l10n.coinsAmount(episode.coinPrice),
                      ),
                      _InfoChip(
                        label: adminPublishDisplayLabel(
                          l10n,
                          episode.publishLabel,
                        ),
                      ),
                      _InfoChip(
                        label: l10n.qualifiedViewsCount(
                          episode.qualifiedViewsTotal,
                        ),
                      ),
                      if (archived)
                        _InfoChip(
                          label: adminArchiveDisplayLabel(
                            l10n,
                            episode.archiveLabel,
                          ),
                        ),
                      _InfoChip(
                        label: adminVideoStatusLabel(
                          l10n,
                          episode.videoStatusLabel,
                        ),
                      ),
                      if (episode.hasPendingReplacement)
                        _InfoChip(
                          label: adminVideoStatusLabel(
                            l10n,
                            episode.pendingVideoStatusLabel,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.releaseAtLabel(
                      formatEpisodeDateTime(episode.releaseAt),
                    ),
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  if (episode.publishBlockReason != null &&
                      !episode.isPublished &&
                      !episode.isArchived)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        adminPublishBlockReasonLabel(
                          l10n,
                          episode.publishBlockReason,
                        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(
              Icons.playlist_play_outlined,
              size: 56,
              color: Color(0xFF555555),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.noEpisodesYet),
            const SizedBox(height: 8),
            Text(
              context.l10n.createFirstEpisode,
              style: const TextStyle(color: Color(0xFFB3B3B3)),
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
              Text(context.l10n.episodesLoadFailedTitle),
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
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
