import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import 'push_audience_readiness_lines.dart';

class PushSendAllDialog extends StatefulWidget {
  const PushSendAllDialog({
    super.key,
    required this.campaign,
    required this.repository,
  });

  final AdminPushCampaign campaign;
  final PushCampaignRepository repository;

  @override
  State<PushSendAllDialog> createState() => _PushSendAllDialogState();
}

class _PushSendAllDialogState extends State<PushSendAllDialog> {
  static const _primaryColor = Color(0xFFE50914);

  PushAudienceSummary? _summary;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await widget.repository.fetchAudienceSummary(
        locales: widget.campaign.targetLocales,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load_failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSend =
        !_loading && _error == null && (_summary?.eligibleDeviceCount ?? 0) > 0;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1212),
      title: Text(l10n.sendToAllUsers),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.campaign.displayTitle,
                key: const Key('push-all-users-campaign-title'),
              ),
              const SizedBox(height: 8),
              Text(
                widget.campaign.targetLocales.join(', '),
                key: const Key('push-all-users-campaign-locales'),
              ),
              const SizedBox(height: 8),
              Text(l10n.pushAudienceAllEligible),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(
                  l10n.pushReadinessLoadFailed,
                  key: const Key('push-all-users-readiness-error'),
                )
              else if (_summary != null)
                PushAudienceReadinessLines(
                  summary: _summary!,
                  note: l10n.pushAudienceCurrentNote,
                  showZeroDevicesMessage: true,
                ),
              const SizedBox(height: 12),
              Text(
                l10n.sendToAllUsersWarning,
                style: const TextStyle(color: Color(0xFFFFB4AB)),
              ),
              const SizedBox(height: 8),
              Text(l10n.sendToAllUsersConfirm(widget.campaign.displayTitle)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('campaign-push-send-now-confirm'),
          onPressed: canSend ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: _primaryColor),
          child: Text(l10n.sendToAllUsers),
        ),
      ],
    );
  }
}
