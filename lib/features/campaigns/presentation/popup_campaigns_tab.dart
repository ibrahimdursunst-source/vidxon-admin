import 'package:flutter/material.dart';

import '../data/campaign_repository.dart';
import '../domain/admin_campaign.dart';
import 'popup_campaign_form_dialog.dart';

class PopupCampaignsTab extends StatefulWidget {
  const PopupCampaignsTab({super.key, this.repository});

  final CampaignRepository? repository;

  @override
  State<PopupCampaignsTab> createState() => PopupCampaignsTabState();
}

class PopupCampaignsTabState extends State<PopupCampaignsTab>
    with AutomaticKeepAliveClientMixin {
  static const _primaryColor = Color(0xFFE50914);

  late final CampaignRepository _repository =
      widget.repository ?? CampaignRepository();

  List<AdminCampaign>? _campaigns;
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

  Future<void> _openForm({AdminCampaign? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PopupCampaignFormDialog(
        repository: _repository,
        existing: existing,
      ),
    );
    if (result == true) {
      _load();
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
                label: const Text('Yeni Pop-up'),
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
          'Henüz pop-up kampanyası oluşturulmadı.',
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
          DataColumn(label: Text('Öncelik')),
          DataColumn(label: Text('Başlangıç')),
          DataColumn(label: Text('Bitiş')),
          DataColumn(label: Text('')),
        ],
        rows: campaigns.map((c) => _buildRow(c)).toList(),
      ),
    );
  }

  DataRow _buildRow(AdminCampaign campaign) {
    final statusColor = switch (campaign.statusLabel) {
      'Aktif' => Colors.green,
      'Planlanmış' => Colors.orange,
      'Süresi Dolmuş' => Colors.grey,
      _ => Colors.red,
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
        DataCell(Text(campaign.priority.toString())),
        DataCell(Text(_formatDate(campaign.startsAt))),
        DataCell(Text(
          campaign.endsAt != null ? _formatDate(campaign.endsAt!) : '—',
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _openForm(existing: campaign),
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
