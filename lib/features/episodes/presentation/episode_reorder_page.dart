import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
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
  late final SeriesMutationRepository _mutationRepository =
      widget.mutationRepository ?? SeriesMutationRepository();
  late final EpisodeRepository _episodeRepository =
      widget.episodeRepository ?? EpisodeRepository();

  late List<AdminEpisode> _ordered;
  late List<AdminEpisode> _baselineEpisodes;
  late int _expectedVersion;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _persistCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _baselineEpisodes = List<AdminEpisode>.from(widget.episodes);
    _ordered = sortEpisodesByNumber(_baselineEpisodes);
    _expectedVersion = widget.expectedSeriesVersion;
  }

  @override
  void dispose() {
    _persistCompleted = true;
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isSaving || _persistCompleted) {
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
    if (!_hasChanges || _isSaving || _persistCompleted) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await _mutationRepository.reorderEpisodes(
        seriesId: widget.seriesId,
        orderedEpisodeIds: _ordered.map((episode) => episode.id).toList(),
        expectedSeriesVersion: _expectedVersion,
      );

      if (!mounted || _persistCompleted) {
        return;
      }

      setState(() {
        _expectedVersion = result.contentVersion;
        _baselineEpisodes = List<AdminEpisode>.from(_ordered);
        _hasChanges = false;
        _isSaving = false;
        _persistCompleted = true;
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(EpisodeReorderSuccess(result.contentVersion));
    } on ContentException catch (error) {
      if (!mounted || _persistCompleted) {
        return;
      }

      if (error.isConflict) {
        await _reconcileAfterConflict();
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isSaving = false;
        _ordered = sortEpisodesByNumber(_baselineEpisodes);
        _hasChanges = false;
      });
    } catch (_) {
      if (!mounted || _persistCompleted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.reorderSaveFailed;
        _isSaving = false;
        _ordered = sortEpisodesByNumber(_baselineEpisodes);
        _hasChanges = false;
      });
    }
  }

  Future<void> _reconcileAfterConflict() async {
    try {
      final snapshot = await _episodeRepository.loadReorderSnapshot(
        widget.seriesId,
      );

      if (!mounted || _persistCompleted) {
        return;
      }

      setState(() {
        _expectedVersion = snapshot.contentVersion;
        _baselineEpisodes = List<AdminEpisode>.from(snapshot.activeEpisodes);
        _ordered = sortEpisodesByNumber(snapshot.activeEpisodes);
        _hasChanges = false;
        _isSaving = false;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.reorderConflictReloaded),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (_) {
      if (!mounted || _persistCompleted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = context.l10n.reorderLoadFailed;
        _ordered = sortEpisodesByNumber(_baselineEpisodes);
        _hasChanges = false;
      });
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_hasChanges || _isSaving || _persistCompleted) {
      return true;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text(context.l10n.unsavedReorder),
          content: Text(context.l10n.unsavedReorderMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.stay),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.leave),
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
      canPop: !_hasChanges && !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving || _persistCompleted) {
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
          title: Text(context.l10n.episodeOrder),
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
                      subtitle: Text(
                        adminPublishDisplayLabel(
                          context.l10n,
                          episode.publishLabel,
                        ),
                      ),
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
                    child: Text(context.l10n.dismiss),
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
                        : Text(context.l10n.saveOrder),
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
