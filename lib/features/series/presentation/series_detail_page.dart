import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/media_config.dart';
import '../../../l10n/admin_l10n.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/admin_category.dart';
import '../../content/data/content_errors.dart';
import '../../content/presentation/content_conflict_helper.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../../content_rating/domain/content_rating_catalog.dart';
import '../../content_rating/presentation/content_rating_editor.dart';
import '../../episodes/presentation/series_episodes_page.dart';
import '../../media/data/image_upload_repository.dart';
import '../../media/domain/poster_file.dart';
import '../../partners/data/partner_errors.dart';
import '../../partners/data/partner_repository.dart';
import '../../partners/domain/partner_series_assignment.dart';
import '../../partners/presentation/partner_assignment_history_panel.dart';
import '../../partners/presentation/partner_selector.dart';
import '../data/series_mutation_repository.dart';
import '../data/series_repository.dart';
import '../domain/admin_series.dart';
import '../domain/update_series_input.dart';
import 'series_create_page.dart';

class SeriesDetailPage extends StatefulWidget {
  const SeriesDetailPage({
    required this.seriesId,
    this.initialSeries,
    this.seriesRepository,
    this.mutationRepository,
    this.categoryRepository,
    this.imageUploadRepository,
    this.partnerRepository,
    this.initialPosterForTesting,
    super.key,
  });

  final String seriesId;
  final AdminSeries? initialSeries;
  final SeriesRepository? seriesRepository;
  final SeriesMutationRepository? mutationRepository;
  final CategoryRepository? categoryRepository;
  final ImageUploadRepository? imageUploadRepository;
  final PartnerRepository? partnerRepository;
  final PosterFile? initialPosterForTesting;

  @override
  State<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends State<SeriesDetailPage> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _synopsisController = TextEditingController();

  late final SeriesRepository _seriesRepository =
      widget.seriesRepository ?? SeriesRepository();
  late final SeriesMutationRepository _mutationRepository =
      widget.mutationRepository ?? SeriesMutationRepository();
  late final CategoryRepository _categoryRepository =
      widget.categoryRepository ?? CategoryRepository();
  late final ImageUploadRepository _imageUploadRepository =
      widget.imageUploadRepository ?? ImageUploadRepository();
  late final PartnerRepository _partnerRepository =
      widget.partnerRepository ?? PartnerRepository();

  AdminSeries? _series;
  AdminSeries? _placeholderSeries;
  late Future<List<AdminCategory>> _categoriesFuture;

  SeriesStatusValue _status = SeriesStatusValue.ongoing;
  bool _isFeatured = false;
  bool _isPremium = false;
  final Set<String> _selectedCategoryIds = {};
  int? _contentAgeRating;
  List<String> _contentDescriptors = [];
  String? _selectedPartnerId;
  String? _loadedPartnerId;

  List<PartnerSeriesAssignment> _assignments = const [];
  bool _assignmentsLoading = false;
  String? _assignmentsError;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPosterUploading = false;
  bool _lifecycleBusy = false;

  String? _errorMessage;

  PosterFile? _newPosterFile;

  @override
  void initState() {
    super.initState();
    _placeholderSeries = widget.initialSeries;
    _newPosterFile = widget.initialPosterForTesting;
    _categoriesFuture = _categoryRepository.fetchAll();
    _loadSeries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fresh = await _seriesRepository.fetchById(widget.seriesId);
      if (!mounted) {
        return;
      }

      _applySeriesToForm(fresh);
      setState(() {
        _series = fresh;
        _isLoading = false;
      });
      await _loadAssignments();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _series = null;
        _errorMessage = context.l10n.seriesLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _applySeriesToForm(AdminSeries series) {
    _titleController.text = series.title;
    _synopsisController.text = series.synopsis;
    _status = SeriesStatusValue.values.firstWhere(
      (value) => value.value == series.status,
      orElse: () => SeriesStatusValue.ongoing,
    );
    _isFeatured = series.isFeatured;
    _isPremium = series.isPremium;
    _selectedCategoryIds
      ..clear()
      ..addAll(series.categoryIds);
    _contentAgeRating = series.contentAgeRating;
    _contentDescriptors = List<String>.from(series.contentDescriptors);
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _assignmentsLoading = true;
      _assignmentsError = null;
    });

