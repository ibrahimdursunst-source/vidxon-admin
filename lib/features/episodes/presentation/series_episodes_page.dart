import 'package:flutter/material.dart';

import '../data/episode_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/episode_release_at.dart';
import 'episode_form_page.dart';
import 'episode_video_upload_page.dart';

class SeriesEpisodesPage extends StatefulWidget {
  const SeriesEpisodesPage({
    required this.seriesId,
    required this.seriesTitle,
    super.key,
  });

  final String seriesId;
  final String seriesTitle;

  @override
  State<SeriesEpisodesPage> createState() => _SeriesEpisodesPageState();
}

class _SeriesEpisodesPageState extends State<SeriesEpisodesPage> {
  static const _desktopBreakpoint = 900.0;

  final EpisodeRepository _repository = EpisodeRepository();

  late Future<List<AdminEpisode>> _episodesFuture;

  @override
  void initState() {
    super.initState();
    _episodesFuture = _repository.fetchEpisodesForSeries(widget.seriesId);
  }

  Future<void> refresh() async {
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

  Future<void> _openVideoUpload(AdminEpisode episode) async {
    if (!episode.allowsVideoUpload) {
      return;
    }

    final result = await Navigator.of(context).push<AdminEpisode>(
      MaterialPageRoute(
        builder: (context) => EpisodeVideoUploadPage(
          episode: episode,
          seriesTitle: widget.seriesTitle,
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
      const SnackBar(
        content: Text(
          'Video yüklendi ve bölüme bağlandı. Cloudflare Stream videoyu '
          'işlemeye devam ediyor; durum kısa süre içinde güncellenecektir.',
        ),
      ),
    );
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

          final episodes = snapshot.data ?? const [];

          return RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(onCreate: _openCreateForm, onRefresh: refresh),
                  const SizedBox(height: 24),
                  if (episodes.isEmpty)
                    const _EmptyState()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= _desktopBreakpoint) {
                          return _EpisodesDataTable(
                            episodes: episodes,
                            onEdit: _openEditForm,
                            onUploadVideo: _openVideoUpload,
                          );
                        }

                        return _EpisodesCardList(
                          episodes: episodes,
                          onEdit: _openEditForm,
                          onUploadVideo: _openVideoUpload,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onCreate, required this.onRefresh});

  final VoidCallback onCreate;
  final VoidCallback onRefresh;

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
            FilledButton.icon(
              onPressed: onCreate,
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

class _EpisodesDataTable extends StatelessWidget {
  const _EpisodesDataTable({
    required this.episodes,
    required this.onEdit,
    required this.onUploadVideo,
  });

  final List<AdminEpisode> episodes;
  final ValueChanged<AdminEpisode> onEdit;
  final ValueChanged<AdminEpisode> onUploadVideo;

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
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Başlık')),
              DataColumn(label: Text('Erişim')),
              DataColumn(label: Text('Coin')),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('Yayın Tarihi')),
              DataColumn(label: Text('Video')),
              DataColumn(label: Text('İzlenme')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: [
              for (final episode in episodes)
                DataRow(
                  cells: [
                    DataCell(Text(episode.episodeNumber.toString())),
                    DataCell(Text(episode.title)),
                    DataCell(Text(episode.isFree ? 'Ücretsiz' : 'Kilitli')),
                    DataCell(Text(episode.coinPrice.toString())),
                    DataCell(Text(episode.isPublished ? 'Yayında' : 'Taslak')),
                    DataCell(Text(formatEpisodeDateTime(episode.releaseAt))),
                    DataCell(_EpisodeVideoStatusCell(episode: episode)),
                    DataCell(Text(episode.totalViews.toString())),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (episode.allowsVideoUpload)
                            TextButton(
                              onPressed: () => onUploadVideo(episode),
                              child: const Text('Video Yükle'),
                            ),
                          IconButton(
                            tooltip: 'Bölümü Düzenle',
                            onPressed: () => onEdit(episode),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
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
    required this.onEdit,
    required this.onUploadVideo,
  });

  final List<AdminEpisode> episodes;
  final ValueChanged<AdminEpisode> onEdit;
  final ValueChanged<AdminEpisode> onUploadVideo;

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
                      IconButton(
                        tooltip: 'Bölümü Düzenle',
                        onPressed: () => onEdit(episode),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: episode.isFree ? 'Ücretsiz' : 'Kilitli'),
                      _InfoChip(label: '${episode.coinPrice} coin'),
                      _InfoChip(
                        label: episode.isPublished ? 'Yayında' : 'Taslak',
                      ),
                      _InfoChip(label: episode.videoStatusLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (episode.allowsVideoUpload)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => onUploadVideo(episode),
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Video Yükle'),
                      ),
                    ),
                  Text(
                    'Yayın: ${formatEpisodeDateTime(episode.releaseAt)}',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  Text(
                    'İzlenme: ${episode.totalViews}',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
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

class _EpisodeVideoStatusCell extends StatelessWidget {
  const _EpisodeVideoStatusCell({required this.episode});

  final AdminEpisode episode;

  @override
  Widget build(BuildContext context) {
    return Text(episode.videoStatusLabel);
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
