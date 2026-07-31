import 'admin_coin_debit_reason.dart';
import 'user_parse_helpers.dart';

class AdminCoinDebitValidationException implements Exception {
  AdminCoinDebitValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdminCoinDebitInput {
  const AdminCoinDebitInput({
    required this.userId,
    required this.amount,
    required this.reason,
    required this.description,
    this.caseReference,
  });

  static const int minAmount = 1;
  static const int maxAmount = 1000000;
  static const int minDescriptionLength = 5;
  static const int maxDescriptionLength = 500;
  static const int maxCaseReferenceLength = 100;

  final String userId;
  final int amount;
  final AdminCoinDebitReason reason;
  final String description;
  final String? caseReference;

  String get payloadFingerprint {
    return [
      userId.trim(),
      amount.toString(),
      reason.storageValue,
      description.trim(),
      (caseReference ?? '').trim(),
    ].join('|');
  }

  int projectedBalance(int currentBalance) {
    if (amount > currentBalance) {
      throw AdminCoinDebitValidationException(
        'Kullanıcının bakiyesi bu işlem için yetersiz.',
      );
    }

    return currentBalance - amount;
  }

  void validate() {
    UserParseHelpers.requireUserId(userId);

    if (amount < minAmount || amount > maxAmount) {
      throw AdminCoinDebitValidationException(
        'Jeton miktarı $minAmount ile $maxAmount arasında olmalıdır.',
      );
    }

    final trimmedDescription = description.trim();
    if (trimmedDescription.length < minDescriptionLength ||
        trimmedDescription.length > maxDescriptionLength) {
      throw AdminCoinDebitValidationException(
        'Açıklama $minDescriptionLength–$maxDescriptionLength karakter olmalıdır.',
      );
    }

    final trimmedCaseReference = caseReference?.trim();
    if (trimmedCaseReference != null && trimmedCaseReference.isNotEmpty) {
      if (trimmedCaseReference.length > maxCaseReferenceLength) {
        throw AdminCoinDebitValidationException(
          'Destek referansı en fazla $maxCaseReferenceLength karakter olabilir.',
        );
      }
    }
  }
}

String? validateCoinDebitDescription(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.length < AdminCoinDebitInput.minDescriptionLength) {
    return 'Açıklama en az ${AdminCoinDebitInput.minDescriptionLength} karakter olmalıdır.';
  }

  if (trimmed.length > AdminCoinDebitInput.maxDescriptionLength) {
    return 'Açıklama en fazla ${AdminCoinDebitInput.maxDescriptionLength} karakter olabilir.';
  }

  return null;
}

Map<String, dynamic> buildDebitUserCoinsRpcParams({
  required AdminCoinDebitInput input,
  required String idempotencyKey,
}) {
  input.validate();

  final trimmedCaseReference = input.caseReference?.trim();

  return {
    'p_user_id': UserParseHelpers.requireUserId(input.userId),
    'p_amount': input.amount,
    'p_reason_code': input.reason.storageValue,
    'p_description': input.description.trim(),
    'p_idempotency_key': UserParseHelpers.requireUserId(
      idempotencyKey,
      fieldName: 'p_idempotency_key',
    ),
    'p_case_reference':
        trimmedCaseReference == null || trimmedCaseReference.isEmpty
        ? null
        : trimmedCaseReference,
  };
}