    try {
      final history = await _partnerRepository.fetchAssignmentHistory(
        widget.seriesId,
      );
      if (!mounted) {
        return;
      }

      final active = history.where((a) => a.isActive).toList(growable: false);
      final currentPartnerId = active.isEmpty ? null : active.first.partnerId;

      setState(() {
        _assignments = history;
        _selectedPartnerId = currentPartnerId;
        _loadedPartnerId = currentPartnerId;
        _assignmentsLoading = false;
      });
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assignmentsError = error.message;
        _assignmentsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assignmentsError = context.l10n.assignmentHistoryLoadFailed;
        _assignmentsLoading = false;
      });
    }
  }

  Future<void> _onPartnerSelectionChanged(String? nextPartnerId) async {
    final series = _series;
    if (series == null || _lifecycleBusy || _isSaving) {
      return;
    }

    if (nextPartnerId == _selectedPartnerId) {
      return;
    }

    final previousSelection = _selectedPartnerId;
    final isUnassign = nextPartnerId == null;
    final confirmed = await confirmContentAction(
      context,
      title: isUnassign
          ? context.l10n.removePartnerAssignment
          : context.l10n.changePartnerAssignment,
      message: isUnassign
          ? context.l10n.unassignWarning
          : context.l10n.partnerChangeWarning,
      confirmLabel: isUnassign
          ? context.l10n.removeAssignment
          : context.l10n.changeAssignment,
    );

    if (!confirmed || !mounted) {
      setState(() => _selectedPartnerId = previousSelection);
      return;
    }

    // Deferred until Save — one Admin Save = one atomic content+partner transaction.
    setState(() {
      _selectedPartnerId = nextPartnerId;
      _errorMessage = null;
    });
  }

  Future<void> _reloadSeries() async {
    final fresh = await _seriesRepository.fetchById(widget.seriesId);
    if (!mounted) {
      return;
    }

    _applySeriesToForm(fresh);
    setState(() => _series = fresh);
    return;
  }

  Future<void> _saveChanges() async {
    final series = _series;
    if (series == null || _isSaving || _lifecycleBusy) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final partnerChanged = _selectedPartnerId != _loadedPartnerId;

    try {
      final result = await _mutationRepository.updateSeriesWithPartner(
        input: UpdateSeriesInput(
          seriesId: series.id,
          title: _titleController.text.trim(),
          synopsis: _synopsisController.text.trim(),
          status: _status.value,
          isFeatured: _isFeatured,
          isPremium: _isPremium,
          categoryIds: _selectedCategoryIds.toList(),
          expectedContentVersion: series.contentVersion,
          contentAgeRating: _contentAgeRating,
          contentDescriptors: ContentRatingCatalog.normalizeDescriptors(
            _contentDescriptors,
          ),
        ),
        partnerId: _selectedPartnerId,
        applyPartner: partnerChanged,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _series = result.applyTo(series);
        if (partnerChanged) {
          _loadedPartnerId = _selectedPartnerId;
        }
        _isSaving = false;
      });
      showContentSuccessSnackBar(context, context.l10n.seriesUpdated);
      if (partnerChanged) {
        await _loadAssignments();
      }
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isConflict) {
        await handleContentConflict<AdminSeries>(
          context: context,
          error: error,
          reloadFresh: () => _seriesRepository.fetchById(widget.seriesId),
          onFreshLoaded: (fresh) {
            setState(() {
              _series = fresh;
              _applySeriesToForm(fresh);
              _selectedPartnerId = _loadedPartnerId;
              _isSaving = false;
            });
          },
        );
        await _loadAssignments();
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _selectedPartnerId = _loadedPartnerId;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.seriesUpdateFailed;
        _selectedPartnerId = _loadedPartnerId;
        _isSaving = false;
      });
    }
  }

  Future<void> _pickPoster() async {
    if (_isPosterUploading || _lifecycleBusy) {
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      setState(() => _errorMessage = context.l10n.posterUnreadable);
      return;
    }

    try {
      final poster = PosterFileValidator.validate(
        bytes: bytes,
        fileName: picked.name,
      );
      setState(() {
        _newPosterFile = poster;
        _errorMessage = null;
      });
    } on PosterFileValidationException catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _replacePoster() async {
    final series = _series;
    final poster = _newPosterFile;
    if (series == null || poster == null || _isPosterUploading) {
      return;
    }

    setState(() {
      _isPosterUploading = true;
      _errorMessage = null;
    });

    try {
      final uploadInfo = await _imageUploadRepository.requestPosterUploadUrl(
        contentType: poster.contentType,
        fileSize: poster.sizeInBytes,
        purpose: 'series_poster_replacement',
        seriesId: series.id,
      );

      await _imageUploadRepository.uploadPoster(
        uploadInfo: uploadInfo,
        fileBytes: poster.bytes,
      );

      final result = await _mutationRepository.replacePoster(
        seriesId: series.id,
        posterPath: uploadInfo.objectPath,
        expectedContentVersion: series.contentVersion,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _series = series.copyWith(
          posterPath: result.posterPath,
          contentVersion: result.contentVersion,
          updatedAt: result.updatedAt,
        );
        _newPosterFile = null;
        _isPosterUploading = false;
      });
      showContentSuccessSnackBar(context, context.l10n.posterUpdated);
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isConflict) {
        await handleContentConflict<AdminSeries>(
          context: context,
          error: error,
          reloadFresh: () => _seriesRepository.fetchById(widget.seriesId),
          onFreshLoaded: (fresh) {
            setState(() {
              _series = fresh;
              _applySeriesToForm(fresh);
              _newPosterFile = null;
              _isPosterUploading = false;
            });
          },
        );
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isPosterUploading = false;
      });
    } on ImageUploadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isPosterUploading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.posterUpdateFailed;
        _isPosterUploading = false;
      });
    }
  }

  Future<void> _runLifecycle(Future<AdminSeries> Function() action) async {
    final series = _series;
    if (series == null ||
        _lifecycleBusy ||
        _isSaving ||
        _isPosterUploading ||
        !contentMutationsEnabled(context)) {
      return;
    }

    setState(() => _lifecycleBusy = true);

    try {
      final updated = await action();
      if (!mounted) {
        return;
      }

      setState(() {
        _series = updated;
        _applySeriesToForm(updated);
        _lifecycleBusy = false;
      });
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isConflict) {
        await handleContentConflict<AdminSeries>(
          context: context,
          error: error,
          reloadFresh: () => _seriesRepository.fetchById(widget.seriesId),
          onFreshLoaded: (fresh) {
            setState(() {
              _series = fresh;
              _applySeriesToForm(fresh);
              _lifecycleBusy = false;
            });
          },
        );
        return;
      }

      showContentErrorSnackBar(context, error.message);
      setState(() => _lifecycleBusy = false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      showContentErrorSnackBar(context, context.l10n.actionIncomplete);
      setState(() => _lifecycleBusy = false);
    }
  }

  Future<void> _publish() async {
    final series = _series;
    if (series == null) {
      return;
    }

    final confirmed = await confirmContentAction(
      context,
      title: context.l10n.publishSeries,
      message: context.l10n.publishSeriesConfirm,
      confirmLabel: context.l10n.publishSeries,
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _runLifecycle(() async {
      final result = await _mutationRepository.publishSeries(
        seriesId: series.id,
        expectedContentVersion: series.contentVersion,
      );
      if (mounted) {
        showContentSuccessSnackBar(context, context.l10n.seriesPublished);
      }
      return series.copyWith(
        isPublished: result.isPublished,
        isArchived: result.isArchived,
        contentVersion: result.contentVersion,
        updatedAt: result.updatedAt,
      );
    });
  }

  Future<void> _unpublish() async {
    final series = _series;
    if (series == null) {
      return;
    }

    final confirmed = await confirmContentAction(
      context,
      title: context.l10n.unpublish,
      message: context.l10n.unpublishSeriesConfirm,
      confirmLabel: context.l10n.unpublish,
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _runLifecycle(() async {
      final result = await _mutationRepository.unpublishSeries(
        seriesId: series.id,
        expectedContentVersion: series.contentVersion,
      );
      if (mounted) {
        showContentSuccessSnackBar(context, context.l10n.seriesUnpublished);
      }
      return series.copyWith(
        isPublished: result.isPublished,
        contentVersion: result.contentVersion,
        updatedAt: result.updatedAt,
      );
    });
  }

  Future<void> _archive() async {
    final series = _series;
    if (series == null) {
      return;
    }

    final confirmed = await confirmContentAction(
      context,
      title: context.l10n.archiveAction,
      message: context.l10n.archiveSeriesConfirm,
      confirmLabel: context.l10n.archiveAction,
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _runLifecycle(() async {
      final result = await _mutationRepository.archiveSeries(
        seriesId: series.id,
        expectedContentVersion: series.contentVersion,
      );
      if (mounted) {
        showContentSuccessSnackBar(context, context.l10n.seriesArchived);
      }
      return series.copyWith(
        isPublished: result.isPublished,
        isArchived: result.isArchived,
        contentVersion: result.contentVersion,
        updatedAt: result.updatedAt,
      );
    });
  }

  Future<void> _restore() async {
    final series = _series;
    if (series == null) {
      return;
    }

    final confirmed = await confirmContentAction(
      context,
      title: context.l10n.restore,
      message: context.l10n.restoreSeriesConfirm,
      confirmLabel: context.l10n.restore,
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _runLifecycle(() async {
      final result = await _mutationRepository.restoreSeries(
        seriesId: series.id,
        expectedContentVersion: series.contentVersion,
      );
      if (mounted) {
        showContentSuccessSnackBar(context, context.l10n.seriesRestored);
      }
      return series.copyWith(
        isArchived: result.isArchived,
        contentVersion: result.contentVersion,
        updatedAt: result.updatedAt,
      );
    });
  }

  void _openEpisodes() {
    final series = _series;
    if (series == null) {
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => SeriesEpisodesPage(
              seriesId: series.id,
              seriesTitle: series.title,
              initialSeries: series,
              isSeriesArchived: series.isArchived,
            ),
          ),
        )
        .then((_) => _reloadSeries());
  }

  @override
  Widget build(BuildContext context) {
    final series = _series;
    final mutationsEnabled = contentMutationsEnabled(context);
    final busy =
        _isSaving || _isPosterUploading || _lifecycleBusy || !mutationsEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          series?.title ??
              _placeholderSeries?.title ??
              context.l10n.seriesDetail,
        ),
        actions: [
          if (series != null)
            TextButton.icon(
              onPressed: busy ? null : _openEpisodes,
              icon: const Icon(Icons.playlist_play_outlined, size: 18),
              label: Text(context.l10n.navEpisodes),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : series == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage ?? context.l10n.seriesNotFound),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _loadSeries(),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SeriesMetaHeader(series: series),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _PosterSection(
                        series: series,
                        newPoster: _newPosterFile,
                        isUploading: _isPosterUploading,
                        onPick: _pickPoster,
                        onReplace: _replacePoster,
                        disabled: busy,
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: _EditSection(
                          titleController: _titleController,
                          synopsisController: _synopsisController,
                          status: _status,
                          isFeatured: _isFeatured,
                          isPremium: _isPremium,
                          selectedCategoryIds: _selectedCategoryIds,
                          categoriesFuture: _categoriesFuture,
                          contentAgeRating: _contentAgeRating,
                          contentDescriptors: _contentDescriptors,
                          disabled: busy || series.isArchived,
                          onStatusChanged: (value) =>
                              setState(() => _status = value),
                          onFeaturedChanged: (value) =>
                              setState(() => _isFeatured = value),
                          onPremiumChanged: (value) =>
                              setState(() => _isPremium = value),
                          onContentAgeChanged: (value) =>
                              setState(() => _contentAgeRating = value),
                          onContentDescriptorsChanged: (value) =>
                              setState(() => _contentDescriptors = value),
                          onCategoryToggle: (id, selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategoryIds.add(id);
                              } else {
                                _selectedCategoryIds.remove(id);
                              }
                            });
                          },
                          onReloadCategories: () {
                            setState(() {
                              _categoriesFuture = _categoryRepository
                                  .fetchAll();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PartnerAssignmentSection(
                        selectedPartnerId: _selectedPartnerId,
                        enabled: !busy && !series.isArchived,
                        repository: _partnerRepository,
                        onChanged: _onPartnerSelectionChanged,
                      ),
                      const SizedBox(height: 24),
                      PartnerAssignmentHistoryPanel(
                        assignments: _assignments,
                        isLoading: _assignmentsLoading,
                        errorMessage: _assignmentsError,
                        onRetry: _loadAssignments,
                      ),
                      const SizedBox(height: 24),
                      _LifecycleSection(
                        series: series,
                        busy: busy,
                        onPublish: _publish,
                        onUnpublish: _unpublish,
                        onArchive: _archive,
                        onRestore: _restore,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: busy || series.isArchived
                            ? null
                            : _saveChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.l10n.saveChanges),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PartnerAssignmentSection extends StatelessWidget {
  const _PartnerAssignmentSection({
    required this.selectedPartnerId,
    required this.enabled,
    required this.repository,
    required this.onChanged,
  });

  final String? selectedPartnerId;
  final bool enabled;
  final PartnerRepository repository;
  final ValueChanged<String?> onChanged;

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
            Text(
              context.l10n.collaborationPartner,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.partnerChangeClosesAssignment,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
            const SizedBox(height: 16),
            PartnerSelector(
              selectedPartnerId: selectedPartnerId,
              enabled: enabled,
              repository: repository,
              label: context.l10n.collaborationPartner,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesMetaHeader extends StatelessWidget {
  const _SeriesMetaHeader({required this.series});

  final AdminSeries series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(series.slug, style: const TextStyle(color: Color(0xFF777777))),
        _Badge(
          label: adminPublishDisplayLabel(context.l10n, series.publishLabel),
          color: series.isPublished
              ? const Color(0xFF35C46A)
              : const Color(0xFF888888),
        ),
        _Badge(
          label: adminArchiveDisplayLabel(context.l10n, series.archiveLabel),
          color: series.isArchived
              ? const Color(0xFFE5A000)
              : const Color(0xFF555555),
        ),
        _Badge(
          label: adminSeriesStatusLabel(context.l10n, series.statusLabel),
          color: const Color(0xFF555555),
        ),
        _Badge(
          label: context.l10n.qualifiedViewsCount(series.qualifiedViewsTotal),
          color: const Color(0xFF3D5AFE),
        ),
        Text(
          context.l10n.episodeCountLabel(series.episodeCount),
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
      ],
    );
  }
}

class _PosterSection extends StatelessWidget {
  const _PosterSection({
    required this.series,
    required this.newPoster,
    required this.isUploading,
    required this.onPick,
    required this.onReplace,
    required this.disabled,
  });

  final AdminSeries series;
  final PosterFile? newPoster;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onReplace;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final posterUrl = MediaConfig.resolvePosterUrl(series.posterPath);

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
              context.l10n.poster,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 112,
                    height: 160,
                    child: newPoster != null
                        ? Image.memory(newPoster!.bytes, fit: BoxFit.cover)
                        : posterUrl == null
                        ? const ColoredBox(
                            color: Color(0xFF181818),
                            child: Center(
                              child: Icon(
                                Icons.movie_outlined,
                                color: Color(0xFF555555),
                              ),
                            ),
                          )
                        : Image.network(posterUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: disabled ? null : onPick,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(context.l10n.selectNewPoster),
                      ),
                      if (newPoster != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          newPoster!.fileName,
                          style: const TextStyle(color: Color(0xFFB3B3B3)),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: disabled || isUploading ? null : onReplace,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE50914),
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(context.l10n.changePoster),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.titleController,
    required this.synopsisController,
    required this.status,
    required this.isFeatured,
    required this.isPremium,
    required this.selectedCategoryIds,
    required this.categoriesFuture,
    required this.contentAgeRating,
    required this.contentDescriptors,
    required this.disabled,
    required this.onStatusChanged,
    required this.onFeaturedChanged,
    required this.onPremiumChanged,
    required this.onContentAgeChanged,
    required this.onContentDescriptorsChanged,
    required this.onCategoryToggle,
    required this.onReloadCategories,
  });

  final TextEditingController titleController;
  final TextEditingController synopsisController;
  final SeriesStatusValue status;
  final bool isFeatured;
  final bool isPremium;
  final Set<String> selectedCategoryIds;
  final Future<List<AdminCategory>> categoriesFuture;
  final int? contentAgeRating;
  final List<String> contentDescriptors;
  final bool disabled;
  final ValueChanged<SeriesStatusValue> onStatusChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onPremiumChanged;
  final ValueChanged<int?> onContentAgeChanged;
  final ValueChanged<List<String>> onContentDescriptorsChanged;
  final void Function(String id, bool selected) onCategoryToggle;
  final VoidCallback onReloadCategories;

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
            Text(
              context.l10n.seriesInfo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              enabled: !disabled,
              decoration: InputDecoration(
                labelText: context.l10n.titleRequiredStar,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.titleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: synopsisController,
              enabled: !disabled,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: context.l10n.description,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ContentRatingEditor(
              ageRating: contentAgeRating,
              descriptors: contentDescriptors,
              enabled: !disabled,
              onAgeChanged: onContentAgeChanged,
              onDescriptorsChanged: onContentDescriptorsChanged,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(labelText: context.l10n.status),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SeriesStatusValue>(
                  value: status,
                  isExpanded: true,
                  items: [
                    for (final item in SeriesStatusValue.values)
                      DropdownMenuItem(
                        value: item,
                        child: Text(
                          adminSeriesStatusLabel(context.l10n, item.value),
                        ),
                      ),
                  ],
                  onChanged: disabled
                      ? null
                      : (value) {
                          if (value != null) {
                            onStatusChanged(value);
                          }
                        },
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.featured),
              value: isFeatured,
              onChanged: disabled ? null : onFeaturedChanged,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.premium),
              value: isPremium,
              onChanged: disabled ? null : onPremiumChanged,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.categories),
            const SizedBox(height: 8),
            FutureBuilder<List<AdminCategory>>(
              future: categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.categoriesLoadFailed,
                        style: const TextStyle(color: Color(0xFFFFB4B4)),
                      ),
                      OutlinedButton(
                        onPressed: disabled ? null : onReloadCategories,
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  );
                }

                final categories = snapshot.data ?? const [];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categories)
                      FilterChip(
                        label: Text(category.name),
                        selected: selectedCategoryIds.contains(category.id),
                        onSelected: disabled
                            ? null
                            : (selected) =>
                                  onCategoryToggle(category.id, selected),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LifecycleSection extends StatelessWidget {
  const _LifecycleSection({
    required this.series,
    required this.busy,
    required this.onPublish,
    required this.onUnpublish,
    required this.onArchive,
    required this.onRestore,
  });

  final AdminSeries series;
  final bool busy;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

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
              context.l10n.publishAndArchive,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (!series.isArchived && !series.isPublished)
                  FilledButton(
                    onPressed: busy ? null : onPublish,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF35C46A),
                    ),
                    child: Text(context.l10n.publishSeries),
                  ),
                if (!series.isArchived && series.isPublished)
                  OutlinedButton(
                    onPressed: busy ? null : onUnpublish,
                    child: Text(context.l10n.unpublish),
                  ),
                if (!series.isArchived)
                  OutlinedButton(
                    onPressed: busy ? null : onArchive,
                    child: Text(context.l10n.archiveAction),
                  ),
                if (series.isArchived)
                  FilledButton(
                    onPressed: busy ? null : onRestore,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                    ),
                    child: Text(context.l10n.restore),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.4),
        ),
      ),
      child: SelectableText(
        message,
        style: const TextStyle(color: Color(0xFFFFB4B4)),
      ),
    );
  }
}

/// Lifecycle button labels currently visible for [series].
List<String> seriesLifecycleActionLabels(AdminSeries series) {
  final labels = <String>[];

  if (!series.isArchived && !series.isPublished) {
    labels.add('Yayınla');
  }
  if (!series.isArchived && series.isPublished) {
    labels.add('Yayından Kaldır');
  }
  if (!series.isArchived) {
    labels.add('Arşivle');
  }
  if (series.isArchived) {
    labels.add('Geri Yükle');
  }

  return labels;
}
