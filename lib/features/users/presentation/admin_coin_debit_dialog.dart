import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/admin_user_wallet_errors.dart';
import '../data/admin_user_wallet_repository.dart';
import '../domain/admin_coin_debit_input.dart';
import '../domain/admin_coin_debit_reason.dart';
import '../domain/admin_coin_credit_input.dart';
import '../domain/admin_user_details.dart';
import '../domain/coin_debit_idempotency.dart';
import '../domain/user_parse_helpers.dart';

String _localizedDisplayName(AppLocalizations l10n, String name) {
  return name == 'Anonim Kullanıcı' ? l10n.anonymousUser : name;
}

Future<String?> showAdminCoinDebitDialog({
  required BuildContext context,
  required AdminUserDetails user,
  AdminUserWalletRepository? repository,
  CoinDebitIdempotencyManager? idempotencyManager,
  UuidGenerator? generateUuid,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _AdminCoinDebitDialog(
        user: user,
        repository: repository ?? AdminUserWalletRepository(),
        idempotencyManager:
            idempotencyManager ??
            CoinDebitIdempotencyManager(
              generateUuid: generateUuid ?? const Uuid().v4,
            ),
      );
    },
  );
}

class _AdminCoinDebitDialog extends StatefulWidget {
  const _AdminCoinDebitDialog({
    required this.user,
    required this.repository,
    required this.idempotencyManager,
  });

  final AdminUserDetails user;
  final AdminUserWalletRepository repository;
  final CoinDebitIdempotencyManager idempotencyManager;

  @override
  State<_AdminCoinDebitDialog> createState() => _AdminCoinDebitDialogState();
}

enum _CoinDebitStep { form, confirm, submitting }

