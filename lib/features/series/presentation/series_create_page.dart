import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/slug_helper.dart';
import '../../../l10n/admin_l10n.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../../content_rating/domain/content_rating_catalog.dart';
import '../../content_rating/presentation/content_rating_editor.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/admin_category.dart';
import '../../media/data/image_upload_repository.dart';
import '../../media/domain/poster_file.dart';
import '../../partners/data/partner_errors.dart';
import '../../partners/data/partner_repository.dart';
import '../../partners/presentation/partner_selector.dart';
import '../data/series_mutation_repository.dart';
import '../domain/admin_series.dart';
import '../domain/create_series_input.dart';

enum SeriesStatusValue {
  ongoing('ongoing', 'Devam Ediyor'),
  completed('completed', 'Tamamlandı'),
  comingSoon('coming_soon', 'Yakında');

  const SeriesStatusValue(this.value, this.label);

  final String value;
  final String label;
}

enum _SubmitStage {
  validating('Form doğrulanıyor'),
  preparingUpload('Yükleme bağlantısı hazırlanıyor'),
  uploadingPoster('Poster yükleniyor'),
  savingSeries('Dizi kaydediliyor');

  const _SubmitStage(this.label);

  final String label;
}

class SeriesCreatePage extends StatefulWidget {
  const SeriesCreatePage({
    required this.onCancel,
    required this.onSuccess,
    this.seriesMutationRepository,
    this.imageUploadRepository,
    this.categoryRepository,
    this.partnerRepository,
    this.initialPosterForTesting,
    super.key,
  });

  final VoidCallback onCancel;
  final void Function(AdminSeries created) onSuccess;
  final SeriesMutationRepository? seriesMutationRepository;
  final ImageUploadRepository? imageUploadRepository;
  final CategoryRepository? categoryRepository;
  final PartnerRepository? partnerRepository;
  final PosterFile? initialPosterForTesting;

  @override
  State<SeriesCreatePage> createState() => _SeriesCreatePageState();
}

