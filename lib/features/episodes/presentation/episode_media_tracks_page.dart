import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/admin_l10n.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../data/episode_media_tracks_errors.dart';
import '../data/episode_media_tracks_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/duration_warning.dart';
import '../domain/episode_audio_file.dart';
import '../domain/episode_media_tracks.dart';
import '../domain/episode_subtitle_file.dart';
import '../domain/media_locale.dart';

class EpisodeMediaTracksPage extends StatefulWidget {
  const EpisodeMediaTracksPage({
    required this.episode,
    required this.seriesTitle,
    this.repository,
    super.key,
  });

  final AdminEpisode episode;
  final String seriesTitle;
  final EpisodeMediaTracksRepository? repository;

  @override
  State<EpisodeMediaTracksPage> createState() => _EpisodeMediaTracksPageState();
}

class _EpisodeMediaTracksPageState extends State<EpisodeMediaTracksPage> {
  static const _primaryColor = Color(0xFFE50914);

  late final EpisodeMediaTracksRepository _repository =
      widget.repository ?? EpisodeMediaTracksRepository();

  late AdminEpisode _episode;
  EpisodeMediaTracksSnapshot? _snapshot;
  bool _loading = true;
  bool _busy = false;
  String? _errorMessage;

  final _originalLocaleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _originalLocaleController.text = _episode.originalAudioLocale;
    _load();
  }

  @override
  void dispose() {
    _originalLocaleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _repository.listTracks(_episode.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _originalLocaleController.text = snapshot.originalAudioLocale;
        _loading = false;
      });
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = context.l10n.mediaTracksLoadFailed;
      });
    }
  }

  bool get _mutationsEnabled =>
      contentMutationsEnabled(context) && !_episode.isArchived && !_busy;

  Future<void> _saveOriginalLocale() async {
    if (!_mutationsEnabled) {
      return;
    }

    final locale = _originalLocaleController.text.trim();
    if (!MediaLocale.isValid(locale)) {
      setState(() {
        _errorMessage = context.l10n.invalidLocaleExample;
      });
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final updated = await _repository.setOriginalAudioLocale(
        episodeId: _episode.id,
        locale: locale,
        expectedContentVersion: _episode.contentVersion,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _episode = updated;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.originalAudioUpdated)),
      );
      await _load();
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = context.l10n.originalAudioSaveFailed;
      });
    }
  }

  Future<void> _openAudioUploadDialog({EpisodeAudioTrack? existing}) async {
    if (!_mutationsEnabled) {
      return;
    }

    final uploaded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AudioUploadDialog(
          episode: _episode,
          originalLocale:
              _snapshot?.originalAudioLocale ?? _episode.originalAudioLocale,
          replaceLocale: existing?.locale,
          repository: _repository,
        );
      },
    );

    if (uploaded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? context.l10n.audioUploadAccepted
                : context.l10n.audioReplaceAccepted,
          ),
        ),
      );
      await _load();
    }
  }

  Future<void> _openSubtitleUploadDialog({
    EpisodeSubtitleTrack? existing,
  }) async {
    if (!_mutationsEnabled) {
      return;
    }

    final uploaded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _SubtitleUploadDialog(
          episode: _episode,
          replaceLocale: existing?.locale,
          repository: _repository,
        );
      },
    );

    if (uploaded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? context.l10n.subtitleUploaded
                : context.l10n.subtitleReplaced,
          ),
        ),
      );
      await _load();
    }
  }

  Future<void> _removeAudio(EpisodeAudioTrack track) async {
    if (!_mutationsEnabled) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text(context.l10n.removeAudioTrack),
          content: Text(context.l10n.removeAudioTrackConfirm(track.locale)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.dismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: Text(context.l10n.remove),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await _repository.removeAudio(trackId: track.id);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.audioTrackRemoved)));
      await _load();
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = context.l10n.audioTrackRemoveFailed;
      });
    }
  }

  Future<void> _removeSubtitle(EpisodeSubtitleTrack track) async {
    if (!_mutationsEnabled) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text(context.l10n.removeSubtitle),
          content: Text(context.l10n.removeSubtitleConfirm(track.locale)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.dismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: Text(context.l10n.remove),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await _repository.removeSubtitle(trackId: track.id);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.subtitleRemoved)));
      await _load();
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = context.l10n.subtitleRemoveFailed;
      });
    }
  }

  Future<void> _reconcileAudio(EpisodeAudioTrack track) async {
    if (!_mutationsEnabled) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await _repository.reconcileAudio(trackId: track.id);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      await _load();
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = context.l10n.statusUpdateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final mutationsEnabled = _mutationsEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(context.l10n.audioSubtitles),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoCard(
                          seriesTitle: widget.seriesTitle,
                          episodeNumber: _episode.episodeNumber,
                          episodeTitle: _episode.title,
                          durationSeconds: _episode.durationSeconds,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        _SectionCard(
                          title: context.l10n.originalAudioLanguage,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.originalAudioHelp,
                                style: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LocaleField(
                                controller: _originalLocaleController,
                                enabled: mutationsEnabled,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton(
                                  onPressed: mutationsEnabled
                                      ? _saveOriginalLocale
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                  ),
                                  child: Text(context.l10n.save),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionCard(
                          title: context.l10n.dubs,
                          trailing: TextButton.icon(
                            onPressed: mutationsEnabled
                                ? () => _openAudioUploadDialog()
                                : null,
                            icon: const Icon(Icons.add),
                            label: Text(context.l10n.add),
                          ),
                          child:
                              snapshot == null || snapshot.audioTracks.isEmpty
                              ? Text(
                                  context.l10n.noDubsYet,
                                  style: const TextStyle(
                                    color: Color(0xFFB3B3B3),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final track in snapshot.audioTracks)
                                      _TrackTile(
                                        locale: track.locale,
                                        statusLabel: adminVideoStatusLabel(
                                          context.l10n,
                                          track.statusLabel,
                                        ),
                                        warningLevel:
                                            track.durationWarningLevel,
                                        enabled: mutationsEnabled,
                                        onReplace: () => _openAudioUploadDialog(
                                          existing: track,
                                        ),
                                        onRemove: track.canRemove
                                            ? () => _removeAudio(track)
                                            : null,
                                        onRefreshStatus: track.canReconcile
                                            ? () => _reconcileAudio(track)
                                            : null,
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),
                        _SectionCard(
                          title: context.l10n.subtitles,
                          trailing: TextButton.icon(
                            onPressed: mutationsEnabled
                                ? () => _openSubtitleUploadDialog()
                                : null,
                            icon: const Icon(Icons.add),
                            label: Text(context.l10n.add),
                          ),
                          child:
                              snapshot == null ||
                                  snapshot.subtitleTracks.isEmpty
                              ? Text(
                                  context.l10n.noSubtitlesYet,
                                  style: const TextStyle(
                                    color: Color(0xFFB3B3B3),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final track in snapshot.subtitleTracks)
                                      _TrackTile(
                                        locale: track.locale,
                                        statusLabel: adminVideoStatusLabel(
                                          context.l10n,
                                          track.statusLabel,
                                        ),
                                        enabled: mutationsEnabled,
                                        onReplace: () =>
                                            _openSubtitleUploadDialog(
                                              existing: track,
                                            ),
                                        onRemove: track.canRemove
                                            ? () => _removeSubtitle(track)
                                            : null,
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.seriesTitle,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.durationSeconds,
  });

  final String seriesTitle;
  final int episodeNumber;
  final String episodeTitle;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seriesTitle,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.episodePickerLabel(episodeNumber, episodeTitle),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (durationSeconds != null) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.episodeDurationSeconds(durationSeconds!),
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A2222)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Color(0xFFFFB4B4))),
      ),
    );
  }
}

