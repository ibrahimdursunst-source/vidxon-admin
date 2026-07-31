import '../../admin_context/domain/admin_role.dart';
import 'user_parse_helpers.dart';

class AdminUserSummary {
  const AdminUserSummary({
    required this.userId,
    required this.accountStatus,
    required this.coinBalance,
    required this.accountCreatedAt,
    required this.walletActionsAllowed,
    this.email,
    this.displayName,
    this.lastSignInAt,
    this.adminRole,
  });

  final String userId;
  final String? email;
  final String? displayName;
  final String accountStatus;
  final int coinBalance;
  final DateTime accountCreatedAt;
  final DateTime? lastSignInAt;
  final AdminRole? adminRole;
  final bool walletActionsAllowed;

  String get resolvedDisplayName =>
      formatUserDisplayName(displayName: displayName, email: email);

  String get resolvedEmailLabel => formatUserEmailLabel(email);

  String get accountStatusLabel => formatAccountStatusLabel(accountStatus);

  String? get adminRoleLabel =>
      adminRole == null ? null : formatAdminRoleLabel(adminRole);

  factory AdminUserSummary.fromMap(Map<String, dynamic> map) {
    return AdminUserSummary(
      userId: UserParseHelpers.requireUserId(map['user_id']),
      email: UserParseHelpers.parseNullableEmail(map['email']),
      displayName: UserParseHelpers.parseNullableDisplayName(
        map['display_name'],
      ),
      accountStatus: UserParseHelpers.requireString(
        map['account_status'],
        fieldName: 'account_status',
      ),
      coinBalance: UserParseHelpers.parseInt(
        map['coin_balance'],
        fieldName: 'coin_balance',
      ),
      accountCreatedAt: UserParseHelpers.requireUtcDateTime(
        map['account_created_at'],
        fieldName: 'account_created_at',
      ),
      lastSignInAt: UserParseHelpers.parseUtcDateTime(map['last_sign_in_at']),
      adminRole: AdminRole.parseNullable(map['admin_role']),
      walletActionsAllowed: UserParseHelpers.requireBool(
        map['wallet_actions_allowed'],
        fieldName: 'wallet_actions_allowed',
      ),
    );
  }
}

Map<String, dynamic> buildSearchUsersRpcParams({
  required String query,
  required int limit,
  required int offset,
}) {
  return {'p_query': query.trim(), 'p_limit': limit, 'p_offset': offset};
}
