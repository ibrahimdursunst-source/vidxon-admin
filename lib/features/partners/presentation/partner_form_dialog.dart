import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/partner_errors.dart';
import '../data/partner_repository.dart';
import '../domain/admin_partner_summary.dart';
import '../domain/partner_status.dart';

Future<AdminPartnerSummary?> showPartnerFormDialog({
  required BuildContext context,
  required PartnerRepository repository,
  AdminPartnerSummary? initial,
}) {
  return showDialog<AdminPartnerSummary>(
    context: context,
    builder: (context) =>
        PartnerFormDialog(repository: repository, initial: initial),
  );
}

class PartnerFormDialog extends StatefulWidget {
  const PartnerFormDialog({required this.repository, this.initial, super.key});

  final PartnerRepository repository;
  final AdminPartnerSummary? initial;

  @override
  State<PartnerFormDialog> createState() => _PartnerFormDialogState();
}

class _PartnerFormDialogState extends State<PartnerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _legalNameController;
  late PartnerStatus _status;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _displayNameController = TextEditingController(
      text: initial?.displayName ?? '',
    );
    _legalNameController = TextEditingController(
      text: initial?.legalName ?? '',
    );
    _status = initial?.status ?? PartnerStatus.active;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _legalNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final AdminPartnerSummary result;
      if (widget.initial == null) {
        result = await widget.repository.createPartner(
          displayName: _displayNameController.text.trim(),
          legalName: _legalNameController.text.trim(),
        );
      } else {
        result = await widget.repository.updatePartner(
          partnerId: widget.initial!.id,
          displayName: _displayNameController.text.trim(),
          legalName: _legalNameController.text.trim(),
          status: _status,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = context.l10n.actionFailed;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: Text(
        isEdit ? context.l10n.editPartner : context.l10n.createPartner,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFFFB4B4)),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _displayNameController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: context.l10n.displayNameStar,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.displayNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _legalNameController,
                enabled: !_isSaving,
                decoration: InputDecoration(labelText: context.l10n.legalName),
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(labelText: context.l10n.status),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PartnerStatus>(
                      value: _status,
                      isExpanded: true,
                      items: [
                        for (final status in PartnerStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(
                              adminPartnerStatusLabel(
                                context.l10n,
                                status.value,
                              ),
                            ),
                          ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.dismiss),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? context.l10n.save : context.l10n.create),
        ),
      ],
    );
  }
}
