import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';
import '../../episodes/data/episode_repository.dart';
import '../../media/data/image_upload_repository.dart';
import '../../series/data/series_repository.dart';
import '../application/campaign_destination_controller.dart';
import '../application/campaign_image_controller.dart';
import '../data/campaign_repository.dart';
import '../domain/admin_campaign.dart';
import '../domain/campaign_destination.dart';
import 'campaign_destination_fields.dart';
import 'locale_translation_fields.dart';

/// Supported Vidxon app locales for campaign targeting.
const List<String> kSupportedLocales = VidxonProductLocales.all;

class PopupCampaignFormDialog extends StatefulWidget {
  const PopupCampaignFormDialog({
    super.key,
    required this.repository,
    this.existing,
    this.imageUploadRepository,
    this.imageController,
    this.filePicker,
    this.seriesRepository,
    this.episodeRepository,
  });

  final CampaignRepository repository;
  final AdminCampaign? existing;
  final ImageUploadRepository? imageUploadRepository;
  final CampaignImageController? imageController;
  final Future<({Uint8List bytes, String fileName})?> Function()? filePicker;
  final SeriesRepository? seriesRepository;
  final EpisodeRepository? episodeRepository;

  @override
  State<PopupCampaignFormDialog> createState() =>
      _PopupCampaignFormDialogState();
}