class _AdminCoinDebitDialogState extends State<_AdminCoinDebitDialog> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caseReferenceController = TextEditingController();

  _CoinDebitStep _step = _CoinDebitStep.form;
  AdminCoinDebitReason _selectedReason = AdminCoinDebitReason.customerSupport;
  String? _errorMessage;
  AdminCoinDebitInput? _pendingInput;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _caseReferenceController.dispose();
    super.dispose();
  }

  int? get _parsedAmount {
    final trimmed = _amountController.text.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return null;
    }

    return int.tryParse(trimmed);
  }

  bool get _isAmountExceedingBalance {
    final amount = _parsedAmount;
    if (amount == null) {
      return false;
    }

    return amount > widget.user.coinBalance;
  }

  int? get _projectedBalance {
    final amount = _parsedAmount;
    if (amount == null || _isAmountExceedingBalance) {
      return null;
    }

    try {
      return AdminCoinDebitInput(
        userId: widget.user.userId,
        amount: amount,
        reason: _selectedReason,
        description: _descriptionController.text,
        caseReference: _caseReferenceController.text,
      ).projectedBalance(widget.user.coinBalance);
    } on AdminCoinDebitValidationException {
      return null;
    }
  }

  AdminCoinDebitInput? _buildInput() {
    final amount = _parsedAmount;
    if (amount == null) {
      return null;
    }

    final caseReference = _caseReferenceController.text.trim();
    return AdminCoinDebitInput(
      userId: widget.user.userId,
      amount: amount,
      reason: _selectedReason,
      description: _descriptionController.text,
      caseReference: caseReference.isEmpty ? null : caseReference,
    );
  }

  void _goToConfirm() {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isAmountExceedingBalance) {
      setState(() => _errorMessage = context.l10n.insufficientBalance);
      return;
    }

    final input = _buildInput();
    if (input == null) {
      return;
    }

    try {
      input.validate();
    } on AdminCoinDebitValidationException catch (error) {
      setState(() => _errorMessage = error.message);
      return;
    }

    setState(() {
      _pendingInput = input;
      _step = _CoinDebitStep.confirm;
      _errorMessage = null;
    });
  }

  void _closeDialog() {
    if (_isSubmitting) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _goBackToForm() {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _step = _CoinDebitStep.form;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final input = _pendingInput;
    if (input == null || _isSubmitting) {
      return;
    }

    if (input.amount > widget.user.coinBalance) {
      setState(() => _errorMessage = context.l10n.insufficientBalance);
      return;
    }

    setState(() {
      _step = _CoinDebitStep.submitting;
      _isSubmitting = true;
      _errorMessage = null;
    });

    final idempotencyKey = widget.idempotencyManager.keyForPayload(
      input.payloadFingerprint,
    );

    try {
      final result = await widget.repository.debitUserCoins(
        input: input,
        idempotencyKey: idempotencyKey,
      );

      if (!mounted) {
        return;
      }

      widget.idempotencyManager.clear();

      final debitedAmount = input.amount;
      final message = result.wasReplayed
          ? context.l10n.idempotentDebit('${result.balanceAfter}')
          : context.l10n.coinsDebited(
              '$debitedAmount',
              '${result.balanceAfter}',
            );

      Navigator.of(context).pop(message);
    } on AdminUserWalletException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.kind == AdminUserWalletFailureKind.idempotencyConflict) {
        widget.idempotencyManager.clear();
      }

      setState(() {
        _step = _CoinDebitStep.confirm;
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _step = _CoinDebitStep.confirm;
        _isSubmitting = false;
        _errorMessage = context.l10n.unexpectedRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = widget.user;
    final input = _pendingInput;

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: Text(
          _step == _CoinDebitStep.confirm
              ? l10n.confirmTransaction
              : l10n.debitCoins,
        ),
        content: SizedBox(
          width: 480,
          child: switch (_step) {
            _CoinDebitStep.form => Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_localizedDisplayName(l10n, user.resolvedDisplayName)} (${adminResolvedEmailLabel(l10n, user.resolvedEmailLabel)})',
                      style: const TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${shortenUserId(user.userId)}',
                      style: const TextStyle(color: Color(0xFF808080)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.currentBalancePrefixed(
                        l10n.coinsAmount(user.coinBalance),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.coinAmount,
                        hintText: '1 – 1.000.000',
                      ),
                      validator: (value) => validateCoinAmountText(value),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_isAmountExceedingBalance) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.insufficientBalance,
                        style: const TextStyle(color: Color(0xFFFFB4B4)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AdminCoinDebitReason>(
                      initialValue: _selectedReason,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.reasonAlt),
                      items: [
                        for (final reason in AdminCoinDebitReason.values)
                          DropdownMenuItem(
                            value: reason,
                            child: Text(
                              adminCoinDebitReasonLabel(
                                l10n,
                                reason.storageValue,
                              ),
                            ),
                          ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _selectedReason = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        hintText: '5–500 karakter',
                      ),
                      validator: (value) => validateCoinDebitDescription(value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _caseReferenceController,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        labelText: l10n.caseReferenceOptional,
                      ),
                      validator: (value) => validateCaseReference(value),
                    ),
                    if (_projectedBalance != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.estimatedNewBalance(
                          l10n.coinsAmount(_projectedBalance!),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFFFB4B4)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _ => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConfirmRow(
                  label: l10n.user,
                  value: _localizedDisplayName(l10n, user.resolvedDisplayName),
                ),
                _ConfirmRow(
                  label: l10n.email,
                  value: adminResolvedEmailLabel(l10n, user.resolvedEmailLabel),
                ),
                _ConfirmRow(
                  label: l10n.userId,
                  value: shortenUserId(user.userId),
                ),
                _ConfirmRow(
                  label: l10n.currentBalance,
                  value: l10n.coinsAmount(user.coinBalance),
                ),
                _ConfirmRow(
                  label: l10n.toDebit,
                  value: l10n.coinsAmount(input?.amount ?? 0),
                ),
                _ConfirmRow(
                  label: l10n.newBalance,
                  value: l10n.coinsAmount(
                    input?.projectedBalance(user.coinBalance) ??
                        user.coinBalance,
                  ),
                ),
                _ConfirmRow(
                  label: l10n.reasonAlt,
                  value: input == null
                      ? '—'
                      : adminCoinDebitReasonLabel(
                          l10n,
                          input.reason.storageValue,
                        ),
                ),
                _ConfirmRow(
                  label: l10n.description,
                  value: input?.description.trim() ?? '—',
                ),
                if (input?.caseReference != null &&
                    input!.caseReference!.trim().isNotEmpty)
                  _ConfirmRow(
                    label: l10n.reference,
                    value: input.caseReference!.trim(),
                  ),
                const SizedBox(height: 12),
                Text(
                  l10n.debitDoesNotDeleteLedger,
                  style: const TextStyle(color: Color(0xFFB3B3B3)),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFFB4B4)),
                  ),
                ],
              ],
            ),
          },
        ),
        actions: [
          if (_step == _CoinDebitStep.confirm ||
              _step == _CoinDebitStep.submitting)
            TextButton(
              onPressed: _isSubmitting ? null : _goBackToForm,
              child: Text(l10n.back),
            ),
          TextButton(
            onPressed: _isSubmitting ? null : _closeDialog,
            child: Text(l10n.cancel),
          ),
          if (_step == _CoinDebitStep.form)
            FilledButton(
              onPressed: _isSubmitting || _isAmountExceedingBalance
                  ? null
                  : _goToConfirm,
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: Text(l10n.continueShort),
            )
          else
            FilledButton(
              onPressed:
                  _isSubmitting ||
                      (input != null && input.amount > user.coinBalance)
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.debitCoins),
            ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
