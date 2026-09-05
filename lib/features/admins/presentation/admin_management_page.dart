import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/admin_l10n.dart';
import '../../admin_context/domain/admin_role.dart';
import '../../admin_context/presentation/admin_context_scope.dart';
import '../../users/data/admin_user_wallet_repository.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../../users/presentation/admin_role_badge.dart';
import '../data/admin_management_repository.dart';
import '../domain/admin_account_summary.dart';
import 'admin_add_admin_dialog.dart';

String _localizedDisplayName(AppLocalizations l10n, String name) {
  return name == 'Anonim Kullanıcı' ? l10n.anonymousUser : name;
}

String _localizedRoleLabel(AppLocalizations l10n, AdminRole role) {
  return switch (role) {
    AdminRole.admin => l10n.adminRole,
    AdminRole.superAdmin => l10n.superAdminRole,
  };
}

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({
    this.repository,
    this.userSearchRepository,
    super.key,
  });

  final AdminManagementRepository? repository;
  final AdminUserWalletRepository? userSearchRepository;

  @override
  AdminManagementPageState createState() => AdminManagementPageState();
}

class AdminManagementPageState extends State<AdminManagementPage> {
  static const _desktopBreakpoint = 900.0;
  static const _pageSize = 50;

  late final AdminManagementRepository _repository =
      widget.repository ?? AdminManagementRepository();

  List<AdminAccountSummary> _admins = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _loadGeneration = 0;

  bool _initialLoadScheduled = false;

  bool _canAccessSuperAdmin(BuildContext context) {
    final result = AdminContextScope.maybeOf(context);
    return result != null && !result.isLoading && result.isSuperAdmin;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    context.dependOnInheritedWidgetOfExactType<AdminContextScope>();
    _maybeScheduleInitialLoad();
  }

  void _maybeScheduleInitialLoad() {
    if (_initialLoadScheduled) {
      return;
    }

    final contextResult = AdminContextScope.maybeOf(context);
    if (contextResult == null || contextResult.isLoading) {
      return;
    }

    _initialLoadScheduled = true;

    if (_canAccessSuperAdmin(context)) {
      _load(reset: true);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void refresh() {
    if (!_canAccessSuperAdmin(context)) {
      return;
    }

    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (!_canAccessSuperAdmin(context)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      return;
    }

    final generation = reset ? ++_loadGeneration : _loadGeneration;

    setState(() {
      _errorMessage = null;
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final admins = await _repository.listAdminUsers(
        limit: _pageSize,
        offset: reset ? 0 : _admins.length,
      );

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        if (reset) {
          _admins = admins;
        } else {
          _admins = [..._admins, ...admins];
        }
        _hasMore = admins.length >= _pageSize;
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

  String? get _currentUserId =>
      AdminContextScope.maybeOf(context)?.context?.userId;

  bool _isSelf(AdminAccountSummary admin) =>
      _currentUserId != null && admin.userId == _currentUserId;

  Future<void> _setRole(AdminAccountSummary admin, AdminRole newRole) async {
    if (_isSelf(admin)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text(l10n.confirmRoleChange),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.targetNamed(
                  _localizedDisplayName(l10n, admin.resolvedDisplayName),
                ),
              ),
              Text(
                l10n.currentRolePrefixed(_localizedRoleLabel(l10n, admin.role)),
              ),
              Text(l10n.newRole(_localizedRoleLabel(l10n, newRole))),
              const SizedBox(height: 12),
              Text(
                l10n.roleChangeAffectsPermissions,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _repository.setAdminRole(userId: admin.userId, role: newRole);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.roleUpdated)));
      await _load(reset: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _revokeAccess(AdminAccountSummary admin) async {
    if (_isSelf(admin)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text(l10n.revokeAdminAccess),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.targetNamed(
                  _localizedDisplayName(l10n, admin.resolvedDisplayName),
                ),
              ),
              Text(
                l10n.currentRolePrefixed(_localizedRoleLabel(l10n, admin.role)),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.revokeAccessDoesNotDelete,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.revokeAccess),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _repository.revokeAdminAccess(userId: admin.userId);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.adminAccessRevoked)));
      await _load(reset: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _copyUserId(String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.userIdCopied)));
  }

  Future<void> _openAddAdminDialog() async {
    if (!_canAccessSuperAdmin(context)) {
      return;
    }

    final message = await showAdminAddAdminDialog(
      context: context,
      userRepository: widget.userSearchRepository,
      managementRepository: _repository,
    );

    if (message == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final contextResult = AdminContextScope.maybeOf(context);

    if (contextResult == null || contextResult.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!contextResult.isSuperAdmin) {
      return const _AccessDeniedState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: () => _load(reset: true),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.adminsTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.adminsSubtitle,
                            style: const TextStyle(color: Color(0xFFB3B3B3)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _canAccessSuperAdmin(context)
                          ? _openAddAdminDialog
                          : null,
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(context.l10n.addAdmin),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_admins.isEmpty)
                  _EmptyState()
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= _desktopBreakpoint) {
                        return _AdminDataTable(
                          admins: _admins,
                          isSelf: _isSelf,
                          onCopyUserId: _copyUserId,
                          onSetRole: _setRole,
                          onRevoke: _revokeAccess,
                        );
                      }

                      return _AdminCardList(
                        admins: _admins,
                        isSelf: _isSelf,
                        onCopyUserId: _copyUserId,
                        onSetRole: _setRole,
                        onRevoke: _revokeAccess,
                      );
                    },
                  ),
                if (_hasMore && _admins.isNotEmpty) ...[
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
      ),
    );
  }
}