class _LocaleField extends StatelessWidget {
  const _LocaleField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: context.l10n.localeCode,
            hintText: 'tr, en, pt_BR, zh_Hans…',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final locale in MediaLocale.suggestedLocales)
              ActionChip(
                label: Text(MediaLocale.displayName(locale)),
                onPressed: enabled
                    ? () {
                        controller.text = locale;
                        controller.selection = TextSelection.collapsed(
                          offset: locale.length,
                        );
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.locale,
    required this.statusLabel,
    required this.enabled,
    this.warningLevel,
    this.onReplace,
    this.onRemove,
    this.onRefreshStatus,
  });

  final String locale;
  final String statusLabel;
  final bool enabled;
  final DurationWarningLevel? warningLevel;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;
  final VoidCallback? onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final warningMessage = warningLevel == null
        ? null
        : durationWarningBannerMessage(warningLevel!) == null
        ? null
        : context.l10n.durationMismatch;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      locale,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                ],
              ),
              if (warningMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  warningMessage,
                  style: const TextStyle(
                    color: Color(0xFFFFCC80),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (onRefreshStatus != null)
                    TextButton(
                      onPressed: enabled ? onRefreshStatus : null,
                      child: Text(context.l10n.updateStatus),
                    ),
                  TextButton(
                    onPressed: enabled ? onReplace : null,
                    child: Text(context.l10n.replace),
                  ),
                  TextButton(
                    onPressed: enabled ? onRemove : null,
                    child: Text(context.l10n.remove),
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

class _AudioUploadDialog extends StatefulWidget {
  const _AudioUploadDialog({
    required this.episode,
    required this.originalLocale,
    required this.repository,
    this.replaceLocale,
  });

  final AdminEpisode episode;
  final String originalLocale;
  final String? replaceLocale;
  final EpisodeMediaTracksRepository repository;

  @override
  State<_AudioUploadDialog> createState() => _AudioUploadDialogState();
}

class _AudioUploadDialogState extends State<_AudioUploadDialog> {
  static const _primaryColor = Color(0xFFE50914);

  late final TextEditingController _localeController;
  final _durationController = TextEditingController();

  EpisodeAudioFile? _file;
  bool _uploading = false;
  bool _severeConfirmed = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _localeController = TextEditingController(text: widget.replaceLocale ?? '');
    final episodeSeconds = widget.episode.durationSeconds;
    if (episodeSeconds != null && episodeSeconds > 0) {
      _durationController.text = '$episodeSeconds';
    }
  }

  @override
  void dispose() {
    _localeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  DurationWarningResult? get _warning {
    final audioSeconds = int.tryParse(_durationController.text.trim());
    final videoSeconds = widget.episode.durationSeconds;
    if (audioSeconds == null ||
        audioSeconds <= 0 ||
        videoSeconds == null ||
        videoSeconds <= 0) {
      return null;
    }
    return classifyDurationWarning(
      audioDurationMs: audioSeconds * 1000,
      videoDurationMs: videoSeconds * 1000,
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: EpisodeAudioFile.allowedExtensions,
      withData: false,
      withReadStream: true,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    try {
      final file = EpisodeAudioFileValidator.validate(
        name: picked.name,
        size: picked.size,
        contentType: picked.extension == null
            ? null
            : EpisodeAudioFile.extensionContentTypes[picked.extension!
                  .toLowerCase()],
        readStream: picked.readStream,
      );
      setState(() {
        _file = file;
        _error = null;
      });
    } on EpisodeAudioFileValidationException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null || _uploading) {
      return;
    }

    final locale = _localeController.text.trim();
    if (!MediaLocale.isValid(locale)) {
      setState(() => _error = context.l10n.invalidLocaleExample);
      return;
    }

    if (locale == widget.originalLocale) {
      setState(() => _error = context.l10n.dubCannotMatchOriginal);
      return;
    }

    final warning = _warning;
    if (warning != null &&
        warning.level.requiresExplicitOverride &&
        !_severeConfirmed) {
      setState(() => _error = context.l10n.severeDurationNeedsConfirm);
      return;
    }

    final audioSeconds = int.tryParse(_durationController.text.trim());

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      await widget.repository.uploadAudioTrack(
        episodeId: widget.episode.id,
        locale: locale,
        file: file,
        audioDurationMs: audioSeconds == null ? null : audioSeconds * 1000,
        videoDurationMs: widget.episode.durationSeconds == null
            ? null
            : widget.episode.durationSeconds! * 1000,
        adminDurationOverride: _severeConfirmed,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() => _progress = progress);
        },
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _error = context.l10n.uploadFailedRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final warning = _warning;
    final warningMessage = warning == null
        ? null
        : durationWarningBannerMessage(warning.level) == null
        ? null
        : context.l10n.durationMismatch;
    final isReplace = widget.replaceLocale != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: Text(
        isReplace ? context.l10n.replaceAudioTrack : context.l10n.addAudioTrack,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _LocaleField(
                controller: _localeController,
                enabled: !_uploading && !isReplace,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                enabled: !_uploading,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.audioDurationSeconds,
                  border: const OutlineInputBorder(),
                  helperText: context.l10n.audioDurationHint,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (warningMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  warningMessage,
                  style: TextStyle(
                    color: warning!.level == DurationWarningLevel.severe
                        ? const Color(0xFFFF8A80)
                        : const Color(0xFFFFCC80),
                  ),
                ),
              ],
              if (warning?.level.requiresExplicitOverride == true) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _severeConfirmed,
                  onChanged: _uploading
                      ? null
                      : (value) {
                          setState(() => _severeConfirmed = value ?? false);
                        },
                  title: Text(
                    context.l10n.severeDurationConfirm,
                    style: const TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.audio_file_outlined),
                label: Text(context.l10n.selectAudioFile),
              ),
              if (_file != null) ...[
                const SizedBox(height: 8),
                Text(_file!.name),
                Text(
                  '${(_file!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                  style: const TextStyle(color: Color(0xFFB3B3B3)),
                ),
              ],
              if (_uploading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress.clamp(0, 1),
                  color: _primaryColor,
                  backgroundColor: const Color(0xFF2A2A2A),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.dismiss),
        ),
        FilledButton(
          onPressed: _uploading || _file == null ? null : _upload,
          style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          child: Text(context.l10n.upload),
        ),
      ],
    );
  }
}

