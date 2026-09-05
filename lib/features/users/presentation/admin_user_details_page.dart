import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/admin_l10n.dart';
import '../../admin_context/presentation/admin_context_scope.dart';
import '../data/admin_user_wallet_repository.dart';
import '../domain/admin_user_details.dart';
import '../domain/admin_user_summary.dart';
import '../domain/admin_wallet_ledger_entry.dart';
import '../domain/user_parse_helpers.dart';
import 'admin_coin_credit_dialog.dart';
import 'admin_coin_debit_dialog.dart';
import 'admin_role_badge.dart';
import 'admin_wallet_mutation_permission.dart';

String _localizedDisplayName(AppLocalizations l10n, String name) {
  return name == 'Anonim Kullanıcı' ? l10n.anonymousUser : name;
}

String _localizedRoleLabel(AppLocalizations l10n, String label) {
  return switch (label) {
    'Admin' => l10n.adminRole,
    'Super Admin' => l10n.superAdminRole,
    _ => label,
  };
}

String adminLedgerActorLabel(
  AppLocalizations l10n,
  AdminWalletLedgerEntry entry,
) {
  final actorId = entry.actorAdminUserId;
  if (actorId == null || actorId.trim().isEmpty) {
    return adminActorLabel(l10n, actorId);
  }

  final email = entry.actorAdminEmail?.trim();
  if (email != null && email.isNotEmpty) {
    return email;
  }

  return shortenUserId(actorId);
}

class AdminUserDetailsPage extends StatefulWidget {
  const AdminUserDetailsPage({
    required this.userId,
    this.repository,
    this.initialSummary,
    super.key,
  });

  final String userId;
  final AdminUserWalletRepository? repository;
  final AdminUserSummary? initialSummary;

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  static const _desktopBreakpoint = 900.0;
  static const _ledgerPageSize = 50;
  static const _primaryColor = Color(0xFFE50914);

  late final AdminUserWalletRepository _repository =
      widget.repository ?? AdminUserWalletRepository();

  AdminUserDetails? _details;
  List<AdminWalletLedgerEntry> _ledgerEntries = const [];
  bool _isLoading = true;
  bool _isLoadingMoreLedger = false;
  bool _hasMoreLedger = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll(resetLedger: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.dependOnInheritedWidgetOfExactType<AdminContextScope>();
  }

  bool _canMutateWallet(AdminUserDetails details) {
    final contextResult = AdminContextScope.maybeOf(context);
    return canMutateAdminWallet(
      contextResult: contextResult,
      walletActionsAllowed: details.walletActionsAllowed,
    );
  }

  String? _walletRestrictionMessage(AdminUserDetails details) {
    final contextResult = AdminContextScope.maybeOf(context);
    return adminWalletMutationRestrictionMessage(
      contextResult: contextResult,
      walletActionsAllowed: details.walletActionsAllowed,
    );
  }

