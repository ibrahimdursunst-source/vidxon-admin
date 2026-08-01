import 'package:flutter/material.dart';

import '../../../core/config/media_config.dart';
import '../../content/presentation/content_mutation_guard.dart';
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
                const _EmptyState(
                  icon: Icons.movie_outlined,
                  title: 'Henüz dizi yok',
                  message: 'Katalogda listelenecek dizi bulunmuyor.',
                )
              else if (filteredSeries.isEmpty)
                const _EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Sonuç bulunamadı',
                  message:
                      'Arama veya filtre kriterlerinize uygun dizi bulunamadı.',
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
                'Diziler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vidxon içerik kataloğundaki dizileri yönetin',
                style: TextStyle(color: Color(0xFFB3B3B3)),
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
                label: const Text('Yeni Dizi'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                ),
              ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yenile'),
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
              hintText: 'Dizi adı veya slug ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Temizle',
                      onPressed: searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        SegmentedButton<_PublishFilter>(
          segments: const [
            ButtonSegment(value: _PublishFilter.all, label: Text('Tümü')),
            ButtonSegment(
              value: _PublishFilter.published,
              label: Text('Yayında'),
            ),
            ButtonSegment(value: _PublishFilter.draft, label: Text('Taslak')),
            ButtonSegment(value: _PublishFilter.archived, label: Text('Arşiv')),
          ],
          selected: {publishFilter},
          onSelectionChanged: (selection) {
            onPublishFilterChanged(selection.first);
          },
        ),
        DropdownButton<_StatusFilter>(
          value: statusFilter,
          dropdownColor: const Color(0xFF181818),
          items: const [
            DropdownMenuItem(
              value: _StatusFilter.all,
              child: Text('Tüm Durumlar'),
            ),
            DropdownMenuItem(
              value: _StatusFilter.ongoing,
              child: Text('Devam Ediyor'),
            ),
            DropdownMenuItem(
              value: _StatusFilter.completed,
              child: Text('Tamamlandı'),
            ),
            DropdownMenuItem(
              value: _StatusFilter.comingSoon,
              child: Text('Yakında'),
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
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('Poster')),
              DataColumn(label: Text('Dizi Adı')),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Bölüm')),
              DataColumn(label: Text('Yayın')),
              DataColumn(label: Text('Son Güncelleme')),
              DataColumn(label: Text('İşlemler')),
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
          Column(
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
            ],
          ),
        ),
        DataCell(Text(item.statusLabel)),
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
            tooltip: 'İşlemler',
            onSelected: (action) {
              switch (action) {
                case _SeriesRowAction.detail:
                  onDetailTap(item);
                case _SeriesRowAction.episodes:
                  onEpisodesTap(item);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _SeriesRowAction.detail,
                child: Text('Düzenle / Detay'),
              ),
              PopupMenuItem(
                value: _SeriesRowAction.episodes,
                child: Text('Bölümler'),
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
                  const SizedBox(height: 6),
                  Text(
                    '${item.statusLabel} · ${_formatCategories(item.categories)}',
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
                        label: const Text('Bölümler'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onDetailTap,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Detay'),
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
                        '${item.episodeCount} bölüm',
                        style: const TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                      Text(
                        'Güncelleme: ${_formatDateTime(item.updatedAt)}',
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
        isPublished ? 'Yayında' : 'Taslak',
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
      child: const Text(
        'Arşiv',
        style: TextStyle(
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
                'Diziler yüklenemedi',
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
                child: const Text('Tekrar Dene'),
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