class _SubtitleUploadDialog extends StatefulWidget {
  const _SubtitleUploadDialog({
    required this.episode,
    required this.repository,
    this.replaceLocale,
  });

  final AdminEpisode episode;
  final String? replaceLocale;
  final EpisodeMediaTracksRepository repository;

  @override
  State<_SubtitleUploadDialog> createState() => _SubtitleUploadDialogState();
}

class _SubtitleUploadDialogState extends State<_SubtitleUploadDialog> {
  static const _primaryColor = Color(0xFFE50914);

  late final TextEditingController _localeController;
  EpisodeSubtitleFile? _file;
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _localeController = TextEditingController(text: widget.replaceLocale ?? '');
  }

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [EpisodeSubtitleFile.allowedExtension],
      withData: false,
      withReadStream: true,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    try {
      final file = EpisodeSubtitleFileValidator.validate(
        name: picked.name,
        size: picked.size,
        readStream: picked.readStream,
      );
      setState(() {
        _file = file;
        _error = null;
      });
    } on EpisodeSubtitleFileValidationException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null || _uploading) {
      return;
    }

    final locale = _localeController.text.trim();
    if (!MediaLocale.isValid(locale)) {
      setState(() => _error = context.l10n.invalidLocaleExample);
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      await widget.repository.uploadSubtitle(
        episodeId: widget.episode.id,
        locale: locale,
        file: file,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() => _progress = progress);
        },
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on EpisodeMediaTracksException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _error = context.l10n.uploadFailedRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReplace = widget.replaceLocale != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: Text(
        isReplace ? context.l10n.replaceSubtitle : context.l10n.addSubtitle,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _LocaleField(
                controller: _localeController,
                enabled: !_uploading && !isReplace,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.subtitles_outlined),
                label: Text(context.l10n.selectWebvtt),
              ),
              if (_file != null) ...[
                const SizedBox(height: 8),
                Text(_file!.name),
              ],
              if (_uploading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress.clamp(0, 1),
                  color: _primaryColor,
                  backgroundColor: const Color(0xFF2A2A2A),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.dismiss),
        ),
        FilledButton(
          onPressed: _uploading || _file == null ? null : _upload,
          style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          child: Text(context.l10n.upload),
        ),
      ],
    );
  }
}
