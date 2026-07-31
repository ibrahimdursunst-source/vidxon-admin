import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/admin_user_wallet_repository.dart';
import '../domain/admin_user_summary.dart';
import '../domain/user_parse_helpers.dart';
import 'admin_user_details_page.dart';
import 'user_search_request_guard.dart';
import 'user_list_search_logic.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({this.repository, super.key});

  final AdminUserWalletRepository? repository;

  @override
  AdminUsersPageState createState() => AdminUsersPageState();
}

class AdminUsersPageState extends State<AdminUsersPage> {
  static const _desktopBreakpoint = 900.0;
  static const _pageSize = 50;
  static const _debounceDuration = Duration(milliseconds: 400);

  late final AdminUserWalletRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounceTimer;
  final UserSearchRequestGuard _searchGuard = UserSearchRequestGuard();

  List<AdminUserSummary> _users = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _activeQuery = '';
  bool _searchListenerEnabled = false;
  String? _inFlightQuery;
  int? _inFlightGeneration;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AdminUserWalletRepository();
    unawaited(_loadInitialUsers());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController
      ..removeListener(_onSearchInputChanged)
      ..dispose();
    super.dispose();
  }

  void refresh() {
    _loadUsers(reset: true);
  }

  Future<void> _loadInitialUsers() async {
    await _loadUsers(reset: true);
    if (!mounted) {
      return;
    }

    _searchController.addListener(_onSearchInputChanged);
    _searchListenerEnabled = true;
  }

  void _onSearchInputChanged() {
    if (!_searchListenerEnabled) {
      return;
    }

    final query = _searchController.text.trim();
    if (shouldSkipDebouncedUserSearch(
      query: query,
      activeQuery: _activeQuery,
      isLoading: _isLoading,
      isLoadingMore: _isLoadingMore,
    )) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted || !_searchListenerEnabled) {
        return;
      }

      final debouncedQuery = _searchController.text.trim();
      if (shouldSkipDebouncedUserSearch(
        query: debouncedQuery,
        activeQuery: _activeQuery,
        isLoading: _isLoading,
        isLoadingMore: _isLoadingMore,
      )) {
        return;
      }

      unawaited(_loadUsers(reset: true));
    });
  }

  void _submitSearch() {
    _debounceTimer?.cancel();

    final query = _searchController.text.trim();
    if (shouldSkipDebouncedUserSearch(
          query: query,
          activeQuery: _activeQuery,
          isLoading: _isLoading,
          isLoadingMore: _isLoadingMore,
        ) &&
        _errorMessage == null) {
      return;
    }

    unawaited(_loadUsers(reset: true));
  }

  Future<void> _loadUsers({required bool reset}) async {
    final generation = _searchGuard.beginRequest();
    final query = _searchController.text.trim();

    if (shouldSkipDuplicateInFlightSearch(
      query: query,
      inFlightQuery: _inFlightQuery,
      isLoading: _isLoading,
      reset: reset,
    )) {
      return;
    }

    if (reset) {
      _inFlightQuery = query;
      _inFlightGeneration = generation;
    }

    setState(() {
      _errorMessage = null;
      if (reset) {
        _isLoading = true;
        _hasMore = true;
        _activeQuery = query;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final results = await _repository.searchUsers(
        query: reset ? query : _activeQuery,
        limit: _pageSize,
        offset: reset ? 0 : _users.length,
      );

      if (!mounted || !_searchGuard.shouldApplyResult(generation)) {
        return;
      }

      setState(() {
        if (reset) {
          _users = results;
        } else {
          _users = [..._users, ...results];
        }
        _hasMore = results.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });

      if (reset && _inFlightGeneration == generation) {
        _inFlightQuery = null;
        _inFlightGeneration = null;
      }
    } catch (error) {
      if (!mounted || !_searchGuard.shouldApplyResult(generation)) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (reset && _inFlightGeneration == generation) {
        _inFlightQuery = null;
        _inFlightGeneration = null;
      }
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();

    if (_searchController.text.isEmpty && _activeQuery.isEmpty) {
      return;
    }

    _searchListenerEnabled = false;
    _searchController.clear();
    _searchListenerEnabled = true;
    unawaited(_loadUsers(reset: true));
  }

  Future<void> _openUserDetails(AdminUserSummary user) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            AdminUserDetailsPage(userId: user.userId, initialSummary: user),
      ),
    );

    if (mounted) {
      refresh();
    }
  }

  Future<void> _copyUserId(String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kullanıcı ID kopyalandı.')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(onRefresh: refresh),
          const SizedBox(height: 24),
          _SearchBar(
            controller: _searchController,
            onClear: _clearSearch,
            onSubmitted: _submitSearch,
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            _ErrorState(message: _errorMessage!, onRetry: refresh)
          else if (_users.isEmpty)
            const _EmptyState()
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= _desktopBreakpoint) {
                  return _UsersDataTable(
                    users: _users,
                    onOpenDetails: _openUserDetails,
                    onCopyUserId: _copyUserId,
                  );
                }

                return _UsersCardList(
                  users: _users,
                  onOpenDetails: _openUserDetails,
                  onCopyUserId: _copyUserId,
                );
              },
            ),
            if (_hasMore) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: _isLoadingMore
                      ? null
                      : () => _loadUsers(reset: false),
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
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kullanıcılar',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kullanıcıları arayın, detaylarını görüntüleyin ve jeton yükleyin',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Yenile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF333333)),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final VoidCallback onSubmitted;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            onSubmitted: (_) => widget.onSubmitted(),
            decoration: InputDecoration(
              hintText: 'Kullanıcı ID, e-posta veya görünen ad ile ara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: const Color(0xFF181818),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: widget.onSubmitted,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          child: const Text('Ara'),
        ),
      ],
    );
  }
}

