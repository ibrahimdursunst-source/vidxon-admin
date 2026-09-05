import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import 'push_campaign_form_dialog.dart';

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  void refresh() => _load();

  Future<void> _openForm({AdminPushCampaign? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) =>
          PushCampaignFormDialog(repository: _repository, existing: existing),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _sendNow(AdminPushCampaign campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.sendPush),
        content: Text(context.l10n.sendPushConfirm(campaign.displayTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
            child: Text(context.l10n.send),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.sendNow(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.pushSendStarted)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorPrefixed('$e'))),
        );
      }
    }
  }

  Future<void> _cancel(AdminPushCampaign campaign) async {
    try {
      await _repository.cancel(campaign.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorPrefixed('$e'))),
        );
      }
    }
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
                onPressed: () => _openForm(),
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
            Text(_error.toString()),
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
              adminCampaignStatusLabel(context.l10n, campaign.statusLabel),
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
            campaign.sentAt != null
                ? _formatDate(campaign.sentAt!)
                : campaign.scheduledAt != null
                ? _formatDate(campaign.scheduledAt!)
                : '—',
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
                  onPressed: () => _openForm(existing: campaign),
                  tooltip: context.l10n.edit,
                ),
              if (campaign.canSend)
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 18),
                  onPressed: () => _sendNow(campaign),
                  tooltip: context.l10n.sendNow,
                ),
              if (campaign.canCancel)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  onPressed: () => _cancel(campaign),
                  tooltip: context.l10n.cancelAction,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