  Future<void> _loadAll({required bool resetLedger}) async {
    setState(() {
      _errorMessage = null;
      _isLoading = resetLedger;
    });

    try {
      final details = await _repository.getUserDetails(userId: widget.userId);
      final ledger = await _repository.listUserWalletLedger(
        userId: widget.userId,
        limit: _ledgerPageSize,
        offset: resetLedger ? 0 : _ledgerEntries.length,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
        if (resetLedger) {
          _ledgerEntries = ledger;
        } else {
          _ledgerEntries = [..._ledgerEntries, ...ledger];
        }
        _hasMoreLedger = ledger.length >= _ledgerPageSize;
        _isLoading = false;
        _isLoadingMoreLedger = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _isLoadingMoreLedger = false;
      });
    }
  }

  Future<void> _loadMoreLedger() async {
    setState(() => _isLoadingMoreLedger = true);
    await _loadAll(resetLedger: false);
  }

  Future<void> _openCoinDebit() async {
    final details = _details;
    if (details == null || !_canMutateWallet(details)) {
      return;
    }

    final successMessage = await showAdminCoinDebitDialog(
      context: context,
      user: details,
      repository: _repository,
    );

    if (successMessage != null) {
      if (!mounted) {
        return;
      }

      await _loadAll(resetLedger: true);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  Future<void> _openCoinCredit() async {
    final details = _details;
    if (details == null || !_canMutateWallet(details)) {
      return;
    }

    final successMessage = await showAdminCoinCreditDialog(
      context: context,
      user: details,
      repository: _repository,
    );

    if (successMessage != null) {
      if (!mounted) {
        return;
      }

      await _loadAll(resetLedger: true);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  Future<void> _copyUserId() async {
    await Clipboard.setData(ClipboardData(text: widget.userId));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.userIdCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.initialSummary;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          summary == null
              ? context.l10n.userDetail
              : _localizedDisplayName(
                  context.l10n,
                  summary.resolvedDisplayName,
                ),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            onPressed: _isLoading ? null : () => _loadAll(resetLedger: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorState(
              message: _errorMessage!,
              onRetry: () => _loadAll(resetLedger: true),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final details = _details;
    if (details == null) {
      return const SizedBox.shrink();
    }

    final canMutateWallet = _canMutateWallet(details);
    final restrictionMessage = _walletRestrictionMessage(details);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileCard(details: details, onCopyUserId: _copyUserId),
              const SizedBox(height: 16),
              if (restrictionMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    adminWalletRestrictionLabel(
                      context.l10n,
                      restrictionMessage,
                    ),
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: canMutateWallet ? _openCoinCredit : null,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(context.l10n.creditCoins),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: canMutateWallet ? _openCoinDebit : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: Text(context.l10n.debitCoins),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF444444)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.coinLedger,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_ledgerEntries.isEmpty)
                const _LedgerEmptyState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _desktopBreakpoint) {
                      return _LedgerDataTable(entries: _ledgerEntries);
                    }

                    return _LedgerCardList(entries: _ledgerEntries);
                  },
                ),
              if (_hasMoreLedger && _ledgerEntries.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: _isLoadingMoreLedger ? null : _loadMoreLedger,
                    child: _isLoadingMoreLedger
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.details, required this.onCopyUserId});

  final AdminUserDetails details;
  final VoidCallback onCopyUserId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localizedDisplayName(context.l10n, details.resolvedDisplayName),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (details.adminRoleLabel != null) ...[
              const SizedBox(height: 8),
              AdminRoleBadge(
                label: _localizedRoleLabel(
                  context.l10n,
                  details.adminRoleLabel!,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              adminResolvedEmailLabel(context.l10n, details.resolvedEmailLabel),
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _MetaItem(
                  label: context.l10n.userId,
                  value: details.userId,
                  onCopy: onCopyUserId,
                  compact: true,
                ),
                _MetaItem(
                  label: context.l10n.accountStatus,
                  value: adminUserStatusLabel(
                    context.l10n,
                    details.accountStatusLabel,
                  ),
                ),
                _MetaItem(
                  label: context.l10n.registeredDate,
                  value: formatUserDateTime(details.accountCreatedAt),
                ),
                _MetaItem(
                  label: context.l10n.lastSignIn,
                  value: formatUserDateTime(details.lastSignInAt),
                ),
                _MetaItem(
                  label: context.l10n.currentCoinBalance,
                  value: context.l10n.coinsAmount(details.coinBalance),
                ),
                _MetaItem(
                  label: context.l10n.walletLastUpdate,
                  value: formatUserDateTime(details.walletUpdatedAt),
                ),
                _MetaItem(
                  label: context.l10n.totalLedgerRecords,
                  value: details.ledgerEntryCount.toString(),
                ),
                _MetaItem(
                  label: context.l10n.adminCreditTotal,
                  value: context.l10n.coinsAmount(
                    details.totalAdminCoinCredited,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    this.onCopy,
    this.compact = false,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final displayValue = compact ? shortenUserId(value) : value;

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFB3B3B3))),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  tooltip: context.l10n.copyUserId,
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerDataTable extends StatelessWidget {
  const _LedgerDataTable({required this.entries});

  final List<AdminWalletLedgerEntry> entries;

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
              DataColumn(label: Text(l10n.date)),
              DataColumn(label: Text(l10n.amount)),
              DataColumn(label: Text(l10n.type)),
              DataColumn(label: Text(l10n.reason)),
              DataColumn(label: Text(l10n.description)),
              DataColumn(label: Text(l10n.reference)),
              DataColumn(label: Text(l10n.previous)),
              DataColumn(label: Text(l10n.next)),
              DataColumn(label: Text(l10n.admin)),
            ],
            rows: [
              for (final entry in entries)
                DataRow(
                  cells: [
                    DataCell(Text(formatUserDateTime(entry.createdAt))),
                    DataCell(
                      Text(
                        entry.signedAmountLabel,
                        style: TextStyle(
                          color: entry.isCredit
                              ? const Color(0xFF6BD968)
                              : const Color(0xFFFF8A80),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(adminWalletTxnLabel(l10n, entry.transactionType)),
                    ),
                    DataCell(
                      Text(adminWalletReasonLabel(l10n, entry.reasonCode)),
                    ),
                    DataCell(Text(entry.descriptionLabel)),
                    DataCell(Text(entry.caseReferenceLabel)),
                    DataCell(Text(entry.balanceBeforeLabel)),
                    DataCell(Text(entry.balanceAfter.toString())),
                    DataCell(Text(adminLedgerActorLabel(l10n, entry))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerCardList extends StatelessWidget {
  const _LedgerCardList({required this.entries});

  final List<AdminWalletLedgerEntry> entries;

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
                  Row(
                    children: [
                      Text(
                        entry.signedAmountLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: entry.isCredit
                              ? const Color(0xFF6BD968)
                              : const Color(0xFFFF8A80),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatUserDateTime(entry.createdAt),
                        style: const TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${adminWalletTxnLabel(context.l10n, entry.transactionType)} · ${adminWalletReasonLabel(context.l10n, entry.reasonCode)}',
                  ),
                  if (entry.description != null &&
                      entry.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entry.description!),
                  ],
                  if (entry.caseReference != null &&
                      entry.caseReference!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.referencePrefixed(entry.caseReference!),
                      style: const TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.balanceArrow(
                      entry.balanceBeforeLabel,
                      entry.balanceAfter.toString(),
                    ),
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  Text(
                    '${context.l10n.admin}: ${adminLedgerActorLabel(context.l10n, entry)}',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
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

class _LedgerEmptyState extends StatelessWidget {
  const _LedgerEmptyState();

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
            context.l10n.noCoinMovements,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Color(0xFFE50914),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.userDetailLoadFailed),
              const SizedBox(height: 8),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFFE50914),
                ),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
