import 'admin_coin_credit_reason.dart';
import 'user_parse_helpers.dart';

class AdminCoinCreditValidationException implements Exception {
  AdminCoinCreditValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdminCoinCreditInput {
  const AdminCoinCreditInput({
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
  final AdminCoinCreditReason reason;
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
    final result = currentBalance + amount;
    if (result < currentBalance) {
      throw AdminCoinCreditValidationException(
        'Yeni bakiye hesaplanamadı. Lütfen daha küçük bir miktar deneyin.',
      );
    }

    return result;
  }

  void validate() {
    UserParseHelpers.requireUserId(userId);

    if (amount < minAmount || amount > maxAmount) {
      throw AdminCoinCreditValidationException(
        'Jeton miktarı $minAmount ile $maxAmount arasında olmalıdır.',
      );
    }

    final trimmedDescription = description.trim();
    if (trimmedDescription.length < minDescriptionLength ||
        trimmedDescription.length > maxDescriptionLength) {
      throw AdminCoinCreditValidationException(
        'Açıklama $minDescriptionLength–$maxDescriptionLength karakter olmalıdır.',
      );
    }

    final trimmedCaseReference = caseReference?.trim();
    if (trimmedCaseReference != null && trimmedCaseReference.isNotEmpty) {
      if (trimmedCaseReference.length > maxCaseReferenceLength) {
        throw AdminCoinCreditValidationException(
          'Destek referansı en fazla $maxCaseReferenceLength karakter olabilir.',
        );
      }
    }
  }
}

String? validateCoinAmountText(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Jeton miktarı zorunludur.';
  }

  if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
    return 'Jeton miktarı yalnızca tam sayı olmalıdır.';
  }

  final parsed = int.tryParse(trimmed);
  if (parsed == null) {
    return 'Jeton miktarı geçersiz.';
  }

  if (parsed < AdminCoinCreditInput.minAmount) {
    return 'Jeton miktarı en az ${AdminCoinCreditInput.minAmount} olmalıdır.';
  }

  if (parsed > AdminCoinCreditInput.maxAmount) {
    return 'Jeton miktarı en fazla ${AdminCoinCreditInput.maxAmount} olabilir.';
  }

  return null;
}

String? validateCoinCreditDescription(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.length < AdminCoinCreditInput.minDescriptionLength) {
    return 'Açıklama en az ${AdminCoinCreditInput.minDescriptionLength} karakter olmalıdır.';
  }

  if (trimmed.length > AdminCoinCreditInput.maxDescriptionLength) {
    return 'Açıklama en fazla ${AdminCoinCreditInput.maxDescriptionLength} karakter olabilir.';
  }

  return null;
}

String? validateCaseReference(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  if (trimmed.length > AdminCoinCreditInput.maxCaseReferenceLength) {
    return 'Destek referansı en fazla ${AdminCoinCreditInput.maxCaseReferenceLength} karakter olabilir.';
  }

  return null;
}

Map<String, dynamic> buildCreditUserCoinsRpcParams({
  required AdminCoinCreditInput input,
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
