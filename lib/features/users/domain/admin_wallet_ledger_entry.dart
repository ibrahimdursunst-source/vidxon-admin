import 'user_parse_helpers.dart';
import 'wallet_ledger_display.dart';

class AdminWalletLedgerEntry {
  const AdminWalletLedgerEntry({
    required this.ledgerId,
    required this.amount,
    required this.transactionType,
    required this.balanceAfter,
    required this.createdAt,
    this.reasonCode,
    this.description,
    this.caseReference,
    this.balanceBefore,
    this.actorAdminUserId,
  });

  final int ledgerId;
  final int amount;
  final String transactionType;
  final String? reasonCode;
  final String? description;
  final String? caseReference;
  final int? balanceBefore;
  final int balanceAfter;
  final String? actorAdminUserId;
  final DateTime createdAt;

  bool get isCredit => amount > 0;

  String get transactionTypeLabel =>
      WalletLedgerDisplay.transactionTypeLabel(transactionType);

  String get reasonLabel => WalletLedgerDisplay.reasonLabel(reasonCode);

  String get descriptionLabel => WalletLedgerDisplay.optionalText(description);

  String get caseReferenceLabel =>
      WalletLedgerDisplay.optionalText(caseReference);

  String get balanceBeforeLabel =>
      WalletLedgerDisplay.balanceBeforeLabel(balanceBefore);

  String get actorLabel => WalletLedgerDisplay.actorLabel(actorAdminUserId);

  String get signedAmountLabel {
    if (amount > 0) {
      return '+$amount';
    }

    if (amount < 0) {
      return amount.toString();
    }

    return '0';
  }

  factory AdminWalletLedgerEntry.fromMap(Map<String, dynamic> map) {
    return AdminWalletLedgerEntry(
      ledgerId: UserParseHelpers.parseBigIntField(
        map['ledger_id'],
        fieldName: 'ledger_id',
      ),
      amount: UserParseHelpers.parseInt(map['amount'], fieldName: 'amount'),
      transactionType: UserParseHelpers.requireString(
        map['transaction_type'],
        fieldName: 'transaction_type',
      ),
      reasonCode: UserParseHelpers.nullableString(map['reason_code']),
      description: UserParseHelpers.nullableString(map['description']),
      caseReference: UserParseHelpers.nullableString(map['case_reference']),
      balanceBefore: UserParseHelpers.parseNullableInt(
        map['balance_before'],
        fieldName: 'balance_before',
      ),
      balanceAfter: UserParseHelpers.parseInt(
        map['balance_after'],
        fieldName: 'balance_after',
      ),
      actorAdminUserId: UserParseHelpers.parseOptionalUserId(
        map['actor_admin_user_id'],
        fieldName: 'actor_admin_user_id',
      ),
      createdAt: UserParseHelpers.requireUtcDateTime(
        map['created_at'],
        fieldName: 'created_at',
      ),
    );
  }
}

Map<String, dynamic> buildListUserWalletLedgerRpcParams({
  required String userId,
  required int limit,
  required int offset,
}) {
  return {
    'p_user_id': UserParseHelpers.requireUserId(userId),
    'p_limit': limit,
    'p_offset': offset,
  };
}
