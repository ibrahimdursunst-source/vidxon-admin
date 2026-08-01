import 'package:flutter/material.dart';

import '../../content/data/content_errors.dart';
import '../../series/data/series_mutation_repository.dart';
import '../data/episode_repository.dart';
import '../domain/admin_episode.dart';
import 'episode_reorder_result.dart';

class EpisodeReorderPage extends StatefulWidget {
  const EpisodeReorderPage({
    required this.seriesId,
    required this.episodes,
    required this.expectedSeriesVersion,
    this.episodeRepository,
    this.mutationRepository,
    super.key,
  });

  final String seriesId;
  final List<AdminEpisode> episodes;
  final int expectedSeriesVersion;
  final EpisodeRepository? episodeRepository;
  final SeriesMutationRepository? mutationRepository;

  @override
  State<EpisodeReorderPage> createState() => _EpisodeReorderPageState();
}

class _EpisodeReorderPageState extends State<EpisodeReorderPage> {
  late final SeriesMutationRepository _repository =
      widget.mutationRepository ?? SeriesMutationRepository();

  late List<AdminEpisode> _ordered;
  late int _expectedVersion;
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ordered = sortEpisodesByNumber(widget.episodes);
    _expectedVersion = widget.expectedSeriesVersion;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isSaving) {
      return;
    }

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _ordered.removeAt(oldIndex);
      _ordered.insert(newIndex, item);
      _hasChanges = true;
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    if (!_hasChanges || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.reorderEpisodes(
        seriesId: widget.seriesId,
        orderedEpisodeIds: _ordered.map((episode) => episode.id).toList(),
        expectedSeriesVersion: _expectedVersion,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(EpisodeReorderSuccess(result.contentVersion));
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isConflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(ContentErrorMapper.conflictMessage),
            duration: Duration(seconds: 6),
          ),
        );
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });
        Navigator.of(context).pop(const EpisodeReorderConflict());
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isSaving = false;
        _ordered = sortEpisodesByNumber(widget.episodes);
        _hasChanges = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Sıralama kaydedilemedi.';
        _isSaving = false;
        _ordered = sortEpisodesByNumber(widget.episodes);
        _hasChanges = false;
      });
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_hasChanges || _isSaving) {
      return true;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('Kaydedilmemiş sıralama'),
          content: const Text(
            'Sıralama değişiklikleri kaydedilmedi. Çıkmak istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Kal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Çık'),
            ),
          ],
        );
      },
    );

    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) {
          return;
        }

        final leave = await _confirmLeave();
        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090909),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Bölüm Sıralaması'),
        ),
        body: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFFFB4B4)),
                ),
              ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ordered.length,
                // ignore: deprecated_member_use
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final episode = _ordered[index];
                  return Material(
                    key: ValueKey(episode.id),
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(
                        '#${episode.episodeNumber} · ${episode.title}',
                      ),
                      subtitle: Text(episode.publishLabel),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (await _confirmLeave() && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: !_hasChanges || _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sıralamayı Kaydet'),
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
