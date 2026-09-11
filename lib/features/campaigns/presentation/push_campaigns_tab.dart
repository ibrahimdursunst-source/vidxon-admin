import 'package:flutter/material.dart';

import '../../../core/time/admin_local_time.dart';
import '../../../l10n/admin_l10n.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import 'push_campaign_form_dialog.dart';
import 'push_schedule_dialog.dart';
import 'push_test_send_dialog.dart';

class PushCampaignsTab extends StatefulWidget {
  const PushCampaignsTab({super.key, this.repository});

  final PushCampaignRepository? repository;

  @override
  State<PushCampaignsTab> createState() => PushCampaignsTabState();
}

class PushCampaignsTabState extends State<PushCampaignsTab>
    with AutomaticKeepAliveClientMixin {
  static const _primaryColor = Color(0xFFE50914);

  late final PushCampaignRepository _repository =
      widget.repository ?? PushCampaignRepository();

  List<AdminPushCampaign>? _campaigns;
  bool _isLoading = true;
  Object? _error;
  bool _actionInFlight = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final campaigns = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
        _isLoading = false;
      });
    }
  }

  void refresh() => _load();

  Future<void> _openForm({AdminPushCampaign? existing}) async {
    if (_actionInFlight) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) =>
          PushCampaignFormDialog(repository: _repository, existing: existing),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _sendToAllUsers(AdminPushCampaign campaign) async {
    if (_actionInFlight) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1212),
          title: Text(l10n.sendToAllUsers),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.displayTitle,
                key: const Key('push-all-users-campaign-title'),
              ),
              const SizedBox(height: 8),
              Text(
                campaign.targetLocales.join(', '),
                key: const Key('push-all-users-campaign-locales'),
              ),
              const SizedBox(height: 8),
              Text(l10n.pushAudienceAllEligible),
              const SizedBox(height: 12),
              Text(
                l10n.sendToAllUsersWarning,
                style: const TextStyle(color: Color(0xFFFFB4AB)),
              ),
              const SizedBox(height: 8),
              Text(l10n.sendToAllUsersConfirm(campaign.displayTitle)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('campaign-push-send-now-confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: Text(l10n.sendToAllUsers),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _actionInFlight = true);
    try {
      await _repository.sendNow(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pushAllUsersStarted)),
        );
      }
      await _load();
    } on PushDeliveryFailure catch (failure) {
      await _load();
      if (!mounted) return;
      debugPrint('push send all users failed');
      _showDeliveryFailure(failure);
    } catch (_) {
      await _load();
      if (!mounted) return;
      debugPrint('push send all users failed');
      _showSafeSendFailure();
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _sendToSpecificUser(AdminPushCampaign campaign) async {
    if (_actionInFlight) return;
    setState(() => _actionInFlight = true);
    try {
      final sent = await showDialog<bool>(
        context: context,
        builder: (_) => PushTestSendDialog(
          campaign: campaign,
          repository: _repository,
        ),
      );
      if (sent == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pushSpecificUserStarted)),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _schedule(AdminPushCampaign campaign) async {
    if (_actionInFlight) return;
    final scheduled = await showDialog<bool>(
      context: context,
      builder: (_) => PushScheduleDialog(
        campaign: campaign,
        repository: _repository,
      ),
    );
    if (scheduled == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pushScheduledStarted)),
      );
      await _load();
    }
  }

  Future<void> _cancel(AdminPushCampaign campaign) async {
    if (_actionInFlight) return;
    try {
      await _repository.cancel(campaign.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pushFormSaveFailed)),
        );
      }
    }
  }

  void _showDeliveryFailure(PushDeliveryFailure failure) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pushSendFailed, key: const Key('campaign-push-send-now-error')),
            Text(
              l10n.pushDeliverySummary(
                failure.pendingCount,
                failure.sentCount,
                failure.failedCount,
              ),
              key: const Key('campaign-push-delivery-summary'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSafeSendFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.pushSendFailed,
          key: const Key('campaign-push-send-now-error'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: _actionInFlight ? null : () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.newPush),
                style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _primaryColor),
            const SizedBox(height: 16),
            Text(context.l10n.pushFormSaveFailed),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    final campaigns = _campaigns ?? [];
    if (campaigns.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noPushCampaigns,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        columns: [
          DataColumn(label: Text(context.l10n.status)),
          DataColumn(label: Text(context.l10n.title)),
          DataColumn(label: Text(context.l10n.languages)),
          DataColumn(label: Text(context.l10n.target)),
          DataColumn(label: Text(context.l10n.planOrDelivery)),
          DataColumn(label: Text(context.l10n.sent)),
          DataColumn(label: Text(context.l10n.failed)),
          const DataColumn(label: Text('')),
        ],
        rows: campaigns.map((c) => _buildRow(c)).toList(),
      ),
    );
  }

  DataRow _buildRow(AdminPushCampaign campaign) {
    final statusColor = switch (campaign.status) {
      'draft' => Colors.blue,
      'scheduled' => Colors.orange,
      'sending' => Colors.amber,
      'sent' => Colors.green,
      'failed' => Colors.red,
      'cancelled' => Colors.grey,
      _ => Colors.grey,
    };
    final locale = Localizations.localeOf(context);
    final when = campaign.sentAt ?? campaign.scheduledAt;

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              adminPushCampaignStatusLabel(context.l10n, campaign.status),
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Text(
            campaign.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(campaign.targetLocales.join(', '))),
        DataCell(
          Text(
            adminDestinationTypeLabel(context.l10n, campaign.destinationType),
          ),
        ),
        DataCell(
          Text(
            when == null ? '—' : AdminLocalTime.format(when, locale),
          ),
        ),
        DataCell(Text(campaign.sentCount.toString())),
        DataCell(Text(campaign.failedCount.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (campaign.canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: _actionInFlight
                      ? null
                      : () => _openForm(existing: campaign),
                  tooltip: context.l10n.edit,
                ),
              if (campaign.canTestSend)
                IconButton(
                  key: const Key('campaign-push-test-send'),
                  icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                  onPressed: _actionInFlight
                      ? null
                      : () => _sendToSpecificUser(campaign),
                  tooltip: context.l10n.sendToSpecificUser,
                ),
              if (campaign.canSend)
                IconButton(
                  key: const Key('campaign-push-send-now'),
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  onPressed: _actionInFlight
                      ? null
                      : () => _sendToAllUsers(campaign),
                  tooltip: context.l10n.sendToAllUsers,
                ),
              if (campaign.canSchedule)
                IconButton(
                  key: const Key('campaign-push-schedule'),
                  icon: const Icon(Icons.schedule, size: 18),
                  onPressed: _actionInFlight ? null : () => _schedule(campaign),
                  tooltip: context.l10n.schedulePushSend,
                ),
              if (campaign.canCancel)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  onPressed: _actionInFlight ? null : () => _cancel(campaign),
                  tooltip: context.l10n.cancelAction,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
