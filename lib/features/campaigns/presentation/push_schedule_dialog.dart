import 'package:flutter/material.dart';

import '../../../core/time/admin_local_time.dart';
import '../../../l10n/admin_l10n.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import 'push_audience_readiness_lines.dart';

class PushScheduleDialog extends StatefulWidget {
  const PushScheduleDialog({
    super.key,
    required this.campaign,
    required this.repository,
  });

  final AdminPushCampaign campaign;
  final PushCampaignRepository repository;

  @override
  State<PushScheduleDialog> createState() => _PushScheduleDialogState();
}

class _PushScheduleDialogState extends State<PushScheduleDialog> {
  static const _primaryColor = Color(0xFFE50914);

  late DateTime _localScheduledAt;
  bool _saving = false;
  String? _error;
  PushAudienceSummary? _summary;
  bool _audienceLoading = true;
  Object? _audienceError;

  @override
  void initState() {
    super.initState();
    final existing = widget.campaign.scheduledAt;
    _localScheduledAt = existing != null
        ? AdminLocalTime.utcToLocalPicker(existing)
        : DateTime.now();
    _loadAudience();
  }

  Future<void> _loadAudience() async {
    try {
      final summary = await widget.repository.fetchAudienceSummary(
        locales: widget.campaign.targetLocales,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _audienceLoading = false;
        _audienceError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audienceLoading = false;
        _audienceError = 'load_failed';
      });
    }
  }

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _localScheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_localScheduledAt),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (time == null || !mounted) return;
    setState(() {
      _localScheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.upsert(
        id: widget.campaign.id,
        status: 'scheduled',
        destinationType: widget.campaign.destinationType,
        destinationSeriesId: widget.campaign.destinationSeriesId,
        destinationEpisodeId: widget.campaign.destinationEpisodeId,
        targetLocales: widget.campaign.targetLocales,
        scheduledAt: AdminLocalTime.localToUtc(_localScheduledAt),
        translations: widget.campaign.translations,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PushCampaignException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.l10n.pushFormSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final previewUtc = AdminLocalTime.localToUtc(_localScheduledAt);
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(l10n.schedulePushSend),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.campaign.displayTitle,
                key: const Key('push-schedule-campaign-title'),
              ),
              const SizedBox(height: 12),
              Text(
                AdminLocalTime.format(previewUtc, locale),
                key: const Key('push-schedule-local-preview'),
              ),
              TextButton.icon(
                key: const Key('push-schedule-pick'),
                onPressed: _saving ? null : _pick,
                icon: const Icon(Icons.schedule),
                label: Text(l10n.chooseScheduleTime),
              ),
              const SizedBox(height: 12),
              if (_audienceLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_audienceError != null)
                Text(
                  l10n.pushReadinessLoadFailed,
                  key: const Key('push-schedule-audience-error'),
                )
              else if (_summary != null)
                PushAudienceReadinessLines(
                  summary: _summary!,
                  note: l10n.pushAudienceScheduleEstimateNote,
                ),
              if (_error != null)
                Text(
                  _error!,
                  key: const Key('push-schedule-error'),
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('push-schedule-confirm'),
          onPressed: _saving ? null : _confirm,
          style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          child: Text(l10n.schedulePushConfirm),
        ),
      ],
    );
  }
}