class _SeriesCreatePageState extends State<SeriesCreatePage> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _synopsisController = TextEditingController();

  late final CategoryRepository _categoryRepository =
      widget.categoryRepository ?? CategoryRepository();
  late final ImageUploadRepository _imageUploadRepository =
      widget.imageUploadRepository ?? ImageUploadRepository();
  late final SeriesMutationRepository _seriesMutationRepository =
      widget.seriesMutationRepository ?? SeriesMutationRepository();
  late final PartnerRepository _partnerRepository =
      widget.partnerRepository ?? PartnerRepository();

  late Future<List<AdminCategory>> _categoriesFuture;

  bool _slugEditedManually = false;
  bool _isSubmitting = false;
  _SubmitStage? _submitStage;
  String? _selectedPartnerId;

  SeriesStatusValue _status = SeriesStatusValue.ongoing;
  bool _isFeatured = false;
  bool _isPremium = false;
  DateTime? _releaseDate;
  final Set<String> _selectedCategoryIds = {};
  int? _contentAgeRating;
  List<String> _contentDescriptors = [];

  PosterFile? _posterFile;
  String? _uploadedPosterFingerprint;
  String? _uploadedObjectPath;

  String? _errorMessage;
  String? _retryHint;

  @override
  void initState() {
    super.initState();
    _posterFile = widget.initialPosterForTesting;
    _categoriesFuture = _categoryRepository.fetchAll();
    _titleController.addListener(_onTitleChanged);
    _slugController.addListener(_onSlugChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_onTitleChanged)
      ..dispose();
    _slugController
      ..removeListener(_onSlugChanged)
      ..dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (_slugEditedManually) {
      return;
    }

    final generated = SlugHelper.generateFromTitle(_titleController.text);
    _slugController
      ..removeListener(_onSlugChanged)
      ..text = generated
      ..addListener(_onSlugChanged);
  }

  void _onSlugChanged() {
    _slugEditedManually = true;
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = _categoryRepository.fetchAll();
    });
  }

  Future<void> _pickPoster() async {
    if (_isSubmitting) {
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
      setState(() {
        _errorMessage = context.l10n.posterUnreadable;
        _retryHint = null;
      });
      return;
    }

    try {
      final poster = PosterFileValidator.validate(
        bytes: bytes,
        fileName: picked.name,
      );

      setState(() {
        _posterFile = poster;
        _uploadedPosterFingerprint = null;
        _uploadedObjectPath = null;
        _errorMessage = null;
        _retryHint = null;
      });
    } on PosterFileValidationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _retryHint = null;
      });
    }
  }

  String _posterFingerprint(PosterFile poster) {
    return '${poster.fileName}|${poster.contentType}|${poster.sizeInBytes}';
  }

  Future<void> _submit() async {
    if (_isSubmitting || !contentMutationsEnabled(context)) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _retryHint = null;
      _submitStage = _SubmitStage.validating;
      _isSubmitting = true;
    });

    if (!_formKey.currentState!.validate()) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _submitStage = null;
      });
      return;
    }

    final poster = _posterFile;
    if (poster == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.posterRequired;
        _isSubmitting = false;
        _submitStage = null;
      });
      return;
    }

    try {
      final fingerprint = _posterFingerprint(poster);
      var objectPath = _uploadedObjectPath;

      if (objectPath == null || _uploadedPosterFingerprint != fingerprint) {
        if (!mounted) {
          return;
        }

        setState(() {
          _submitStage = _SubmitStage.preparingUpload;
        });

        final uploadInfo = await _imageUploadRepository.requestPosterUploadUrl(
          contentType: poster.contentType,
          fileSize: poster.sizeInBytes,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _submitStage = _SubmitStage.uploadingPoster;
        });

        await _imageUploadRepository.uploadPoster(
          uploadInfo: uploadInfo,
          fileBytes: poster.bytes,
        );

        objectPath = uploadInfo.objectPath;
        _uploadedPosterFingerprint = fingerprint;
        _uploadedObjectPath = uploadInfo.objectPath;
      }

      final posterPath = objectPath;
      if (!mounted) {
        return;
      }

      if (posterPath.isEmpty) {
        throw ImageUploadException(context.l10n.posterPathFailed);
      }

      setState(() {
        _submitStage = _SubmitStage.savingSeries;
      });

      final releaseDate = _releaseDate == null
          ? null
          : _formatReleaseDate(_releaseDate!);

      final partnerId = _selectedPartnerId;
      final created = await _seriesMutationRepository.createSeriesWithPartner(
        input: CreateSeriesInput(
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          posterPath: posterPath,
          synopsis: _synopsisController.text.trim(),
          status: _status.value,
          isFeatured: _isFeatured,
          isPremium: _isPremium,
          releaseDate: releaseDate,
          categoryIds: _selectedCategoryIds.toList(),
          contentAgeRating: _contentAgeRating,
          contentDescriptors: ContentRatingCatalog.normalizeDescriptors(
            _contentDescriptors,
          ),
        ),
        partnerId: partnerId != null && partnerId.isNotEmpty ? partnerId : null,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.seriesCreated),
          backgroundColor: const Color(0xFF35C46A),
        ),
      );

      widget.onSuccess(created);
    } on ImageUploadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _retryHint = null;
        _isSubmitting = false;
        _submitStage = null;
      });
    } on SeriesMutationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _retryHint = context.l10n.posterAlreadyUploadedRetry;
        _isSubmitting = false;
        _submitStage = null;
      });
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.seriesCreatedPartnerFailed(error.message);
        _retryHint = context.l10n.seriesCreatedRetryPartner;
        _isSubmitting = false;
        _submitStage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.unexpectedRetry;
        _retryHint = _uploadedObjectPath == null
            ? null
            : context.l10n.posterAlreadyUploaded;
        _isSubmitting = false;
        _submitStage = null;
      });
    }
  }

  Future<void> _pickReleaseDate() async {
    if (_isSubmitting) {
      return;
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _releaseDate = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_submitStage != null) _buildProgressBanner(),
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 16),
                ],
                _buildBasicFields(),
                const SizedBox(height: 24),
                _buildContentRatingSection(),
                const SizedBox(height: 24),
                _buildPosterSection(),
                const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 24),
                _buildPartnerSection(),
                const SizedBox(height: 24),
                _buildCategorySection(),
                const SizedBox(height: 32),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.newSeries,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.newSeriesSubtitle,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
      ],
    );
  }

  Widget _buildProgressBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(switch (_submitStage!) {
              _SubmitStage.validating => context.l10n.validatingForm,
              _SubmitStage.preparingUpload => context.l10n.preparingUploadLink,
              _SubmitStage.uploadingPoster => context.l10n.uploadingPoster,
              _SubmitStage.savingSeries => context.l10n.savingSeries,
            }, style: const TextStyle(color: Color(0xFFB3B3B3))),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFFFB4B4)),
          ),
          if (_retryHint != null) ...[
            const SizedBox(height: 8),
            Text(
              _retryHint!,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicFields() {
    return _SectionCard(
      title: context.l10n.basicInfo,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            enabled: !_isSubmitting,
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
            controller: _slugController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: context.l10n.slugRequiredStar,
              helperText: context.l10n.slugHint,
            ),
            validator: (value) {
              final slug = value?.trim() ?? '';
              if (!SlugHelper.isValid(slug)) {
                return context.l10n.validSlug;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _synopsisController,
            enabled: !_isSubmitting,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: context.l10n.description,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.l10n.releaseDate,
                  ),
                  child: Text(
                    _releaseDate == null
                        ? context.l10n.notSelected
                        : _formatReleaseDate(_releaseDate!),
                    style: TextStyle(
                      color: _releaseDate == null
                          ? const Color(0xFF777777)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isSubmitting ? null : _pickReleaseDate,
                child: Text(context.l10n.selectDate),
              ),
              if (_releaseDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: context.l10n.clear,
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _releaseDate = null;
                          });
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentRatingSection() {
    return _SectionCard(
      title: context.l10n.contentRating,
      child: ContentRatingEditor(
        ageRating: _contentAgeRating,
        descriptors: _contentDescriptors,
        enabled: !_isSubmitting,
        showSectionTitle: false,
        onAgeChanged: (value) {
          setState(() => _contentAgeRating = value);
        },
        onDescriptorsChanged: (value) {
          setState(() => _contentDescriptors = value);
        },
      ),
    );
  }

  Widget _buildPosterSection() {
    final poster = _posterFile;

    return _SectionCard(
      title: context.l10n.posterRequiredStar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickPoster,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(context.l10n.selectPoster),
              ),
              if (poster != null)
                Text(
                  '${poster.fileName} · ${poster.contentType} · ${_formatFileSize(poster.sizeInBytes)}',
                  style: const TextStyle(color: Color(0xFFB3B3B3)),
                ),
            ],
          ),
          if (poster != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                poster.bytes,
                width: 160,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _posterPlaceholder();
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            _posterPlaceholder(),
          ],
          const SizedBox(height: 8),
          Text(
            context.l10n.posterFormatsHint,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 160,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Center(
        child: Icon(Icons.movie_outlined, size: 48, color: Color(0xFF555555)),
      ),
    );
  }

  Widget _buildStatusSection() {
    return _SectionCard(
      title: context.l10n.publishSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: InputDecoration(labelText: context.l10n.status),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SeriesStatusValue>(
                value: _status,
                isExpanded: true,
                items: [
                  for (final status in SeriesStatusValue.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(
                        adminSeriesStatusLabel(context.l10n, status.value),
                      ),
                    ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.featured),
            value: _isFeatured,
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _isFeatured = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.premium),
            value: _isPremium,
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _isPremium = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSection() {
    return _SectionCard(
      title: context.l10n.collaborationPartner,
      child: PartnerSelector(
        selectedPartnerId: _selectedPartnerId,
        enabled: !_isSubmitting,
        repository: _partnerRepository,
        label: context.l10n.collaborationPartner,
        onChanged: (value) {
          setState(() => _selectedPartnerId = value);
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    return _SectionCard(
      title: context.l10n.categories,
      child: FutureBuilder<List<AdminCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.categoriesLoadFailed,
                  style: const TextStyle(color: Color(0xFFFFB4B4)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _reloadCategories,
                  child: Text(context.l10n.retry),
                ),
              ],
            );
          }

          final categories = snapshot.data ?? const [];

          if (categories.isEmpty) {
            return Text(
              context.l10n.noCategoriesYet,
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                FilterChip(
                  label: Text(category.name),
                  selected: _selectedCategoryIds.contains(category.id),
                  onSelected: _isSubmitting
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : widget.onCancel,
          child: Text(context.l10n.cancel),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.l10n.createSeries),
        ),
      ],
    );
  }

  static String _formatReleaseDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    }
    return '$bytes B';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
