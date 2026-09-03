import 'package:flutter/material.dart';

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
      builder: (_) => PushCampaignFormDialog(
        repository: _repository,
        existing: existing,
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _sendNow(AdminPushCampaign campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Push Gönder'),
        content: Text(
          '"${campaign.displayTitle}" kampanyasını şimdi göndermek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.sendNow(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push gönderimi başlatıldı.')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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
          SnackBar(content: Text('Hata: $e')),
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
                label: const Text('Yeni Push'),
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
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final campaigns = _campaigns ?? [];
    if (campaigns.isEmpty) {
      return const Center(
        child: Text(
          'Henüz push bildirimi oluşturulmadı.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Durum')),
          DataColumn(label: Text('Başlık')),
          DataColumn(label: Text('Diller')),
          DataColumn(label: Text('Hedef')),
          DataColumn(label: Text('Plan/Gönderim')),
          DataColumn(label: Text('Gönderildi')),
          DataColumn(label: Text('Başarısız')),
          DataColumn(label: Text('')),
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
              campaign.statusLabel,
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
        DataCell(Text(campaign.destinationLabel)),
        DataCell(Text(
          campaign.sentAt != null
              ? _formatDate(campaign.sentAt!)
              : campaign.scheduledAt != null
                  ? _formatDate(campaign.scheduledAt!)
                  : '—',
        )),
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
                  tooltip: 'Düzenle',
                ),
              if (campaign.canSend)
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 18),
                  onPressed: () => _sendNow(campaign),
                  tooltip: 'Şimdi Gönder',
                ),
              if (campaign.canCancel)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  onPressed: () => _cancel(campaign),
                  tooltip: 'İptal Et',
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
