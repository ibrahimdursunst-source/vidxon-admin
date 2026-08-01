import '../../admin_context/domain/admin_role.dart';
import '../../users/domain/user_parse_helpers.dart';

class AdminAccountSummary {
  const AdminAccountSummary({
    required this.userId,
    required this.role,
    required this.adminCreatedAt,
    required this.accountCreatedAt,
    this.email,
    this.displayName,
    this.lastSignInAt,
  });

  final String userId;
  final String? email;
  final String? displayName;
  final AdminRole role;
  final DateTime adminCreatedAt;
  final DateTime accountCreatedAt;
  final DateTime? lastSignInAt;

  String get resolvedDisplayName =>
      formatUserDisplayName(displayName: displayName, email: email);

  String get resolvedEmailLabel => formatUserEmailLabel(email);

  String get roleLabel => role.labelTurkish;

  factory AdminAccountSummary.fromMap(Map<String, dynamic> map) {
    return AdminAccountSummary(
      userId: UserParseHelpers.requireUserId(map['user_id']),
      email: UserParseHelpers.parseNullableEmail(map['email']),
      displayName: UserParseHelpers.parseNullableDisplayName(
        map['display_name'],
      ),
      role: AdminRole.parseRequired(map['role'], fieldName: 'role'),
      adminCreatedAt: UserParseHelpers.requireUtcDateTime(
        map['admin_created_at'],
        fieldName: 'admin_created_at',
      ),
      accountCreatedAt: UserParseHelpers.requireUtcDateTime(
        map['account_created_at'],
        fieldName: 'account_created_at',
      ),
      lastSignInAt: UserParseHelpers.parseUtcDateTime(map['last_sign_in_at']),
    );
  }
}

Map<String, dynamic> buildListAdminUsersRpcParams({
  required int limit,
  required int offset,
}) {
  return {'p_limit': limit, 'p_offset': offset};
}

Map<String, dynamic> buildSetAdminRoleRpcParams({
  required String userId,
  required AdminRole role,
}) {
  return {
    'p_user_id': UserParseHelpers.requireUserId(userId),
    'p_role': role.storageValue,
  };
}

Map<String, dynamic> buildRevokeAdminAccessRpcParams({required String userId}) {
  return {'p_user_id': UserParseHelpers.requireUserId(userId)};
}
