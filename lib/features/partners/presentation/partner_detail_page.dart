import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/presentation/content_conflict_helper.dart';
import '../../users/domain/user_parse_helpers.dart';
import '../data/partner_errors.dart';
import '../data/partner_repository.dart';
import '../domain/admin_partner_detail.dart';
import '../domain/admin_partner_member.dart';
import '../domain/admin_partner_summary.dart';
import '../domain/partner_status.dart';
import 'partner_analytics_panel.dart';
import 'partner_assignment_history_panel.dart';
import 'partner_form_dialog.dart';
import '../domain/partner_series_assignment.dart';

class PartnerDetailPage extends StatefulWidget {
  const PartnerDetailPage({
    required this.partnerId,
    this.initialSummary,
    this.repository,
    super.key,
  });

  final String partnerId;
  final AdminPartnerSummary? initialSummary;
  final PartnerRepository? repository;

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  static const _primaryColor = Color(0xFFE50914);

  late final PartnerRepository _repository =
      widget.repository ?? PartnerRepository();

  AdminPartnerDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedSeriesIdForAnalytics;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _repository.fetchPartnerDetail(widget.partnerId);
      if (!mounted) {
        return;
      }

      final activeSeries = detail.assignments
          .where((a) => a.isActive)
          .map((a) => a.seriesId)
          .toList(growable: false);

      setState(() {
        _detail = detail;
        _isLoading = false;
        if (_selectedSeriesIdForAnalytics == null ||
            !detail.assignments.any(
              (a) => a.seriesId == _selectedSeriesIdForAnalytics,
            )) {
          _selectedSeriesIdForAnalytics = activeSeries.isNotEmpty
              ? activeSeries.first
              : (detail.assignments.isNotEmpty
                    ? detail.assignments.first.seriesId
                    : null);
        }
      });
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Partner detayı yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _editPartner() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final updated = await showPartnerFormDialog(
      context: context,
      repository: _repository,
      initial: detail.toSummary(),
    );

    if (updated == null || !mounted) {
      return;
    }