class _UsersDataTable extends StatelessWidget {
  const _UsersDataTable({
    required this.users,
    required this.onOpenDetails,
    required this.onCopyUserId,
  });

  final List<AdminUserSummary> users;
  final ValueChanged<AdminUserSummary> onOpenDetails;
  final ValueChanged<String> onCopyUserId;

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
              DataColumn(label: Text('Görünen Ad')),
              DataColumn(label: Text('E-posta')),
              DataColumn(label: Text('Kullanıcı ID')),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('Jeton')),
              DataColumn(label: Text('Kayıt')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: [
              for (final user in users)
                DataRow(
                  cells: [
                    DataCell(Text(user.resolvedDisplayName)),
                    DataCell(Text(user.resolvedEmailLabel)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(shortenUserId(user.userId)),
                          IconButton(
                            tooltip: 'Kullanıcı ID kopyala',
                            onPressed: () => onCopyUserId(user.userId),
                            icon: const Icon(Icons.copy, size: 18),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(user.accountStatusLabel)),
                    DataCell(Text(user.coinBalance.toString())),
                    DataCell(Text(formatUserDateTime(user.accountCreatedAt))),
                    DataCell(
                      TextButton(
                        onPressed: () => onOpenDetails(user),
                        child: const Text('Detay'),
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

class _UsersCardList extends StatelessWidget {
  const _UsersCardList({
    required this.users,
    required this.onOpenDetails,
    required this.onCopyUserId,
  });

  final List<AdminUserSummary> users;
  final ValueChanged<AdminUserSummary> onOpenDetails;
  final ValueChanged<String> onCopyUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final user in users) ...[
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
                    user.resolvedDisplayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.resolvedEmailLabel,
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: user.accountStatusLabel),
                      _InfoChip(label: '${user.coinBalance} jeton'),
                      _InfoChip(
                        label:
                            'Kayıt: ${formatUserDateTime(user.accountCreatedAt)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        shortenUserId(user.userId),
                        style: const TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                      IconButton(
                        tooltip: 'Kullanıcı ID kopyala',
                        onPressed: () => onCopyUserId(user.userId),
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => onOpenDetails(user),
                        child: const Text('Detay'),
                      ),
                    ],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 56, color: Color(0xFF555555)),
            SizedBox(height: 16),
            Text('Kullanıcı bulunamadı'),
            SizedBox(height: 8),
            Text(
              'Arama kriterlerinize uygun kullanıcı yok.',
              style: TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Color(0xFFE50914),
              ),
              const SizedBox(height: 16),
              const Text('Kullanıcılar yüklenemedi'),
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