class _AccessDeniedState extends StatelessWidget {
  const _AccessDeniedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.superAdminRequired,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
        ),
      ),
    );
  }
}

class _AdminDataTable extends StatelessWidget {
  const _AdminDataTable({
    required this.admins,
    required this.isSelf,
    required this.onCopyUserId,
    required this.onSetRole,
    required this.onRevoke,
  });

  final List<AdminAccountSummary> admins;
  final bool Function(AdminAccountSummary admin) isSelf;
  final ValueChanged<String> onCopyUserId;
  final Future<void> Function(AdminAccountSummary admin, AdminRole role)
  onSetRole;
  final Future<void> Function(AdminAccountSummary admin) onRevoke;

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
            columnSpacing: 24,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(const Color(0xFF181818)),
            columns: [
              DataColumn(label: Text(l10n.manager)),
              DataColumn(label: Text(l10n.role)),
              DataColumn(label: Text(l10n.becameAdmin)),
              DataColumn(label: Text(l10n.accountCreated)),
              DataColumn(label: Text(l10n.lastSignIn)),
              DataColumn(label: Text(l10n.userId)),
              DataColumn(label: Text(l10n.actionsColumn)),
            ],
            rows: [
              for (final admin in admins)
                DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          '${_localizedDisplayName(l10n, admin.resolvedDisplayName)}\n'
                          '${adminResolvedEmailLabel(l10n, admin.resolvedEmailLabel)}',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                    ),
                    DataCell(
                      AdminRoleBadge(
                        label: _localizedRoleLabel(l10n, admin.role),
                      ),
                    ),
                    DataCell(Text(formatUserDateTime(admin.adminCreatedAt))),
                    DataCell(Text(formatUserDateTime(admin.accountCreatedAt))),
                    DataCell(Text(formatUserDateTime(admin.lastSignInAt))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(shortenUserId(admin.userId)),
                          IconButton(
                            tooltip: l10n.copyUserId,
                            onPressed: () => onCopyUserId(admin.userId),
                            icon: const Icon(Icons.copy, size: 18),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: _AdminActions(
                          admin: admin,
                          isSelf: isSelf(admin),
                          onSetRole: onSetRole,
                          onRevoke: onRevoke,
                        ),
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

class _AdminCardList extends StatelessWidget {
  const _AdminCardList({
    required this.admins,
    required this.isSelf,
    required this.onCopyUserId,
    required this.onSetRole,
    required this.onRevoke,
  });

  final List<AdminAccountSummary> admins;
  final bool Function(AdminAccountSummary admin) isSelf;
  final ValueChanged<String> onCopyUserId;
  final Future<void> Function(AdminAccountSummary admin, AdminRole role)
  onSetRole;
  final Future<void> Function(AdminAccountSummary admin) onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        for (final admin in admins) ...[
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
                      Expanded(
                        child: Text(
                          _localizedDisplayName(
                            l10n,
                            admin.resolvedDisplayName,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      AdminRoleBadge(
                        label: _localizedRoleLabel(l10n, admin.role),
                      ),
                    ],
                  ),
                  Text(
                    adminResolvedEmailLabel(l10n, admin.resolvedEmailLabel),
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.becameAdminAt(
                      formatUserDateTime(admin.adminCreatedAt),
                    ),
                  ),
                  Text(
                    l10n.lastSignInAt(formatUserDateTime(admin.lastSignInAt)),
                  ),
                  Row(
                    children: [
                      Text(
                        shortenUserId(admin.userId),
                        style: const TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                      IconButton(
                        onPressed: () => onCopyUserId(admin.userId),
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                    ],
                  ),
                  _AdminActions(
                    admin: admin,
                    isSelf: isSelf(admin),
                    onSetRole: onSetRole,
                    onRevoke: onRevoke,
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

enum _AdminAction { setAdmin, setSuperAdmin, revoke }

class _AdminActions extends StatelessWidget {
  const _AdminActions({
    required this.admin,
    required this.isSelf,
    required this.onSetRole,
    required this.onRevoke,
  });

  final AdminAccountSummary admin;
  final bool isSelf;
  final Future<void> Function(AdminAccountSummary admin, AdminRole role)
  onSetRole;
  final Future<void> Function(AdminAccountSummary admin) onRevoke;

  @override
  Widget build(BuildContext context) {
    if (isSelf) {
      return Text(
        context.l10n.yourAccount,
        style: const TextStyle(color: Color(0xFFB3B3B3)),
      );
    }

    return PopupMenuButton<_AdminAction>(
      tooltip: context.l10n.actions,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _AdminAction.setAdmin:
            unawaited(onSetRole(admin, AdminRole.admin));
          case _AdminAction.setSuperAdmin:
            unawaited(onSetRole(admin, AdminRole.superAdmin));
          case _AdminAction.revoke:
            unawaited(onRevoke(admin));
        }
      },
      itemBuilder: (context) {
        final l10n = context.l10n;
        return [
          if (admin.role != AdminRole.admin)
            PopupMenuItem(
              value: _AdminAction.setAdmin,
              child: Text(l10n.makeAdminAction),
            ),
          if (admin.role != AdminRole.superAdmin)
            PopupMenuItem(
              value: _AdminAction.setSuperAdmin,
              child: Text(l10n.makeSuperAdmin),
            ),
          PopupMenuItem(
            value: _AdminAction.revoke,
            child: Text(l10n.revokeAccess),
          ),
        ];
      },
    );
  }
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
            context.l10n.noAdminsFound,
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
