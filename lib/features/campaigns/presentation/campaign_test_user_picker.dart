import 'package:flutter/material.dart';

import '../../users/data/admin_user_wallet_repository.dart';
import '../../users/domain/admin_user_summary.dart';

class CampaignTestUserPicker extends StatefulWidget {
  const CampaignTestUserPicker({
    required this.selectedUserId,
    required this.selectedLabel,
    required this.onSelected,
    required this.onCleared,
    this.userRepository,
    super.key,
  });

  final String? selectedUserId;
  final String? selectedLabel;
  final ValueChanged<AdminUserSummary> onSelected;
  final VoidCallback onCleared;
  final AdminUserWalletRepository? userRepository;

  @override
  State<CampaignTestUserPicker> createState() => _CampaignTestUserPickerState();
}

class _CampaignTestUserPickerState extends State<CampaignTestUserPicker> {
  final _queryController = TextEditingController();
  late final AdminUserWalletRepository _repository =
      widget.userRepository ?? AdminUserWalletRepository();
  List<AdminUserSummary> _results = const [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'E-posta veya ad girin.');
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await _repository.searchUsers(query: query, limit: 8);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty) {
          _error = 'Eşleşen kullanıcı yok.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'Kullanıcı araması başarısız.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectedUserId;
    final selectedLabel = widget.selectedLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedId != null && selectedId.isNotEmpty) ...[
          Text(
            selectedLabel == null || selectedLabel.isEmpty
                ? selectedId
                : '$selectedLabel · $selectedId',
            key: const Key('campaign-test-user-selected'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onCleared,
              child: const Text('Kullanıcıyı kaldır'),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('campaign-test-user-search'),
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Test kullanıcısı ara',
                    hintText: 'E-posta veya ad',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('campaign-test-user-search-button'),
                onPressed: _searching ? null : _search,
                child: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ara'),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        if (_results.isNotEmpty && (selectedId == null || selectedId.isEmpty))
          ..._results.map((user) {
            return ListTile(
              dense: true,
              title: Text(user.resolvedDisplayName),
              subtitle: Text(user.resolvedEmailLabel),
              onTap: () {
                widget.onSelected(user);
                setState(() => _results = const []);
              },
            );
          }),
      ],
    );
  }
}
