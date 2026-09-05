import 'package:flutter/material.dart';

import '../../../core/config/media_config.dart';
import '../../../l10n/admin_l10n.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../../content_rating/presentation/synopsis_preview.dart';
import '../../episodes/presentation/series_episodes_page.dart';
import '../data/series_repository.dart';
import '../domain/admin_series.dart';
import 'series_detail_page.dart';

enum _PublishFilter { all, published, draft, archived }

enum _StatusFilter { all, ongoing, completed, comingSoon }

class SeriesListPage extends StatefulWidget {
  const SeriesListPage({this.onCreateTap, this.repository, super.key});

  final VoidCallback? onCreateTap;
  final SeriesRepository? repository;

  @override
  SeriesListPageState createState() => SeriesListPageState();
}

class SeriesListPageState extends State<SeriesListPage> {
  static const _desktopBreakpoint = 900.0;

  late final SeriesRepository _repository =
      widget.repository ?? SeriesRepository();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<AdminSeries>> _seriesFuture;

  _PublishFilter _publishFilter = _PublishFilter.all;
  _StatusFilter _statusFilter = _StatusFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _seriesFuture = _repository.fetchAll();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void refresh() {
    setState(() {
      _seriesFuture = _repository.fetchAll();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<AdminSeries> _applyFilters(List<AdminSeries> series) {
    final normalizedQuery = _searchQuery.toLowerCase();

    return series.where((item) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.slug.toLowerCase().contains(normalizedQuery);

      final matchesPublish = switch (_publishFilter) {
        _PublishFilter.all => true,
        _PublishFilter.published => item.isPublished && !item.isArchived,
        _PublishFilter.draft => !item.isPublished && !item.isArchived,
        _PublishFilter.archived => item.isArchived,
      };

      final matchesStatus = switch (_statusFilter) {
        _StatusFilter.all => true,
        _StatusFilter.ongoing => item.status == 'ongoing',
        _StatusFilter.completed => item.status == 'completed',
        _StatusFilter.comingSoon => item.status == 'coming_soon',
      };

      return matchesSearch && matchesPublish && matchesStatus;
    }).toList();
  }

  void _openEpisodes(BuildContext context, AdminSeries series) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SeriesEpisodesPage(
          seriesId: series.id,
          seriesTitle: series.title,
          initialSeries: series,
          isSeriesArchived: series.isArchived,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, AdminSeries series) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) =>
                SeriesDetailPage(seriesId: series.id, initialSeries: series),
          ),
        )
        .then((_) => refresh());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminSeries>>(
      future: _seriesFuture,
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

        final allSeries = snapshot.data ?? const [];
        final filteredSeries = _applyFilters(allSeries);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(onRefresh: refresh, onCreateTap: widget.onCreateTap),
              const SizedBox(height: 24),
              _FilterBar(
                searchController: _searchController,
                publishFilter: _publishFilter,
                statusFilter: _statusFilter,
                onPublishFilterChanged: (value) {
                  setState(() => _publishFilter = value);
                },
                onStatusFilterChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
              const SizedBox(height: 24),
              if (allSeries.isEmpty)
                _EmptyState(
                  icon: Icons.movie_outlined,
                  title: context.l10n.noSeriesYet,
                  message: context.l10n.noSeriesInCatalog,
                )
              else if (filteredSeries.isEmpty)
                _EmptyState(
                  icon: Icons.search_off_outlined,
                  title: context.l10n.noResults,
                  message: context.l10n.noSeriesMatchFilters,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _desktopBreakpoint) {
                      return _SeriesDataTable(
                        series: filteredSeries,
                        onEpisodesTap: (series) =>
                            _openEpisodes(context, series),
                        onDetailTap: (series) => _openDetail(context, series),
                      );
                    }

                    return _SeriesCardList(
                      series: filteredSeries,
                      onEpisodesTap: (series) => _openEpisodes(context, series),
                      onDetailTap: (series) => _openDetail(context, series),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onRefresh, this.onCreateTap});

  final VoidCallback onRefresh;
  final VoidCallback? onCreateTap;

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
                context.l10n.navSeries,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.seriesCatalogSubtitle,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (onCreateTap != null)
              FilledButton.icon(
                onPressed: contentMutationsEnabled(context)
                    ? onCreateTap
                    : null,
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.l10n.newSeries),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                ),
              ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.refresh),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.publishFilter,
    required this.statusFilter,
    required this.onPublishFilterChanged,
    required this.onStatusFilterChanged,
  });

  final TextEditingController searchController;
  final _PublishFilter publishFilter;
  final _StatusFilter statusFilter;
  final ValueChanged<_PublishFilter> onPublishFilterChanged;
  final ValueChanged<_StatusFilter> onStatusFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: context.l10n.searchSeriesNameOrSlug,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.clear,
                      onPressed: searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        SegmentedButton<_PublishFilter>(
          segments: [
            ButtonSegment(
              value: _PublishFilter.all,
              label: Text(context.l10n.all),
            ),
            ButtonSegment(
              value: _PublishFilter.published,
              label: Text(context.l10n.published),
            ),
            ButtonSegment(
              value: _PublishFilter.draft,
              label: Text(context.l10n.draft),
            ),
            ButtonSegment(
              value: _PublishFilter.archived,
              label: Text(context.l10n.archive),
            ),
          ],
          selected: {publishFilter},
          onSelectionChanged: (selection) {
            onPublishFilterChanged(selection.first);
          },
        ),
        DropdownButton<_StatusFilter>(
          value: statusFilter,
          dropdownColor: const Color(0xFF181818),
          items: [
            DropdownMenuItem(
              value: _StatusFilter.all,
              child: Text(context.l10n.allStatuses),
            ),
            DropdownMenuItem(
              value: _StatusFilter.ongoing,
              child: Text(adminSeriesStatusLabel(context.l10n, 'ongoing')),
            ),
            DropdownMenuItem(
              value: _StatusFilter.completed,
              child: Text(context.l10n.statusCompleted),
            ),
            DropdownMenuItem(
              value: _StatusFilter.comingSoon,
              child: Text(context.l10n.statusComingSoon),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onStatusFilterChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _SeriesDataTable extends StatelessWidget {
  const _SeriesDataTable({
    required this.series,
    required this.onEpisodesTap,
    required this.onDetailTap,
  });

  final List<AdminSeries> series;
  final ValueChanged<AdminSeries> onEpisodesTap;
  final ValueChanged<AdminSeries> onDetailTap;

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
            dataRowMinHeight: 72,
            dataRowMaxHeight: 120,
            columns: [
              DataColumn(label: Text(context.l10n.poster)),
              DataColumn(label: Text(context.l10n.seriesName)),
              DataColumn(label: Text(context.l10n.status)),
              DataColumn(label: Text(context.l10n.category)),
              DataColumn(label: Text(context.l10n.destinationEpisode)),
              DataColumn(label: Text(context.l10n.publish)),
              DataColumn(label: Text(context.l10n.lastUpdate)),
              DataColumn(label: Text(context.l10n.actions)),
            ],
            rows: [for (final item in series) _buildRow(context, item)],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, AdminSeries item) {
    return DataRow(
      cells: [
        DataCell(_SeriesPoster(posterPath: item.posterPath, size: 48)),
        DataCell(
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.slug.isNotEmpty)
                  Text(
                    item.slug,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 12,
                    ),
                  ),
                SynopsisPreview(synopsis: item.synopsis),
              ],
            ),
          ),
        ),
        DataCell(Text(adminSeriesStatusLabel(context.l10n, item.statusLabel))),
        DataCell(Text(_formatCategories(item.categories))),
        DataCell(Text(item.episodeCount.toString())),
        DataCell(
          Wrap(
            spacing: 6,
            children: [
              _PublishStatusBadge(isPublished: item.isPublished),
              if (item.isArchived) const _ArchiveBadge(),
            ],
          ),
        ),
        DataCell(Text(_formatDateTime(item.updatedAt))),
        DataCell(
          PopupMenuButton<_SeriesRowAction>(
            tooltip: context.l10n.actions,
            onSelected: (action) {
              switch (action) {
                case _SeriesRowAction.detail:
                  onDetailTap(item);
                case _SeriesRowAction.episodes:
                  onEpisodesTap(item);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SeriesRowAction.detail,
                child: Text(context.l10n.editOrDetail),
              ),
              PopupMenuItem(
                value: _SeriesRowAction.episodes,
                child: Text(context.l10n.navEpisodes),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }
}

enum _SeriesRowAction { detail, episodes }

class _SeriesCardList extends StatelessWidget {
  const _SeriesCardList({
    required this.series,
    required this.onEpisodesTap,
    required this.onDetailTap,
  });

  final List<AdminSeries> series;
  final ValueChanged<AdminSeries> onEpisodesTap;
  final ValueChanged<AdminSeries> onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in series) ...[
          _SeriesCard(
            item: item,
            onEpisodesTap: () => onEpisodesTap(item),
            onDetailTap: () => onDetailTap(item),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.item,
    required this.onEpisodesTap,
    required this.onDetailTap,
  });

  final AdminSeries item;
  final VoidCallback onEpisodesTap;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeriesPoster(posterPath: item.posterPath, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SynopsisPreview(synopsis: item.synopsis),
                  const SizedBox(height: 6),
                  Text(
                    '${adminSeriesStatusLabel(context.l10n, item.statusLabel)} · ${_formatCategories(item.categories)}',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEpisodesTap,
                        icon: const Icon(
                          Icons.playlist_play_outlined,
                          size: 18,
                        ),
                        label: Text(context.l10n.navEpisodes),
                      ),
                      OutlinedButton.icon(
                        onPressed: onDetailTap,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(context.l10n.detail),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _PublishStatusBadge(isPublished: item.isPublished),
                      if (item.isArchived) const _ArchiveBadge(),
                      Text(
                        context.l10n.episodeCountLabel(item.episodeCount),
                        style: const TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                      Text(
                        context.l10n.updatedAtLabel(
                          _formatDateTime(item.updatedAt),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesPoster extends StatelessWidget {
  const _SeriesPoster({required this.posterPath, required this.size});

  final String posterPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final posterUrl = MediaConfig.resolvePosterUrl(posterPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size * 0.7,
        height: size,
        child: posterUrl == null
            ? _buildPlaceholder()
            : Image.network(
                posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return _buildPlaceholder(showLoader: true);
                },
              ),
      ),
    );
  }

  Widget _buildPlaceholder({bool showLoader = false}) {
    return ColoredBox(
      color: const Color(0xFF181818),
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.movie_outlined, color: Color(0xFF555555)),
      ),
    );
  }
}

class _PublishStatusBadge extends StatelessWidget {
  const _PublishStatusBadge({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final color = isPublished
        ? const Color(0xFF35C46A)
        : const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        isPublished ? context.l10n.published : context.l10n.draft,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ArchiveBadge extends StatelessWidget {
  const _ArchiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5A000).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5A000).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        context.l10n.archive,
        style: const TextStyle(
          color: Color(0xFFE5A000),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(icon, size: 56, color: const Color(0xFF555555)),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ),
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
              Text(
                context.l10n.seriesLoadFailedTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                  backgroundColor: const Color(0xFFE50914),
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

String _formatCategories(List<String> categories) {
  if (categories.isEmpty) {
    return '—';
  }

  return categories.join(', ');
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute';
}
