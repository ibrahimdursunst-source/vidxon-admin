import 'user_parse_helpers.dart';

class AdminCoinDebitResult {
  const AdminCoinDebitResult({
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

  factory AdminCoinDebitResult.fromMap(Map<String, dynamic> map) {
    final amount = UserParseHelpers.parseInt(
      map['amount'],
      fieldName: 'amount',
    );
    if (amount >= 0) {
      throw FormatException('amount must be negative for debit.');
    }

    final balanceAfter = UserParseHelpers.parseInt(
      map['balance_after'],
      fieldName: 'balance_after',
    );
    if (balanceAfter < 0) {
      throw FormatException('balance_after must be non-negative.');
    }

    final transactionType = UserParseHelpers.requireString(
      map['transaction_type'],
      fieldName: 'transaction_type',
    );
    if (transactionType != 'admin_coin_debit') {
      throw FormatException('transaction_type must be admin_coin_debit.');
    }

    return AdminCoinDebitResult(
      ledgerId: UserParseHelpers.parseBigIntField(
        map['ledger_id'],
        fieldName: 'ledger_id',
      ),
      userId: UserParseHelpers.requireUserId(map['user_id']),
      amount: amount,
      balanceBefore: UserParseHelpers.parseInt(
        map['balance_before'],
        fieldName: 'balance_before',
      ),
      balanceAfter: balanceAfter,
      transactionType: transactionType,
      reasonCode: UserParseHelpers.requireString(
        map['reason_code'],
        fieldName: 'reason_code',
      ),
      wasReplayed: map['was_replayed'] == true,
      createdAt: UserParseHelpers.parseUtcDateTime(map['created_at']),
    );
  }
}
