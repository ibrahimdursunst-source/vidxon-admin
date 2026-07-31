import 'user_parse_helpers.dart';

class AdminCoinCreditResult {
  const AdminCoinCreditResult({
    required this.ledgerId,
    required this.userId,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.transactionType,
    required this.reasonCode,
    required this.wasReplayed,
    this.createdAt,
  });

  final int ledgerId;
  final String userId;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String transactionType;
  final String reasonCode;
  final bool wasReplayed;
  final DateTime? createdAt;

  factory AdminCoinCreditResult.fromMap(Map<String, dynamic> map) {
    return AdminCoinCreditResult(
      ledgerId: UserParseHelpers.parseBigIntField(
        map['ledger_id'],
        fieldName: 'ledger_id',
      ),
      userId: UserParseHelpers.requireUserId(map['user_id']),
      amount: UserParseHelpers.parseInt(map['amount'], fieldName: 'amount'),
      balanceBefore: UserParseHelpers.parseInt(
        map['balance_before'],
        fieldName: 'balance_before',
      ),
      balanceAfter: UserParseHelpers.parseInt(
        map['balance_after'],
        fieldName: 'balance_after',
      ),
      transactionType: UserParseHelpers.requireString(
        map['transaction_type'],
        fieldName: 'transaction_type',
      ),
      reasonCode: UserParseHelpers.requireString(
        map['reason_code'],
        fieldName: 'reason_code',
      ),
      wasReplayed: map['was_replayed'] == true,
      createdAt: UserParseHelpers.parseUtcDateTime(map['created_at']),
    );
  }
}
