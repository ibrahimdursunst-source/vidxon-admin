import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/admin_user_wallet_repository.dart';
import '../domain/admin_user_details.dart';
import '../domain/admin_user_summary.dart';
import '../domain/admin_wallet_ledger_entry.dart';
import '../domain/user_parse_helpers.dart';
import 'admin_coin_credit_dialog.dart';

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

  Future<void> _openCoinCredit() async {
    final details = _details;
    if (details == null) {
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
    ).showSnackBar(const SnackBar(content: Text('Kullanıcı ID kopyalandı.')));
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.initialSummary;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(summary?.resolvedDisplayName ?? 'Kullanıcı Detayı'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
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
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _openCoinCredit,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Jeton Yükle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Jeton Hareket Geçmişi',
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
              details.resolvedDisplayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details.resolvedEmailLabel,
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _MetaItem(
                  label: 'Kullanıcı ID',
                  value: details.userId,
                  onCopy: onCopyUserId,
                  compact: true,
                ),
                _MetaItem(
                  label: 'Hesap durumu',
                  value: details.accountStatusLabel,
                ),
                _MetaItem(
                  label: 'Kayıt tarihi',
                  value: formatUserDateTime(details.accountCreatedAt),
                ),
                _MetaItem(
                  label: 'Son giriş',
                  value: formatUserDateTime(details.lastSignInAt),
                ),
                _MetaItem(
                  label: 'Güncel jeton bakiyesi',
                  value: '${details.coinBalance} jeton',
                ),
                _MetaItem(
                  label: 'Wallet son güncelleme',
                  value: formatUserDateTime(details.walletUpdatedAt),
                ),
                _MetaItem(
                  label: 'Toplam ledger kaydı',
                  value: details.ledgerEntryCount.toString(),
                ),
                _MetaItem(
                  label: 'Admin yüklemesi toplamı',
                  value: '${details.totalAdminCoinCredited} jeton',
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
                  tooltip: 'Kullanıcı ID kopyala',
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
              DataColumn(label: Text('Tarih')),
              DataColumn(label: Text('Miktar')),
              DataColumn(label: Text('Tür')),
              DataColumn(label: Text('Neden')),
              DataColumn(label: Text('Açıklama')),
              DataColumn(label: Text('Referans')),
              DataColumn(label: Text('Önceki')),
              DataColumn(label: Text('Sonraki')),
              DataColumn(label: Text('Admin')),
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
                    DataCell(Text(entry.transactionTypeLabel)),
                    DataCell(Text(entry.reasonLabel)),
                    DataCell(Text(entry.descriptionLabel)),
                    DataCell(Text(entry.caseReferenceLabel)),
                    DataCell(Text(entry.balanceBeforeLabel)),
                    DataCell(Text(entry.balanceAfter.toString())),
                    DataCell(
                      Text(
                        entry.actorAdminUserId == null
                            ? entry.actorLabel
                            : shortenUserId(entry.actorAdminUserId!),
                      ),
                    ),
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
                  Text('${entry.transactionTypeLabel} · ${entry.reasonLabel}'),
                  if (entry.description != null &&
                      entry.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entry.description!),
                  ],
                  if (entry.caseReference != null &&
                      entry.caseReference!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Referans: ${entry.caseReference!}',
                      style: const TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Bakiye: ${entry.balanceBeforeLabel} → ${entry.balanceAfter}',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  Text(
                    'Admin: ${entry.actorAdminUserId == null ? entry.actorLabel : shortenUserId(entry.actorAdminUserId!)}',
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
            'Henüz jeton hareketi yok.',
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
              const Text('Kullanıcı detayı yüklenemedi'),
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
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
