import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/dashboard/presentation/admin_home_page.dart';

import '../../content/content_test_helpers.dart';

AdminCurrentContext _context({required bool superAdmin}) {
  return AdminCurrentContext.fromMap({
    'user_id': '11111111-1111-1111-1111-111111111111',
    'role': superAdmin ? 'super_admin' : 'admin',
    'is_super_admin': superAdmin,
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required AdminCurrentContext context,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdminContextScope(
        contextResult: AdminContextLoadResult.loaded(context),
        child: AdminHomePage(
          email: 'admin@example.com',
          dashboardRepository: FakeDashboardRepository(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureContentWidgetTests);

  testWidgets('normal admin does not see Kampanyalar navigation', (tester) async {
    await _pumpHome(tester, context: _context(superAdmin: false));
    expect(find.text('Kampanyalar'), findsNothing);
  });

  testWidgets('super admin sees Kampanyalar navigation', (tester) async {
    await _pumpHome(tester, context: _context(superAdmin: true));
    expect(find.text('Kampanyalar'), findsOneWidget);
  });
}
