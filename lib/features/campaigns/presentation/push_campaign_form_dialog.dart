import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';
import '../../../l10n/admin_l10n.dart';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

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

      final existing = widget.existing;
      final keepScheduled = existing?.status == 'scheduled';

      await widget.repository.upsert(
        id: existing?.id,
        status: keepScheduled ? 'scheduled' : 'draft',
        destinationType: _destinationType,
        destinationSeriesId: _destinationController.seriesIdForSave,
        destinationEpisodeId: _destinationController.episodeIdForSave,
        targetLocales: _selectedLocales.toList(),
        scheduledAt: keepScheduled ? existing?.scheduledAt : null,
        translations: translations,
      );

      if (mounted) Navigator.of(context).pop(true);
    } on PushCampaignException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.pushFormSaveFailed;
        _isSaving = false;
      });
    }
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
                  _isEditing ? context.l10n.editPush : context.l10n.newPush,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _sectionLabel(context.l10n.target),
                CampaignDestinationFields(
                  controller: _destinationController,
                  destinationType: _destinationType,
                  onDestinationTypeChanged: (type) {
                    setState(() => _destinationType = type);
                    _destinationController.setDestinationType(type);
                  },
                ),
                _sectionLabel(context.l10n.targetLanguages),
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
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    key: const Key('campaign-push-form-error'),
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
                      child: Text(context.l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: Key(
                        _isEditing
                            ? 'campaign-push-save-changes'
                            : 'campaign-push-create',
                      ),
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      child: Text(
                        _isEditing
                            ? context.l10n.savePushChanges
                            : context.l10n.createPushCampaign,
                      ),
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
