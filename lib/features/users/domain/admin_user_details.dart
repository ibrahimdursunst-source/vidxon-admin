import 'user_parse_helpers.dart';

class AdminUserDetails {
  const AdminUserDetails({
    required this.userId,
    required this.accountStatus,
    required this.coinBalance,
    required this.ledgerEntryCount,
    required this.totalAdminCoinCredited,
    required this.accountCreatedAt,
    this.email,
    this.displayName,
    this.lastSignInAt,
    this.walletUpdatedAt,
  });

  final String userId;
  final String? email;
  final String? displayName;
  final String accountStatus;
  final int coinBalance;
  final int ledgerEntryCount;
  final int totalAdminCoinCredited;
  final DateTime accountCreatedAt;
  final DateTime? lastSignInAt;
  final DateTime? walletUpdatedAt;

  String get resolvedDisplayName =>
      formatUserDisplayName(displayName: displayName, email: email);

  String get resolvedEmailLabel => formatUserEmailLabel(email);

  String get accountStatusLabel => formatAccountStatusLabel(accountStatus);

  factory AdminUserDetails.fromMap(Map<String, dynamic> map) {
    return AdminUserDetails(
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
      ledgerEntryCount: UserParseHelpers.parseInt(
        map['ledger_entry_count'],
        fieldName: 'ledger_entry_count',
      ),
      totalAdminCoinCredited: UserParseHelpers.parseInt(
        map['total_admin_coin_credited'],
        fieldName: 'total_admin_coin_credited',
      ),
      accountCreatedAt: UserParseHelpers.requireUtcDateTime(
        map['account_created_at'],
        fieldName: 'account_created_at',
      ),
      lastSignInAt: UserParseHelpers.parseUtcDateTime(map['last_sign_in_at']),
      walletUpdatedAt: UserParseHelpers.parseUtcDateTime(
        map['wallet_updated_at'],
      ),
    );
  }
}

Map<String, dynamic> buildGetUserDetailsRpcParams({required String userId}) {
  return {'p_user_id': UserParseHelpers.requireUserId(userId)};
}
