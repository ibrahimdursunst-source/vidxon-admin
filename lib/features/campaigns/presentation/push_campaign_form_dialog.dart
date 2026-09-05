import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';
import '../../episodes/data/episode_repository.dart';
import '../../series/data/series_repository.dart';
import '../application/campaign_destination_controller.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import '../domain/campaign_destination.dart';
import 'campaign_destination_fields.dart';
import 'locale_translation_fields.dart';
import 'popup_campaign_form_dialog.dart' show kSupportedLocales;

class PushCampaignFormDialog extends StatefulWidget {
  const PushCampaignFormDialog({
    super.key,
    required this.repository,
    this.existing,
    this.seriesRepository,
    this.episodeRepository,
  });

  final PushCampaignRepository repository;
  final AdminPushCampaign? existing;
  final SeriesRepository? seriesRepository;
  final EpisodeRepository? episodeRepository;

  @override
  State<PushCampaignFormDialog> createState() => _PushCampaignFormDialogState();
}

class _PushCampaignFormDialogState extends State<PushCampaignFormDialog> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  late final CampaignDestinationController _destinationController;

  late String _destinationType;
  late Set<String> _selectedLocales;
  DateTime? _scheduledAt;

  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _bodyControllers = {};

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _destinationType = e?.destinationType ?? CampaignDestinationType.none;
    _destinationController = CampaignDestinationController(
      seriesRepository: widget.seriesRepository ?? SeriesRepository(),
      episodeRepository: widget.episodeRepository ?? EpisodeRepository(),
      destinationType: _destinationType,
      initialSeriesId: e?.destinationSeriesId,
      initialEpisodeId: e?.destinationEpisodeId,
    );
    _destinationController.initialize();
    _scheduledAt = e?.scheduledAt;

    _selectedLocales = e != null ? Set<String>.from(e.targetLocales) : {'tr'};

    for (final locale in kSupportedLocales) {
      final existing = e?.translations
          .where((t) => t.locale == locale)
          .firstOrNull;
      _titleControllers[locale] = TextEditingController(
        text: existing?.title ?? '',
      );
      _bodyControllers[locale] = TextEditingController(
        text: existing?.body ?? '',
      );
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _bodyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save({String status = 'draft'}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final translations = _selectedLocales.map((locale) {
        return AdminPushTranslation(
          locale: locale,
          title: _titleControllers[locale]!.text.trim(),
          body: _bodyControllers[locale]!.text.trim(),
        );
      }).toList();

      await widget.repository.upsert(
        id: widget.existing?.id,
        status: status,
        destinationType: _destinationType,
        destinationSeriesId: _destinationController.seriesIdForSave,
        destinationEpisodeId: _destinationController.episodeIdForSave,
        targetLocales: _selectedLocales.toList(),
        scheduledAt: status == 'scheduled' ? _scheduledAt : null,
        translations: translations,
      );

      if (mounted) Navigator.of(context).pop(true);
    } on PushCampaignException catch (e) {
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

  Future<void> _pickSchedule() async {
    final initial = _scheduledAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
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
                  _isEditing ? 'Push Düzenle' : 'Yeni Push Bildirimi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // === Hedef ===
                _sectionLabel('Hedef'),
                CampaignDestinationFields(
                  controller: _destinationController,
                  destinationType: _destinationType,
                  onDestinationTypeChanged: (type) {
                    setState(() => _destinationType = type);
                    _destinationController.setDestinationType(type);
                  },
                ),

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

                ..._selectedLocales.map((locale) {
                  return LocaleTranslationFields(
                    locale: locale,
                    titleController: _titleControllers[locale]!,
                    bodyController: _bodyControllers[locale]!,
                    showBody: true,
                  );
                }),

                // === Gönderim ===
                _sectionLabel('Gönderim'),
                if (_scheduledAt != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(
                      '${_scheduledAt!.year}-${_scheduledAt!.month.toString().padLeft(2, '0')}-${_scheduledAt!.day.toString().padLeft(2, '0')} '
                      '${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')} UTC',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _scheduledAt = null),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _pickSchedule,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Zamanlama Seç'),
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
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _save(status: 'draft'),
                      child: const Text('Taslak Kaydet'),
                    ),
                    if (_scheduledAt != null) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () => _save(status: 'scheduled'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Zamanla'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