    showContentSuccessSnackBar(context, 'Partner güncellendi.');
    await _load();
  }

  Future<void> _addMember() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final added = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _AddMemberDialog(repository: _repository, partnerId: detail.id),
    );

    if (added == true && mounted) {
      showContentSuccessSnackBar(context, 'Üye eklendi.');
      await _load();
    }
  }

  Future<void> _setMemberStatus(
    AdminPartnerMember member,
    PartnerMemberStatus status,
  ) async {
    final confirmed = await confirmContentAction(
      context,
      title: 'Üye durumunu değiştir',
      message:
          '${formatUserDisplayName(displayName: member.displayName, email: member.email)} '
          'durumu “${status.label}” olarak ayarlansın mı?',
      confirmLabel: 'Onayla',
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _repository.setMemberStatus(
        partnerId: widget.partnerId,
        userId: member.userId,
        status: status,
      );
      if (!mounted) {
        return;
      }
      showContentSuccessSnackBar(context, 'Üye durumu güncellendi.');
      await _load();
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      showContentErrorSnackBar(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final title =
        detail?.displayName ?? widget.initialSummary?.displayName ?? 'Partner';

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          if (detail != null)
            IconButton(
              tooltip: 'Düzenle',
              onPressed: _editPartner,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFFB4B4)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                    ),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : detail == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(detail: detail),
                      const SizedBox(height: 24),
                      _MembersSection(
                        members: detail.members,
                        onAdd: _addMember,
                        onSetStatus: _setMemberStatus,
                      ),
                      const SizedBox(height: 24),
                      PartnerAssignmentHistoryPanel(
                        assignments: detail.assignments,
                        showSeriesTitle: true,
                      ),
                      const SizedBox(height: 24),
                      if (detail.assignments.isNotEmpty) ...[
                        _AnalyticsSeriesPicker(
                          assignments: detail.assignments,
                          selectedSeriesId: _selectedSeriesIdForAnalytics,
                          onChanged: (id) {
                            setState(() => _selectedSeriesIdForAnalytics = id);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_selectedSeriesIdForAnalytics != null)
                          PartnerAnalyticsPanel(
                            partnerId: detail.id,
                            seriesId: _selectedSeriesIdForAnalytics!,
                            repository: _repository,
                          ),
                      ] else
                        const Text(
                          'Analitik için önce bir dizi ataması gerekir.',
                          style: TextStyle(color: Color(0xFFB3B3B3)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.detail});

  final AdminPartnerDetail detail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (detail.legalName != null) ...[
              const SizedBox(height: 4),
              Text(
                detail.legalName!,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: detail.status.label),
                _Badge(
                  label: 'Oluşturulma ${formatUserDateTime(detail.createdAt)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.members,
    required this.onAdd,
    required this.onSetStatus,
  });

  final List<AdminPartnerMember> members;
  final VoidCallback onAdd;
  final void Function(AdminPartnerMember, PartnerMemberStatus) onSetStatus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Üyeler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Üye Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Text(
                'Henüz üye yok.',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              )
            else
              for (final member in members) ...[
                _MemberRow(member: member, onSetStatus: onSetStatus),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onSetStatus});

  final AdminPartnerMember member;
  final void Function(AdminPartnerMember, PartnerMemberStatus) onSetStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatUserDisplayName(
                    displayName: member.displayName,
                    email: member.email,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatUserEmailLabel(member.email),
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            member.status.label,
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<PartnerMemberStatus>(
            tooltip: 'Durum',
            onSelected: (status) => onSetStatus(member, status),
            itemBuilder: (context) => [
              for (final status in PartnerMemberStatus.values)
                if (status != member.status)
                  PopupMenuItem(value: status, child: Text(status.label)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSeriesPicker extends StatelessWidget {
  const _AnalyticsSeriesPicker({
    required this.assignments,
    required this.selectedSeriesId,
    required this.onChanged,
  });

  final List<PartnerSeriesAssignment> assignments;
  final String? selectedSeriesId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final uniqueSeries = <String, String>{};
    for (final assignment in assignments) {
      uniqueSeries[assignment.seriesId] =
          assignment.seriesTitle ?? assignment.seriesId;
    }

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Analitik Dizisi'),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSeriesId,
          isExpanded: true,
          items: [
            for (final entry in uniqueSeries.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.repository, required this.partnerId});

  final PartnerRepository repository;
  final String partnerId;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _emailController = TextEditingController();
  PartnerLookupUser? _lookup;
  bool _isLookingUp = false;
  bool _isAdding = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _lookupUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'E-posta zorunludur.');
      return;
    }

    setState(() {
      _isLookingUp = true;
      _errorMessage = null;
      _lookup = null;
    });

    try {
      final user = await widget.repository.lookupUserByEmail(email);
      if (!mounted) {
        return;
      }
      setState(() {
        _lookup = user;
        _isLookingUp = false;
      });
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLookingUp = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Kullanıcı aranamadı.';
        _isLookingUp = false;
      });
    }
  }

  Future<void> _add() async {
    final user = _lookup;
    if (user == null || _isAdding) {
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.addMember(
        partnerId: widget.partnerId,
        userId: user.userId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isAdding = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Üye eklenemedi.';
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF181818),
      title: const Text('Üye Ekle'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mevcut bir Vidxon hesabını tam e-posta ile bulun.',
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFFFB4B4)),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _emailController,
              enabled: !_isLookingUp && !_isAdding,
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _lookupUser(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLookingUp || _isAdding ? null : _lookupUser,
              child: _isLookingUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kullanıcıyı Bul'),
            ),
            if (_lookup != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatUserDisplayName(
                        displayName: _lookup!.displayName,
                        email: _lookup!.email,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _lookup!.email,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _lookup == null || _isAdding ? null : _add,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
          ),
          child: _isAdding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Üye Olarak Ekle'),
        ),
      ],
    );
  }
}
