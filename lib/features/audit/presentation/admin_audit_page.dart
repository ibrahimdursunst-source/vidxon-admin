import 'package:flutter/material.dart';

import '../../admin_context/presentation/admin_context_scope.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../../users/domain/wallet_ledger_display.dart';
import '../data/admin_audit_repository.dart';
import '../domain/admin_audit_entry.dart';

class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({this.repository, super.key});

  final AdminAuditRepository? repository;

  @override
  AdminAuditPageState createState() => AdminAuditPageState();
}

class AdminAuditPageState extends State<AdminAuditPage> {
  static const _desktopBreakpoint = 900.0;
  static const _pageSize = 50;

  late final AdminAuditRepository _repository =
      widget.repository ?? AdminAuditRepository();

  final TextEditingController _targetUserIdController = TextEditingController();

  List<AdminAuditEntry> _entries = const [];
  String? _selectedActionType;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _targetUserIdController.dispose();
    super.dispose();
  }

  void refresh() {
    _load(reset: true);
  }

  List<_AuditFilterOption> _filterOptions(BuildContext context) {
    final isSuperAdmin =
        AdminContextScope.maybeOf(context)?.isSuperAdmin ?? false;

    return [
      const _AuditFilterOption(label: 'Tümü', value: null),
      const _AuditFilterOption(
        label: 'Jeton Yükleme',
        value: AdminAuditActionType.walletCredit,
      ),
      const _AuditFilterOption(
        label: 'Jeton Eksiltme',
        value: AdminAuditActionType.walletDebit,
      ),
      if (isSuperAdmin) ...[
        const _AuditFilterOption(
          label: 'Admin Rolü Değişikliği',
          value: AdminAuditActionType.roleSet,
        ),
        const _AuditFilterOption(
          label: 'Admin Erişimi Kaldırma',
          value: AdminAuditActionType.accessRevoke,
        ),
      ],
    ];
  }

  String? _validateTargetUserIdFilter() {
    return validateAuditTargetUserIdFilter(_targetUserIdController.text);
  }

  Future<void> _load({required bool reset}) async {
    final generation = reset ? ++_loadGeneration : _loadGeneration;

    final targetValidationError = _validateTargetUserIdFilter();
    if (targetValidationError != null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = targetValidationError;
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final targetUserId = _targetUserIdController.text.trim();
      final entries = await _repository.listAuditLog(
        actionType: _selectedActionType,
        targetUserId: targetUserId.isEmpty ? null : targetUserId,
        limit: _pageSize,
        offset: reset ? 0 : _entries.length,
      );

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        if (reset) {
          _entries = entries;
        } else {
          _entries = [..._entries, ...entries];
        }
        _hasMore = entries.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = _filterOptions(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'İşlem Kayıtları',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Admin paneli işlem geçmişi',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return _AuditFilterBar(
                    maxWidth: constraints.maxWidth,
                    selectedActionType: _selectedActionType,
                    targetUserIdController: _targetUserIdController,
                    filterOptions: filterOptions,
                    isLoading: _isLoading,
                    onActionTypeChanged: (value) {
                      setState(() => _selectedActionType = value);
                    },
                    onRefresh: _applyFilters,
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                _ErrorState(
                  message: _errorMessage!,
                  onRetry: () => _load(reset: true),
                )
              else if (_entries.isEmpty)
                const _EmptyState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _desktopBreakpoint) {
                      return _AuditDataTable(entries: _entries);
                    }

                    return _AuditCardList(entries: _entries);
                  },
                ),
              if (_hasMore && _entries.isNotEmpty && _errorMessage == null) ...[
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: _isLoadingMore
                        ? null
                        : () => _load(reset: false),
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Daha Fazla Yükle'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditFilterOption {
  const _AuditFilterOption({required this.label, required this.value});

  final String label;
  final String? value;
}

class _AuditFilterBar extends StatelessWidget {
  const _AuditFilterBar({
    required this.maxWidth,
    required this.selectedActionType,
    required this.targetUserIdController,
    required this.filterOptions,
    required this.isLoading,
    required this.onActionTypeChanged,
    required this.onRefresh,
  });

