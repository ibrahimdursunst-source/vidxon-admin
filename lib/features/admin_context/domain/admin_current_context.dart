import '../../users/domain/user_parse_helpers.dart';
import 'admin_role.dart';

class AdminCurrentContext {
  const AdminCurrentContext({
    required this.userId,
    required this.role,
    required this.isSuperAdmin,
  });

  final String userId;
  final AdminRole role;
  final bool isSuperAdmin;

  factory AdminCurrentContext.fromMap(Map<String, dynamic> map) {
    final userId = UserParseHelpers.requireUserId(map['user_id']);
    final role = AdminRole.parseRequired(map['role'], fieldName: 'role');

    if (map['is_super_admin'] is! bool) {
      throw FormatException('is_super_admin is invalid.');
    }

    final isSuperAdmin = map['is_super_admin'] as bool;

    final expectedSuperAdmin = role == AdminRole.superAdmin;
    if (isSuperAdmin != expectedSuperAdmin) {
      throw FormatException('role and is_super_admin are inconsistent.');
    }

    return AdminCurrentContext(
      userId: userId,
      role: role,
      isSuperAdmin: isSuperAdmin,
    );
  }
}