class _PopupCampaignFormDialogState extends State<PopupCampaignFormDialog> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  late final CampaignImageController _imageController;
  late final CampaignDestinationController _destinationController;
  late final TextEditingController _priorityController;

  late String _destinationType;
  late bool _isActive;
  late DateTime _startsAt;
  DateTime? _endsAt;
  late Set<String> _selectedLocales;

  /// Per-locale translation controllers: locale -> {title, description, cta}
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};
  final Map<String, TextEditingController> _ctaControllers = {};

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _imageController =
        widget.imageController ??
        CampaignImageController(
          imageUploadRepository: widget.imageUploadRepository,
          initialObjectPath: e?.imagePath,
        );
    _priorityController = TextEditingController(
      text: (e?.priority ?? CampaignPriority.defaultValue).toString(),
    );
    _destinationType = e?.destinationType ?? CampaignDestinationType.none;
    _destinationController = CampaignDestinationController(
      seriesRepository: widget.seriesRepository ?? SeriesRepository(),
      episodeRepository: widget.episodeRepository ?? EpisodeRepository(),
      destinationType: _destinationType,
      initialSeriesId: e?.destinationSeriesId,
      initialEpisodeId: e?.destinationEpisodeId,
    );
    _destinationController.initialize();
    _isActive = e?.isActive ?? false;
    _startsAt = e?.startsAt ?? DateTime.now();
    _endsAt = e?.endsAt;

    _selectedLocales = e != null ? Set<String>.from(e.targetLocales) : {'tr'};

    // Initialize translation controllers
    for (final locale in kSupportedLocales) {
      final existing = e?.translations
          .where((t) => t.locale == locale)
          .firstOrNull;
      _titleControllers[locale] = TextEditingController(
        text: existing?.title ?? '',
      );
      _descriptionControllers[locale] = TextEditingController(
        text: existing?.description ?? '',
      );
      _ctaControllers[locale] = TextEditingController(
        text: existing?.ctaLabel ?? '',
      );
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _priorityController.dispose();
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _descriptionControllers.values) {
      c.dispose();
    }
    for (final c in _ctaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_imageController.canSave) {
      setState(() {
        _errorMessage = _imageController.uploading
            ? 'Görsel yükleniyor, lütfen bekleyin.'
            : (_imageController.errorMessage ??
                  'Görsel yüklemesi tamamlanmadan kaydedilemez.');
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final translations = _selectedLocales.map((locale) {
        return AdminCampaignTranslation(
          locale: locale,
          title: _titleControllers[locale]!.text.trim(),
          description: _descriptionControllers[locale]!.text.trim(),
          ctaLabel: _ctaControllers[locale]!.text.trim().isEmpty
              ? null
              : _ctaControllers[locale]!.text.trim(),
        );
      }).toList();

      await widget.repository.upsert(
        id: widget.existing?.id,
        imagePath: _imageController.objectPath?.trim() ?? '',
        destinationType: _destinationType,
        destinationSeriesId: _destinationController.seriesIdForSave,
        destinationEpisodeId: _destinationController.episodeIdForSave,
        targetLocales: _selectedLocales.toList(),
        isActive: _isActive,
        priority: CampaignPriority.parseOrDefault(_priorityController.text),
        startsAt: _startsAt,
        endsAt: _endsAt,
        translations: translations,
      );

      if (mounted) Navigator.of(context).pop(true);
    } on CampaignException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startsAt : (_endsAt ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startsAt = dt;
      } else {
        _endsAt = dt;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing ? 'Pop-up Düzenle' : 'Yeni Pop-up',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // === Genel ===
                _sectionLabel('Görsel'),
                _CampaignImageField(
                  controller: _imageController,
                  onPick: _pickAndUploadImage,
                  onChanged: () => setState(() {}),
                ),
                if (_imageController.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _imageController.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 12),

                CampaignDestinationFields(
                  controller: _destinationController,
                  destinationType: _destinationType,
                  onDestinationTypeChanged: (type) {
                    setState(() => _destinationType = type);
                    _destinationController.setDestinationType(type);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  key: const Key('campaign-priority-field'),
                  controller: _priorityController,
                  decoration: const InputDecoration(
                    labelText: CampaignPriority.label,
                    helperText: CampaignPriority.helperText,
                    helperMaxLines: 4,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // === Diller ===
                _sectionLabel('Hedef Diller'),
                Wrap(
                  spacing: 8,
                  children: kSupportedLocales.map((locale) {
                    final selected = _selectedLocales.contains(locale);
                    return FilterChip(
                      label: Text(VidxonProductLocales.displayName(locale)),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedLocales.add(locale);
                          } else if (_selectedLocales.length > 1) {
                            _selectedLocales.remove(locale);
                          }
                        });
                      },
                      selectedColor: _primaryColor.withValues(alpha: 0.3),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Per-locale translation fields
                ..._selectedLocales.map((locale) {
                  return LocaleTranslationFields(
                    locale: locale,
                    titleController: _titleControllers[locale]!,
                    descriptionController: _descriptionControllers[locale]!,
                    ctaController: _ctaControllers[locale]!,
                    ctaRequired: _destinationType != 'none',
                  );
                }),

                // === Zamanlama ===
                _sectionLabel('Zamanlama'),
                Row(
                  children: [
                    Expanded(
                      child: _DateTimeField(
                        label: 'Başlangıç',
                        value: _startsAt,
                        onTap: () => _pickDateTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTimeField(
                        label: 'Bitiş (opsiyonel)',
                        value: _endsAt,
                        onTap: () => _pickDateTime(isStart: false),
                      ),
                    ),
                    if (_endsAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _endsAt = null),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeTrackColor: _primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Güncelle' : 'Oluştur'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      Uint8List bytes;
      String fileName;
      final injected = widget.filePicker;
      if (injected != null) {
        final picked = await injected();
        if (picked == null || !mounted) return;
        bytes = picked.bytes;
        fileName = picked.fileName;
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
          withData: true,
          allowMultiple: false,
        );
        if (!mounted || result == null || result.files.isEmpty) return;
        final file = result.files.single;
        if (file.bytes == null) {
          setState(() {
            _imageController.errorMessage = 'Görsel dosyası okunamadı.';
          });
          return;
        }
        bytes = file.bytes!;
        fileName = file.name;
      }

      setState(() {
        _imageController.uploading = true;
        _imageController.errorMessage = null;
      });
      await _imageController.applyPickedBytes(bytes: bytes, fileName: fileName);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageController.uploading = false;
          _imageController.errorMessage = 'Görsel yüklenemedi.';
        });
      }
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CampaignImageField extends StatelessWidget {
  const _CampaignImageField({
    required this.controller,
    required this.onPick,
    required this.onChanged,
  });

  final CampaignImageController controller;
  final Future<void> Function() onPick;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: controller.uploading
              ? const Center(child: CircularProgressIndicator())
              : controller.previewBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    controller.previewBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 140,
                    errorBuilder: (_, error, stackTrace) => const Center(
                      child: Icon(Icons.image, color: Colors.white70, size: 48),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    controller.hasImage
                        ? 'Görsel yüklendi'
                        : 'Görsel seçilmedi (opsiyonel)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: controller.uploading ? null : onPick,
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(
                controller.hasImage ? 'Görseli Değiştir' : 'Görsel Yükle',
              ),
            ),
            if (controller.hasImage || controller.previewBytes != null)
              TextButton(
                onPressed: controller.uploading
                    ? null
                    : () {
                        controller.remove();
                        onChanged();
                      },
                child: const Text('Görseli Kaldır'),
              ),
          ],
        ),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = value != null
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} '
              '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
        : '—';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(formatted),
      ),
    );
  }
}
