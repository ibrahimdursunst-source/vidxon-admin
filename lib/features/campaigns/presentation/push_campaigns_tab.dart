import 'package:flutter/material.dart';

import '../../../core/locale/vidxon_product_locales.dart';
import '../../../core/time/admin_local_time.dart';
import '../../../l10n/admin_l10n.dart';
import '../data/push_campaign_repository.dart';
import '../domain/admin_push_campaign.dart';
import 'push_campaign_form_dialog.dart';
import 'push_schedule_dialog.dart';
import 'push_send_all_dialog.dart';
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

  PushAudienceSummary? _audience;
  bool _audienceLoading = true;
  Object? _audienceError;
  String? _audienceLocale;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAudience();
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

  Future<void> _loadAudience() async {
    setState(() {
      _audienceLoading = true;
      _audienceError = null;
    });
    try {
      final locales = _audienceLocale == null
          ? null
          : <String>[_audienceLocale!];
      final summary = await _repository.fetchAudienceSummary(locales: locales);
      if (!mounted) return;
      setState(() {
        _audience = summary;
        _audienceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audienceError = 'load_failed';
        _audienceLoading = false;
      });
    }
  }

  void refresh() => _load();

  void _selectAudienceLocale(String? locale) {
    if (_audienceLocale == locale) return;
    setState(() => _audienceLocale = locale);
    _loadAudience();
  }

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
      builder: (_) =>
          PushSendAllDialog(campaign: campaign, repository: _repository),
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
      await _loadAudience();
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
        builder: (_) =>
            PushTestSendDialog(campaign: campaign, repository: _repository),
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
      builder: (_) =>
          PushScheduleDialog(campaign: campaign, repository: _repository),
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
            Text(
              l10n.pushSendFailed,
              key: const Key('campaign-push-send-now-error'),
            ),
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
        _buildAudiencePanel(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildAudiencePanel() {
    final l10n = context.l10n;
    final summary = _audience;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pushAudienceTitle,
            key: const Key('campaign-push-audience-title'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('campaign-push-audience-locale-all'),
                label: Text(l10n.all),
                selected: _audienceLocale == null,
                onSelected: (_) => _selectAudienceLocale(null),
              ),
              for (final locale in VidxonProductLocales.all)
                ChoiceChip(
                  key: Key('campaign-push-audience-locale-$locale'),
                  label: Text(locale),
                  selected: _audienceLocale == locale,
                  onSelected: (_) => _selectAudienceLocale(locale),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_audienceLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_audienceError != null)
            Text(
              l10n.pushReadinessLoadFailed,
              key: const Key('campaign-push-audience-error'),
            )
          else if (summary != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(
                  key: const Key('campaign-push-audience-enabled'),
                  label: l10n.pushEnabledAccounts,
                  value: summary.enabledAccountCount,
                ),
                _metricCard(
                  key: const Key('campaign-push-audience-users'),
                  label: l10n.pushEligibleUsers,
                  value: summary.eligibleUserCount,
                ),
                _metricCard(
                  key: const Key('campaign-push-audience-devices'),
                  label: l10n.pushEligibleDevicesLabel,
                  value: summary.eligibleDeviceCount,
                ),
                _metricCard(
                  key: const Key('campaign-push-audience-android'),
                  label: l10n.pushAndroidLabel,
                  value: summary.androidDeviceCount,
                ),
                _metricCard(
                  key: const Key('campaign-push-audience-ios'),
                  label: l10n.pushIosLabel,
                  value: summary.iosDeviceCount,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required Key key,
    required String label,
    required int value,
  }) {
    return Container(
      key: key,
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB3B3B3)),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(context.l10n.status)),
            DataColumn(label: Text(context.l10n.title)),
            DataColumn(label: Text(context.l10n.messageColumn)),
            DataColumn(label: Text(context.l10n.languages)),
            DataColumn(label: Text(context.l10n.target)),
            DataColumn(label: Text(context.l10n.planOrDelivery)),
            DataColumn(label: Text(context.l10n.sentDevices)),
            DataColumn(label: Text(context.l10n.failedDevices)),
            DataColumn(label: Text(context.l10n.pushCampaignActions)),
          ],
          rows: campaigns.map((c) => _buildRow(c)).toList(),
        ),
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
    final message = campaign.displayBodyForUi(locale.languageCode);

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
        DataCell(
          Tooltip(
            message: message,
            child: SizedBox(
              width: 220,
              child: Text(
                message,
                key: const Key('campaign-push-message'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            key: const Key('campaign-plan-or-delivery'),
          ),
        ),
        DataCell(
          Text(
            campaign.sentCount.toString(),
            key: const Key('campaign-push-sent-devices'),
          ),
        ),
        DataCell(
          Text(
            campaign.failedCount.toString(),
            key: const Key('campaign-push-failed-devices'),
          ),
        ),
        DataCell(
          (campaign.canEdit ||
                  campaign.canTestSend ||
                  campaign.canSend ||
                  campaign.canSchedule ||
                  campaign.canCancel)
              ? PopupMenuButton<String>(
                  key: const Key('campaign-push-actions'),
                  enabled: !_actionInFlight,
                  tooltip: context.l10n.pushCampaignActions,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openForm(existing: campaign);
                      case 'specific':
                        _sendToSpecificUser(campaign);
                      case 'all':
                        _sendToAllUsers(campaign);
                      case 'schedule':
                        _schedule(campaign);
                      case 'cancel':
                        _cancel(campaign);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (campaign.canEdit)
                      PopupMenuItem(value: 'edit', child: Text(ctx.l10n.edit)),
                    if (campaign.canTestSend)
                      PopupMenuItem(
                        key: const Key('campaign-push-test-send'),
                        value: 'specific',
                        child: Text(ctx.l10n.sendToSpecificUser),
                      ),
                    if (campaign.canSend)
                      PopupMenuItem(
                        key: const Key('campaign-push-send-now'),
                        value: 'all',
                        child: Text(ctx.l10n.sendToAllUsers),
                      ),
                    if (campaign.canSchedule)
                      PopupMenuItem(
                        key: const Key('campaign-push-schedule'),
                        value: 'schedule',
                        child: Text(ctx.l10n.schedulePushSend),
                      ),
                    if (campaign.canCancel)
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text(ctx.l10n.cancelAction),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      context.l10n.pushCampaignActions,
                      style: const TextStyle(
                        color: Color(0xFFE50914),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
