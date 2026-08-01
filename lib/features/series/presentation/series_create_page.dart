import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/slug_helper.dart';
import '../../content/presentation/content_mutation_guard.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/admin_category.dart';
import '../../media/data/image_upload_repository.dart';
import '../../media/domain/poster_file.dart';
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
    this.initialPosterForTesting,
    super.key,
  });

  final VoidCallback onCancel;
  final void Function(AdminSeries created) onSuccess;
  final SeriesMutationRepository? seriesMutationRepository;
  final ImageUploadRepository? imageUploadRepository;
  final CategoryRepository? categoryRepository;
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

  late Future<List<AdminCategory>> _categoriesFuture;

  bool _slugEditedManually = false;
  bool _isSubmitting = false;
  _SubmitStage? _submitStage;

  SeriesStatusValue _status = SeriesStatusValue.ongoing;
  bool _isFeatured = false;
  bool _isPremium = false;
  DateTime? _releaseDate;
  final Set<String> _selectedCategoryIds = {};

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
        _errorMessage = 'Poster dosyası okunamadı.';
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
        _errorMessage = 'Poster seçimi zorunludur.';
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
      if (posterPath.isEmpty) {
        throw ImageUploadException('Poster yolu oluşturulamadı.');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _submitStage = _SubmitStage.savingSeries;
      });

      final releaseDate = _releaseDate == null
          ? null
          : _formatReleaseDate(_releaseDate!);

      final created = await _seriesMutationRepository.createSeries(
        CreateSeriesInput(
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          posterPath: posterPath,
          synopsis: _synopsisController.text.trim(),
          status: _status.value,
          isFeatured: _isFeatured,
          isPremium: _isPremium,
          releaseDate: releaseDate,
          categoryIds: _selectedCategoryIds.toList(),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dizi başarıyla oluşturuldu.'),
          backgroundColor: Color(0xFF35C46A),
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
        _retryHint =
            'Poster zaten yüklendi. Bilgileri düzenleyip tekrar deneyebilirsiniz.';
        _isSubmitting = false;
        _submitStage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
        _retryHint = _uploadedObjectPath == null
            ? null
            : 'Poster zaten yüklendi. Tekrar deneyebilirsiniz.';
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
                _buildPosterSection(),
                const SizedBox(height: 24),
                _buildStatusSection(),
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
          'Yeni Dizi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kataloga yeni bir dizi ekleyin',
          style: TextStyle(color: Color(0xFFB3B3B3)),
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
            child: Text(
              _submitStage!.label,
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            ),
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
      title: 'Temel Bilgiler',
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(labelText: 'Başlık *'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Başlık zorunludur.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _slugController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Slug *',
              helperText: 'Küçük harf, rakam ve tire',
            ),
            validator: (value) {
              final slug = value?.trim() ?? '';
              if (!SlugHelper.isValid(slug)) {
                return 'Geçerli bir slug girin.';
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
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Yayın Tarihi'),
                  child: Text(
                    _releaseDate == null
                        ? 'Seçilmedi'
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
                child: const Text('Tarih Seç'),
              ),
              if (_releaseDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Temizle',
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

  Widget _buildPosterSection() {
    final poster = _posterFile;

    return _SectionCard(
      title: 'Poster *',
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
                label: const Text('Poster Seç'),
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
          const Text(
            'JPG, PNG veya WEBP · En fazla 10 MiB',
            style: TextStyle(color: Color(0xFF777777), fontSize: 12),
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
      title: 'Yayın Ayarları',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Durum'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SeriesStatusValue>(
                value: _status,
                isExpanded: true,
                items: [
                  for (final status in SeriesStatusValue.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
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
            title: const Text('Öne Çıkan'),
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
            title: const Text('Premium'),
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

  Widget _buildCategorySection() {
    return _SectionCard(
      title: 'Kategoriler',
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
                const Text(
                  'Kategoriler yüklenemedi.',
                  style: TextStyle(color: Color(0xFFFFB4B4)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _reloadCategories,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            );
          }

          final categories = snapshot.data ?? const [];

          if (categories.isEmpty) {
            return const Text(
              'Henüz kategori bulunmuyor.',
              style: TextStyle(color: Color(0xFFB3B3B3)),
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
          child: const Text('İptal'),
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
              : const Text('Diziyi Oluştur'),
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
