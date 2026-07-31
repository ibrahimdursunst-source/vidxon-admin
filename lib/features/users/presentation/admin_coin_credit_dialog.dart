import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../data/admin_user_wallet_errors.dart';
import '../data/admin_user_wallet_repository.dart';
import '../domain/admin_coin_credit_input.dart';
import '../domain/admin_coin_credit_reason.dart';
import '../domain/admin_user_details.dart';
import '../domain/coin_credit_idempotency.dart';

Future<String?> showAdminCoinCreditDialog({
  required BuildContext context,
  required AdminUserDetails user,
  AdminUserWalletRepository? repository,
  CoinCreditIdempotencyManager? idempotencyManager,
  UuidGenerator? generateUuid,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _AdminCoinCreditDialog(
        user: user,
        repository: repository ?? AdminUserWalletRepository(),
        idempotencyManager:
            idempotencyManager ??
            CoinCreditIdempotencyManager(
              generateUuid: generateUuid ?? const Uuid().v4,
            ),
      );
    },
  );
}

class _AdminCoinCreditDialog extends StatefulWidget {
  const _AdminCoinCreditDialog({
    required this.user,
    required this.repository,
    required this.idempotencyManager,
  });

  final AdminUserDetails user;
  final AdminUserWalletRepository repository;
  final CoinCreditIdempotencyManager idempotencyManager;

  @override
  State<_AdminCoinCreditDialog> createState() => _AdminCoinCreditDialogState();
}

enum _CoinCreditStep { form, confirm, submitting }

class _AdminCoinCreditDialogState extends State<_AdminCoinCreditDialog> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caseReferenceController = TextEditingController();

  _CoinCreditStep _step = _CoinCreditStep.form;
  AdminCoinCreditReason _selectedReason = AdminCoinCreditReason.customerSupport;
  String? _errorMessage;
  AdminCoinCreditInput? _pendingInput;

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

  int? get _projectedBalance {
    final amount = _parsedAmount;
    if (amount == null) {
      return null;
    }

    try {
      return AdminCoinCreditInput(
        userId: widget.user.userId,
        amount: amount,
        reason: _selectedReason,
        description: _descriptionController.text,
        caseReference: _caseReferenceController.text,
      ).projectedBalance(widget.user.coinBalance);
    } on AdminCoinCreditValidationException {
      return null;
    }
  }

  AdminCoinCreditInput? _buildInput() {
    final amount = _parsedAmount;
    if (amount == null) {
      return null;
    }

    final caseReference = _caseReferenceController.text.trim();
    return AdminCoinCreditInput(
      userId: widget.user.userId,
      amount: amount,
      reason: _selectedReason,
      description: _descriptionController.text,
      caseReference: caseReference.isEmpty ? null : caseReference,
    );
  }

  void _goToConfirm() {
    if (_step == _CoinCreditStep.submitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final input = _buildInput();
    if (input == null) {
      return;
    }

    try {
      input.validate();
    } on AdminCoinCreditValidationException catch (error) {
      setState(() => _errorMessage = error.message);
      return;
    }

    setState(() {
      _pendingInput = input;
      _step = _CoinCreditStep.confirm;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final input = _pendingInput;
    if (input == null || _step == _CoinCreditStep.submitting) {
      return;
    }

    setState(() {
      _step = _CoinCreditStep.submitting;
      _errorMessage = null;
    });

    final idempotencyKey = widget.idempotencyManager.keyForPayload(
      input.payloadFingerprint,
    );

    try {
      final result = await widget.repository.creditUserCoins(
        input: input,
        idempotencyKey: idempotencyKey,
      );

      if (!mounted) {
        return;
      }

      widget.idempotencyManager.clear();

      final message = result.wasReplayed
          ? 'Bu işlem daha önce tamamlanmıştı. Güncel bakiye yenilendi.'
          : 'Jetonlar başarıyla yüklendi.';

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(message);
    } on AdminUserWalletException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.kind == AdminUserWalletFailureKind.idempotencyConflict) {
        widget.idempotencyManager.clear();
      }

      setState(() {
        _step = _CoinCreditStep.confirm;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _step = _CoinCreditStep.confirm;
        _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final input = _pendingInput;
    final isSubmitting = _step == _CoinCreditStep.submitting;

    return PopScope(
      canPop: !isSubmitting,
      child: AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: Text(
          _step == _CoinCreditStep.confirm ? 'İşlemi Onayla' : 'Jeton Yükle',
        ),
        content: SizedBox(
          width: 480,
          child: switch (_step) {
            _CoinCreditStep.form => Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${user.resolvedDisplayName} (${user.resolvedEmailLabel})',
                      style: const TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                    const SizedBox(height: 8),
                    Text('Mevcut bakiye: ${user.coinBalance} jeton'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Jeton miktarı',
                        hintText: '1 – 1.000.000',
                      ),
                      validator: (value) => validateCoinAmountText(value),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AdminCoinCreditReason>(
                      initialValue: _selectedReason,
                      decoration: const InputDecoration(labelText: 'Neden'),
                      items: [
                        for (final reason in AdminCoinCreditReason.values)
                          DropdownMenuItem(
                            value: reason,
                            child: Text(reason.labelTurkish),
                          ),
                      ],
                      onChanged: isSubmitting
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
                      enabled: !isSubmitting,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        hintText: '5–500 karakter',
                      ),
                      validator: (value) =>
                          validateCoinCreditDescription(value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _caseReferenceController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Destek / işlem referansı (opsiyonel)',
                      ),
                      validator: (value) => validateCaseReference(value),
                    ),
                    if (_projectedBalance != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tahmini yeni bakiye: $_projectedBalance jeton',
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
                  label: 'Kullanıcı',
                  value: user.resolvedDisplayName,
                ),
                _ConfirmRow(
                  label: 'Mevcut bakiye',
                  value: '${user.coinBalance} jeton',
                ),
                _ConfirmRow(
                  label: 'Yüklenecek',
                  value: '${input?.amount ?? 0} jeton',
                ),
                _ConfirmRow(
                  label: 'Yeni bakiye',
                  value:
                      '${input?.projectedBalance(user.coinBalance) ?? user.coinBalance} jeton',
                ),
                _ConfirmRow(
                  label: 'Neden',
                  value: input?.reason.labelTurkish ?? '—',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu işlem kullanıcı bakiyesini değiştirecek.',
                  style: TextStyle(color: Color(0xFFB3B3B3)),
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
          TextButton(
            onPressed: isSubmitting
                ? null
                : () {
                    if (_step == _CoinCreditStep.confirm) {
                      setState(() => _step = _CoinCreditStep.form);
                      return;
                    }

                    Navigator.of(context).pop(false);
                  },
            child: const Text('İptal'),
          ),
          if (_step == _CoinCreditStep.form)
            FilledButton(
              onPressed: isSubmitting ? null : _goToConfirm,
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text('Devam'),
            )
          else
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('${input?.amount ?? 0} Jeton Yükle'),
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
