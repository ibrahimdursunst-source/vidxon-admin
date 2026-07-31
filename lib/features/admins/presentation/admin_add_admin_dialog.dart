import 'dart:async';

import 'package:flutter/material.dart';

import '../../admin_context/domain/admin_role.dart';
import '../../users/data/admin_user_wallet_errors.dart';
import '../../users/data/admin_user_wallet_repository.dart';
import '../../users/domain/admin_user_summary.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../../users/presentation/admin_role_badge.dart';
import '../../users/presentation/user_list_search_logic.dart';
import '../../users/presentation/user_search_request_guard.dart';
import '../data/admin_management_repository.dart';

Future<String?> showAdminAddAdminDialog({
  required BuildContext context,
  AdminUserWalletRepository? userRepository,
  AdminManagementRepository? managementRepository,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _AdminAddAdminDialog(
        userRepository: userRepository ?? AdminUserWalletRepository(),
        managementRepository:
            managementRepository ?? AdminManagementRepository(),
      );
    },
  );
}

enum _AddAdminStep { search, role, confirm, submitting }

class _AdminAddAdminDialog extends StatefulWidget {
  const _AdminAddAdminDialog({
    required this.userRepository,
    required this.managementRepository,
  });

  final AdminUserWalletRepository userRepository;
  final AdminManagementRepository managementRepository;

  @override
  State<_AdminAddAdminDialog> createState() => _AdminAddAdminDialogState();
}

class _AdminAddAdminDialogState extends State<_AdminAddAdminDialog> {
  static const _pageSize = 50;
  static const _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _searchController = TextEditingController();
  final UserSearchRequestGuard _searchGuard = UserSearchRequestGuard();

  Timer? _debounceTimer;
  _AddAdminStep _step = _AddAdminStep.search;
  AdminUserSummary? _selectedUser;
  AdminRole _selectedRole = AdminRole.admin;
  String? _errorMessage;

  List<AdminUserSummary> _results = const [];
  bool _isSearching = false;
  String _activeQuery = '';
  String? _inFlightQuery;
  int? _inFlightGeneration;
  bool _searchListenerEnabled = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
    _searchListenerEnabled = true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController
      ..removeListener(_onSearchInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    if (!_searchListenerEnabled) {
      return;
    }

    final query = _searchController.text.trim();
    if (!isAdminAddSearchQueryReady(query)) {
      _debounceTimer?.cancel();
      return;
    }

    if (shouldSkipDebouncedUserSearch(
      query: query,
      activeQuery: _activeQuery,
      isLoading: _isSearching,
      isLoadingMore: false,
    )) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted || !_searchListenerEnabled) {
        return;
      }

      final debouncedQuery = _searchController.text.trim();
      if (!isAdminAddSearchQueryReady(debouncedQuery)) {
        return;
      }

      if (shouldSkipDebouncedUserSearch(
        query: debouncedQuery,
        activeQuery: _activeQuery,
        isLoading: _isSearching,
        isLoadingMore: false,
      )) {
        return;
      }

      unawaited(_searchUsers(reset: true));
    });
  }

  void _submitSearch() {
    _debounceTimer?.cancel();

    final query = _searchController.text.trim();
    if (!isAdminAddSearchQueryReady(query)) {
      return;
    }

    if (shouldSkipDebouncedUserSearch(
          query: query,
          activeQuery: _activeQuery,
          isLoading: _isSearching,
          isLoadingMore: false,
        ) &&
        _errorMessage == null) {
      return;
    }

    unawaited(_searchUsers(reset: true));
  }

  Future<void> _searchUsers({required bool reset}) async {
    if (!reset) {
      return;
    }

    final query = _searchController.text.trim();
    if (!isAdminAddSearchQueryReady(query)) {
      return;
    }

    if (shouldSkipDuplicateInFlightSearch(
      query: query,
      inFlightQuery: _inFlightQuery,
      isLoading: _isSearching,
      reset: reset,
    )) {
      return;
    }

    final generation = _searchGuard.beginRequest();
    _inFlightQuery = query;
    _inFlightGeneration = generation;

    setState(() {
      _errorMessage = null;
      _isSearching = true;
      _activeQuery = query;
    });

    try {
      final results = await widget.userRepository.searchUsers(
        query: query,
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted || !_searchGuard.shouldApplyResult(generation)) {
        return;
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });

      if (_inFlightGeneration == generation) {
        _inFlightQuery = null;
        _inFlightGeneration = null;
      }
    } catch (error) {
      if (!mounted || !_searchGuard.shouldApplyResult(generation)) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isSearching = false;
      });

      if (_inFlightGeneration == generation) {
        _inFlightQuery = null;
        _inFlightGeneration = null;
      }
    }
  }

  void _selectUser(AdminUserSummary user) {
    if (!canAddUserAsAdmin(user) || _step == _AddAdminStep.submitting) {
      return;
    }

    setState(() {
      _selectedUser = user;
      _selectedRole = AdminRole.admin;
      _step = _AddAdminStep.role;
      _errorMessage = null;
    });
  }

  void _goToConfirm() {
    if (_selectedUser == null || _step == _AddAdminStep.submitting) {
      return;
    }

    setState(() {
      _step = _AddAdminStep.confirm;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final user = _selectedUser;
    if (user == null || _step == _AddAdminStep.submitting) {
      return;
    }

    setState(() {
      _step = _AddAdminStep.submitting;
      _errorMessage = null;
    });

    try {
      await widget.managementRepository.setAdminRole(
        userId: user.userId,
        role: _selectedRole,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        buildAdminAddSuccessMessage(
          displayName: user.resolvedDisplayName,
          role: _selectedRole,
        ),
      );
    } on AdminUserWalletException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _step = _AddAdminStep.confirm;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _step = _AddAdminStep.confirm;
        _errorMessage = 'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.';
      });
    }
  }

  void _goBack() {
    if (_step == _AddAdminStep.submitting) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _step = switch (_step) {
        _AddAdminStep.role => _AddAdminStep.search,
        _AddAdminStep.confirm => _AddAdminStep.role,
        _ => _step,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: Text(_dialogTitle),
      content: SizedBox(
        width: 560,
        child: switch (_step) {
          _AddAdminStep.search => _SearchStep(
            controller: _searchController,
            isSearching: _isSearching,
            errorMessage: _errorMessage,
            results: _results,
            activeQuery: _activeQuery,
            onSubmitSearch: _submitSearch,
            onSelectUser: _selectUser,
          ),
          _AddAdminStep.role => _RoleStep(
            user: _selectedUser!,
            selectedRole: _selectedRole,
            onRoleChanged: (role) => setState(() => _selectedRole = role),
          ),
          _AddAdminStep.confirm || _AddAdminStep.submitting => _ConfirmStep(
            user: _selectedUser!,
            role: _selectedRole,
            errorMessage: _errorMessage,
          ),
        },
      ),
      actions: _buildActions(),
    );
  }

  String get _dialogTitle => switch (_step) {
    _AddAdminStep.search => 'Yönetici Ekle',
    _AddAdminStep.role => 'Rol Seç',
    _AddAdminStep.confirm || _AddAdminStep.submitting => 'Onay',
  };

  List<Widget> _buildActions() {
    final isSubmitting = _step == _AddAdminStep.submitting;

    return [
      if (_step != _AddAdminStep.search)
        TextButton(
          onPressed: isSubmitting ? null : _goBack,
          child: const Text('Geri'),
        ),
      TextButton(
        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        child: const Text('İptal'),
      ),
      if (_step == _AddAdminStep.role)
        FilledButton(
          onPressed: isSubmitting ? null : _goToConfirm,
          child: const Text('Devam'),
        ),
      if (_step == _AddAdminStep.confirm || _step == _AddAdminStep.submitting)
        FilledButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Onayla'),
        ),
    ];
  }
}

