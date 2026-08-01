import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_role.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  group('AdminCurrentContext.fromMap', () {
    test('parses admin context', () {
      final context = AdminCurrentContext.fromMap({
        'user_id': userId,
        'role': 'admin',
        'is_super_admin': false,
      });

      expect(context.userId, userId);
      expect(context.role, AdminRole.admin);
      expect(context.isSuperAdmin, isFalse);
    });

    test('parses super admin context', () {
      final context = AdminCurrentContext.fromMap({
        'user_id': userId,
        'role': 'super_admin',
        'is_super_admin': true,
      });

      expect(context.role, AdminRole.superAdmin);
      expect(context.isSuperAdmin, isTrue);
    });

    test('rejects inconsistent role and is_super_admin', () {
      expect(
        () => AdminCurrentContext.fromMap({
          'user_id': userId,
          'role': 'admin',
          'is_super_admin': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown role', () {
      expect(
        () => AdminCurrentContext.fromMap({
          'user_id': userId,
          'role': 'owner',
          'is_super_admin': false,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty role', () {
      expect(
        () => AdminCurrentContext.fromMap({
          'user_id': userId,
          'role': '',
          'is_super_admin': false,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
