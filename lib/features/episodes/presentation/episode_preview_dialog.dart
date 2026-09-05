import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../../content/data/content_errors.dart';
import '../data/episode_preview_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/cloudflare_stream_status.dart';
import 'stream_preview_player.dart';

Future<void> showEpisodePreviewDialog({
  required BuildContext context,
  required AdminEpisode episode,
  required String videoSource,
  required EpisodePreviewRepository repository,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return _EpisodePreviewDialog(
        episode: episode,
        videoSource: videoSource,
        repository: repository,
      );
    },
  );
}

class _EpisodePreviewDialog extends StatefulWidget {
  const _EpisodePreviewDialog({
    required this.episode,
    required this.videoSource,
    required this.repository,
  });

  final AdminEpisode episode;
  final String videoSource;
  final EpisodePreviewRepository repository;

  @override
  State<_EpisodePreviewDialog> createState() => _EpisodePreviewDialogState();
}

class _EpisodePreviewDialogState extends State<_EpisodePreviewDialog> {
  String? _previewUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final blockReason = _previewBlockReason(
      episode: widget.episode,
      videoSource: widget.videoSource,
      l10n: lookupAppLocalizations(const Locale('tr')),
    );
    if (blockReason != null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _previewUrl = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewUrl = null;
    });

    try {
      final response = await widget.repository.createPreviewUrl(
        episodeId: widget.episode.id,
        videoSource: widget.videoSource,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _previewUrl = response.previewUrl;
        _isLoading = false;
      });
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.previewLoadFailed;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _previewUrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blockReason = _previewBlockReason(
      episode: widget.episode,
      videoSource: widget.videoSource,
      l10n: l10n,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: Text(
        widget.videoSource == 'pending'
            ? l10n.pendingVideoPreview
            : l10n.activeVideoPreview,
      ),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (blockReason != null)
              Text(
                blockReason,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              )
            else if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFFFB4B4)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadPreview, child: Text(l10n.retry)),
            ] else if (_previewUrl != null)
              SizedBox(
                height: 360,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: StreamPreviewPlayer(previewUrl: _previewUrl!),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }
}

String? _previewBlockReason({
  required AdminEpisode episode,
  required String videoSource,
  required AppLocalizations l10n,
}) {
  if (videoSource == 'active') {
    if (!episode.hasActiveVideo) {
      return l10n.noActiveVideo;
    }

    if (episode.cloudflareStreamStatus != CloudflareStreamStatus.ready) {
      return l10n.activeVideoNotReady;
    }
  }

  if (videoSource == 'pending') {
    if (!episode.hasPendingReplacement) {
      return l10n.noPendingVideo;
    }

    if (episode.cloudflareStreamPendingStatus != CloudflareStreamStatus.ready) {
      return l10n.pendingVideoNotReady;
    }
  }

  return null;
}