class _SearchStep extends StatelessWidget {
  const _SearchStep({
    required this.controller,
    required this.isSearching,
    required this.errorMessage,
    required this.results,
    required this.activeQuery,
    required this.onSubmitSearch,
    required this.onSelectUser,
  });

  final TextEditingController controller;
  final bool isSearching;
  final String? errorMessage;
  final List<AdminUserSummary> results;
  final String activeQuery;
  final VoidCallback onSubmitSearch;
  final ValueChanged<AdminUserSummary> onSelectUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Kullanıcı ID, e-posta veya görünen ad ile arayın.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Arama sorgusu',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSubmitSearch(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSubmitSearch,
              child: isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ara'),
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!, style: const TextStyle(color: Color(0xFFFF8A8A))),
        ],
        if (activeQuery.isNotEmpty && !isSearching && errorMessage == null) ...[
          const SizedBox(height: 16),
          if (results.isEmpty)
            const Text(
              'Sonuç bulunamadı.',
              style: TextStyle(color: Color(0xFFB3B3B3)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = results[index];
                  return _SearchResultTile(
                    user: user,
                    onSelect: () => onSelectUser(user),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.user, required this.onSelect});

  final AdminUserSummary user;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final canAdd = canAddUserAsAdmin(user);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(user.resolvedDisplayName)),
          if (user.adminRoleLabel != null)
            AdminRoleBadge(label: user.adminRoleLabel!),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.resolvedEmailLabel,
            style: const TextStyle(color: Color(0xFFB3B3B3)),
          ),
          Text(
            shortenUserId(user.userId),
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
        ],
      ),
      trailing: canAdd
          ? FilledButton(onPressed: onSelect, child: const Text('Yönetici Yap'))
          : null,
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({
    required this.user,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final AdminUserSummary user;
  final AdminRole selectedRole;
  final ValueChanged<AdminRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hedef: ${user.resolvedDisplayName}'),
        Text(
          user.resolvedEmailLabel,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 16),
        SegmentedButton<AdminRole>(
          segments: const [
            ButtonSegment(value: AdminRole.admin, label: Text('Admin')),
            ButtonSegment(
              value: AdminRole.superAdmin,
              label: Text('Super Admin'),
            ),
          ],
          selected: {selectedRole},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onRoleChanged(selection.first);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          adminRolePermissionDescription(selectedRole),
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.user,
    required this.role,
    required this.errorMessage,
  });

  final AdminUserSummary user;
  final AdminRole role;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kullanıcı: ${user.resolvedDisplayName}'),
        Text('E-posta: ${user.resolvedEmailLabel}'),
        Text('Kullanıcı ID: ${shortenUserId(user.userId)}'),
        Text('Verilecek rol: ${role.labelTurkish}'),
        const SizedBox(height: 12),
        Text(
          adminRolePermissionDescription(role),
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bu işlem kullanıcının mevcut hesabını, profilini, cüzdanını veya '
          'geçmişini değiştirmez. Kullanıcıya admin paneli erişimi verir.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!, style: const TextStyle(color: Color(0xFFFF8A8A))),
        ],
      ],
    );
  }
}