  static const _stackedBreakpoint = 720.0;
  static const _actionTypeFieldWidth = 240.0;
  static const _targetUserFieldWidth = 320.0;

  final double maxWidth;
  final String? selectedActionType;
  final TextEditingController targetUserIdController;
  final List<_AuditFilterOption> filterOptions;
  final bool isLoading;
  final ValueChanged<String?> onActionTypeChanged;
  final VoidCallback onRefresh;

  bool get _useStackedLayout => maxWidth < _stackedBreakpoint;

  double _fieldWidth(double preferredWidth) {
    if (_useStackedLayout) {
      return maxWidth;
    }

    return preferredWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: _fieldWidth(_actionTypeFieldWidth),
          child: DropdownButtonFormField<String?>(
            initialValue: selectedActionType,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'İşlem türü'),
            items: [
              for (final option in filterOptions)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: onActionTypeChanged,
          ),
        ),
        SizedBox(
          width: _fieldWidth(_targetUserFieldWidth),
          child: TextField(
            controller: targetUserIdController,
            decoration: const InputDecoration(labelText: 'Hedef kullanıcı ID'),
          ),
        ),
        FilledButton(
          onPressed: isLoading ? null : onRefresh,
          child: const Text('Yenile'),
        ),
      ],
    );
  }
}

class _AuditDataTable extends StatelessWidget {
  const _AuditDataTable({required this.entries});

  final List<AdminAuditEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF181818)),
            columns: const [
              DataColumn(label: Text('İşlem')),
              DataColumn(label: Text('Admin')),
              DataColumn(label: Text('Hedef')),
              DataColumn(label: Text('Miktar')),
              DataColumn(label: Text('Önceki')),
              DataColumn(label: Text('Sonraki')),
              DataColumn(label: Text('Sebep')),
              DataColumn(label: Text('Açıklama')),
              DataColumn(label: Text('Referans')),
              DataColumn(label: Text('Tarih')),
            ],
            rows: [
              for (final entry in entries)
                DataRow(
                  cells: [
                    DataCell(Text(entry.actionTypeLabel)),
                    DataCell(Text(entry.actorLabel)),
                    DataCell(Text(entry.targetLabel)),
                    DataCell(Text(_amountLabel(entry))),
                    DataCell(Text(_balanceLabel(entry.balanceBefore))),
                    DataCell(Text(_balanceLabel(entry.balanceAfter))),
                    DataCell(
                      Text(WalletLedgerDisplay.reasonLabel(entry.reasonCode)),
                    ),
                    DataCell(
                      Text(WalletLedgerDisplay.optionalText(entry.description)),
                    ),
                    DataCell(
                      Text(
                        WalletLedgerDisplay.optionalText(entry.caseReference),
                      ),
                    ),
                    DataCell(Text(formatUserDateTime(entry.createdAt))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditCardList extends StatelessWidget {
  const _AuditCardList({required this.entries});

  final List<AdminAuditEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.actionTypeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Admin: ${entry.actorLabel}'),
                  Text('Hedef: ${entry.targetLabel}'),
                  if (entry.amount != null)
                    Text('Miktar: ${_amountLabel(entry)}'),
                  if (entry.balanceBefore != null)
                    Text('Önceki bakiye: ${entry.balanceBefore}'),
                  if (entry.balanceAfter != null)
                    Text('Sonraki bakiye: ${entry.balanceAfter}'),
                  if (entry.reasonCode != null)
                    Text(
                      'Sebep: ${WalletLedgerDisplay.reasonLabel(entry.reasonCode)}',
                    ),
                  Text('Tarih: ${formatUserDateTime(entry.createdAt)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

String _amountLabel(AdminAuditEntry entry) {
  if (entry.amount == null) {
    return '—';
  }

  if (entry.actionType == AdminAuditActionType.walletDebit) {
    return '-${entry.amount}';
  }

  return entry.amount.toString();
}

String _balanceLabel(int? value) {
  if (value == null) {
    return '—';
  }

  return value.toString();
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.all(Radius.circular(14)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'İşlem kaydı bulunamadı.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
