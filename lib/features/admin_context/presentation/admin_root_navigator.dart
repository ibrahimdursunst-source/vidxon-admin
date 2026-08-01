import 'package:flutter/material.dart';

import '../../dashboard/presentation/admin_home_page.dart';

/// Keeps all authenticated admin routes under the same [Navigator] subtree so
/// pushed pages (for example [AdminUserDetailsPage]) remain descendants of
/// [AdminContextScope].
class AdminRootNavigator extends StatelessWidget {
  const AdminRootNavigator({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AdminHomePage(email: email),
        );
      },
    );
  }
}
