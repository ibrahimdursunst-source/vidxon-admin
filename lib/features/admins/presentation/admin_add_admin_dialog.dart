import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../../admin_context/domain/admin_role.dart';
import '../../users/data/admin_user_wallet_errors.dart';
import '../../users/data/admin_user_wallet_repository.dart';
import '../../users/domain/admin_user_summary.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../../users/presentation/admin_role_badge.dart';
import '../../users/presentation/user_list_search_logic.dart';
import '../../users/presentation/user_search_request_guard.dart';
import '../data/admin_management_repository.dart';

String _localizedDisplayName(AppLocalizations l10n, String name) {
  return name == 'Anonim Kullanıcı' ? l10n.anonymousUser : name;
}

String _localizedRoleLabel(AppLocalizations l10n, AdminRole role) {
  return switch (role) {
    AdminRole.admin => l10n.adminRole,
    AdminRole.superAdmin => l10n.superAdminRole,
  };
}

String _localizedRoleDescription(AppLocalizations l10n, AdminRole role) {
  return switch (role) {
    AdminRole.admin => l10n.adminRoleDescription,
    AdminRole.superAdmin => l10n.superAdminRoleDescription,
  };
}

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
        _selectedRole == AdminRole.superAdmin
            ? context.l10n.addedAsSuperAdmin(user.resolvedDisplayName)
            : context.l10n.addedAsAdmin(user.resolvedDisplayName),
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
        _errorMessage = context.l10n.networkDisconnected;
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
    _AddAdminStep.search => context.l10n.addAdmin,
    _AddAdminStep.role => context.l10n.selectRole,
    _AddAdminStep.confirm ||
    _AddAdminStep.submitting => context.l10n.confirmTitle,
  };

  List<Widget> _buildActions() {
    final isSubmitting = _step == _AddAdminStep.submitting;

    return [
      if (_step != _AddAdminStep.search)
        TextButton(
          onPressed: isSubmitting ? null : _goBack,
          child: Text(context.l10n.back),
        ),
      TextButton(
        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      if (_step == _AddAdminStep.role)
        FilledButton(
          onPressed: isSubmitting ? null : _goToConfirm,
          child: Text(context.l10n.continueShort),
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
              : Text(context.l10n.confirm),
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
        Text(
          context.l10n.searchByIdEmailName,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: context.l10n.searchQuery,
                  border: const OutlineInputBorder(),
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
                  : Text(context.l10n.search),
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
            Text(
              context.l10n.noResultsPeriod,
              style: const TextStyle(color: Color(0xFFB3B3B3)),
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
          Expanded(
            child: Text(
              _localizedDisplayName(context.l10n, user.resolvedDisplayName),
            ),
          ),
          if (user.adminRoleLabel != null)
            AdminRoleBadge(
              label: switch (user.adminRoleLabel!) {
                'Admin' => context.l10n.adminRole,
                'Super Admin' => context.l10n.superAdminRole,
                _ => user.adminRoleLabel!,
              },
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adminResolvedEmailLabel(context.l10n, user.resolvedEmailLabel),
            style: const TextStyle(color: Color(0xFFB3B3B3)),
          ),
          Text(
            shortenUserId(user.userId),
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
        ],
      ),
      trailing: canAdd
          ? FilledButton(
              onPressed: onSelect,
              child: Text(context.l10n.makeAdmin),
            )
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
        Text(
          context.l10n.targetNamed(
            _localizedDisplayName(context.l10n, user.resolvedDisplayName),
          ),
        ),
        Text(
          adminResolvedEmailLabel(context.l10n, user.resolvedEmailLabel),
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 16),
        SegmentedButton<AdminRole>(
          segments: [
            ButtonSegment(
              value: AdminRole.admin,
              label: Text(context.l10n.adminRole),
            ),
            ButtonSegment(
              value: AdminRole.superAdmin,
              label: Text(context.l10n.superAdminRole),
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
          _localizedRoleDescription(context.l10n, selectedRole),
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
        Text(
          context.l10n.userNamed(
            _localizedDisplayName(context.l10n, user.resolvedDisplayName),
          ),
        ),
        Text(
          context.l10n.emailNamed(
            adminResolvedEmailLabel(context.l10n, user.resolvedEmailLabel),
          ),
        ),
        Text(context.l10n.userIdNamed(shortenUserId(user.userId))),
        Text(
          context.l10n.roleToGrantPrefixed(
            _localizedRoleLabel(context.l10n, role),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _localizedRoleDescription(context.l10n, role),
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.thisGrantsAdminAccess,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!, style: const TextStyle(color: Color(0xFFFF8A8A))),
        ],
      ],
    );
  }
}
