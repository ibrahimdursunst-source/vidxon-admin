import 'package:flutter/material.dart';

import '../../users/data/admin_user_wallet_errors.dart';
import '../data/admin_context_repository.dart';
import '../domain/admin_current_context.dart';

class AdminContextScope extends InheritedWidget {
  const AdminContextScope({
    required this.contextResult,
    required super.child,
    super.key,
  });

  final AdminContextLoadResult contextResult;

  static AdminContextLoadResult of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminContextScope>();
    assert(scope != null, 'AdminContextScope not found');
    return scope!.contextResult;
  }

  static AdminContextLoadResult? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminContextScope>()
        ?.contextResult;
  }

  @override
  bool updateShouldNotify(AdminContextScope oldWidget) {
    return contextResult != oldWidget.contextResult;
  }
}

class AdminContextLoadResult {
  const AdminContextLoadResult.loading()
    : context = null,
      errorMessage = null,
      isLoading = true;

  const AdminContextLoadResult.loaded(this.context)
    : errorMessage = null,
      isLoading = false;

  const AdminContextLoadResult.error(this.errorMessage)
    : context = null,
      isLoading = false;

  final AdminCurrentContext? context;
  final String? errorMessage;
  final bool isLoading;

  bool get isSuperAdmin => context?.isSuperAdmin ?? false;

  bool get hasContext => context != null;
}

class AdminContextLoader extends StatefulWidget {
  const AdminContextLoader({required this.child, this.repository, super.key});

  final Widget child;
  final AdminContextRepository? repository;

  @override
  State<AdminContextLoader> createState() => _AdminContextLoaderState();
}

class _AdminContextLoaderState extends State<AdminContextLoader> {
  late final AdminContextRepository _repository =
      widget.repository ?? AdminContextRepository();

  AdminContextLoadResult _result = const AdminContextLoadResult.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _result = const AdminContextLoadResult.loading());

    try {
      final context = await _repository.getCurrentContext();
      if (!mounted) {
        return;
      }

      setState(() => _result = AdminContextLoadResult.loaded(context));
    } on AdminUserWalletException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _result = AdminContextLoadResult.error(error.message));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(
        () => _result = const AdminContextLoadResult.error(
          'Admin oturum bilgisi yüklenemedi.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminContextScope(contextResult: _result, child: widget.child);
  }
}
