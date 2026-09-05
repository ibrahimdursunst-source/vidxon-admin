import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
import '../data/partner_repository.dart';
import '../domain/admin_partner_summary.dart';

/// Dropdown for assigning an active Partner to a series.
/// [selectedPartnerId] null means unassigned.
class PartnerSelector extends StatefulWidget {
  const PartnerSelector({
    required this.selectedPartnerId,
    required this.onChanged,
    this.repository,
    this.enabled = true,
    this.label,
    this.initialOptions,
    super.key,
  });

  final String? selectedPartnerId;
  final ValueChanged<String?> onChanged;
  final PartnerRepository? repository;
  final bool enabled;
  final String? label;
  final List<AdminPartnerActiveOption>? initialOptions;

  @override
  State<PartnerSelector> createState() => _PartnerSelectorState();
}

class _PartnerSelectorState extends State<PartnerSelector> {
  late final PartnerRepository _repository =
      widget.repository ?? PartnerRepository();
  late Future<List<AdminPartnerActiveOption>> _optionsFuture;

  @override
  void initState() {
    super.initState();
    _optionsFuture = widget.initialOptions != null
        ? Future.value(widget.initialOptions)
        : _repository.listActivePartners();
  }

  void _reload() {
    setState(() {
      _optionsFuture = _repository.listActivePartners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? context.l10n.collaborationPartner;

    return FutureBuilder<List<AdminPartnerActiveOption>>(
      future: _optionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return InputDecorator(
            decoration: InputDecoration(labelText: label),
            child: const SizedBox(
              height: 24,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.partnerListLoadFailed,
                style: TextStyle(
                  color: const Color(0xFFFFB4B4).withValues(alpha: 1),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.enabled ? _reload : null,
                child: Text(context.l10n.retry),
              ),
            ],
          );
        }

        final options = snapshot.data ?? const <AdminPartnerActiveOption>[];
        final selected = widget.selectedPartnerId;
        final hasSelected =
            selected != null && options.any((o) => o.id == selected);

        return InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: hasSelected ? selected : null,
              isExpanded: true,
              hint: Text(context.l10n.unassigned),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(context.l10n.unassigned),
                ),
                for (final option in options)
                  DropdownMenuItem<String?>(
                    value: option.id,
                    child: Text(option.displayName),
                  ),
                if (selected != null && !hasSelected)
                  DropdownMenuItem<String?>(
                    value: selected,
                    child: Text(context.l10n.partnerNamed(selected)),
                  ),
              ],
              onChanged: widget.enabled
                  ? (value) => widget.onChanged(value)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
