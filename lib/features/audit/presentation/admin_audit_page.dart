import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../../admin_context/presentation/admin_context_scope.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../../users/domain/wallet_ledger_display.dart';
import '../data/admin_audit_repository.dart';
import '../domain/admin_audit_entry.dart';

String _auditSummaryLabel(AppLocalizations l10n, AdminAuditEntry entry) {
  final actionLabel = adminAuditActionLabel(l10n, entry.actionType);
  final metadata = entry.metadata;
  if (metadata == null || metadata.isEmpty) {
    return actionLabel;
  }

  final title = AdminAuditActionType.metadataTitle(metadata);
  if (title != null) {
    return '$actionLabel · $title';
  }

  return actionLabel;
}

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

    final l10n = context.l10n;

    return [
      _AuditFilterOption(label: l10n.all, value: null),
      _AuditFilterOption(
        label: l10n.filterWalletCredit,
        value: AdminAuditActionType.walletCredit,
      ),
      _AuditFilterOption(
        label: l10n.filterWalletDebitExact,
        value: AdminAuditActionType.walletDebit,
      ),
      _AuditFilterOption(
        label: l10n.filterSeriesUpdated,
        value: AdminAuditActionType.seriesUpdated,
      ),
      _AuditFilterOption(
        label: l10n.filterPosterReplaced,
        value: AdminAuditActionType.seriesPosterReplaced,
      ),
      _AuditFilterOption(
        label: l10n.filterSeriesPublished,
        value: AdminAuditActionType.seriesPublished,
      ),
      _AuditFilterOption(
        label: l10n.filterSeriesArchived,
        value: AdminAuditActionType.seriesArchived,
      ),
      _AuditFilterOption(
        label: l10n.filterEpisodeUpdated,
        value: AdminAuditActionType.episodeUpdated,
      ),
      _AuditFilterOption(
        label: l10n.filterEpisodeReorder,
        value: AdminAuditActionType.episodesReordered,
      ),
      _AuditFilterOption(
        label: l10n.filterVideoReplacement,
        value: AdminAuditActionType.episodeStreamReplacementRequested,
      ),
      if (isSuperAdmin) ...[
        _AuditFilterOption(
          label: l10n.filterAdminRoleChange,
          value: AdminAuditActionType.roleSet,
        ),
        _AuditFilterOption(
          label: l10n.filterAdminAccessRevoke,
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
                context.l10n.auditTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.auditSubtitle,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
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
                _EmptyState()
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
                        : Text(context.l10n.loadMore),
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
            decoration: InputDecoration(labelText: context.l10n.actionType),
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
            decoration: InputDecoration(labelText: context.l10n.targetUserId),
          ),
        ),
        FilledButton(
          onPressed: isLoading ? null : onRefresh,
          child: Text(context.l10n.refresh),
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
    final l10n = context.l10n;

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
            columns: [
              DataColumn(label: Text(l10n.action)),
              DataColumn(label: Text(l10n.admin)),
              DataColumn(label: Text(l10n.target)),
              DataColumn(label: Text(l10n.amount)),
              DataColumn(label: Text(l10n.previous)),
              DataColumn(label: Text(l10n.next)),
              DataColumn(label: Text(l10n.reasonAlt)),
              DataColumn(label: Text(l10n.description)),
              DataColumn(label: Text(l10n.reference)),
              DataColumn(label: Text(l10n.date)),
            ],
            rows: [
              for (final entry in entries)
                DataRow(
                  cells: [
                    DataCell(Text(_auditSummaryLabel(l10n, entry))),
                    DataCell(Text(entry.actorLabel)),
                    DataCell(Text(entry.targetLabel)),
                    DataCell(Text(_amountLabel(entry))),
                    DataCell(Text(_balanceLabel(entry.balanceBefore))),
                    DataCell(Text(_balanceLabel(entry.balanceAfter))),
                    DataCell(
                      Text(adminWalletReasonLabel(l10n, entry.reasonCode)),
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
                    adminAuditActionLabel(context.l10n, entry.actionType),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${context.l10n.admin}: ${entry.actorLabel}'),
                  Text(context.l10n.targetNamed(entry.targetLabel)),
                  if (entry.amount != null)
                    Text(context.l10n.amountPrefixed(_amountLabel(entry))),
                  if (entry.balanceBefore != null)
                    Text(
                      context.l10n.previousBalance('${entry.balanceBefore}'),
                    ),
                  if (entry.balanceAfter != null)
                    Text(
                      context.l10n.nextBalancePrefixed('${entry.balanceAfter}'),
                    ),
                  if (entry.reasonCode != null)
                    Text(
                      context.l10n.reasonPrefixed(
                        adminWalletReasonLabel(context.l10n, entry.reasonCode),
                      ),
                    ),
                  Text(
                    context.l10n.datePrefixed(
                      formatUserDateTime(entry.createdAt),
                    ),
                  ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.all(Radius.circular(14)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            context.l10n.noAuditRecords,
            style: const TextStyle(color: Color(0xFFB3B3B3)),
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
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
