import 'dart:async';

import 'package:flutter/material.dart';

import '../../users/domain/user_parse_helpers.dart';
import '../data/partner_errors.dart';
import '../data/partner_repository.dart';
import '../domain/admin_partner_summary.dart';
import '../domain/partner_analytics_health.dart';
import '../domain/partner_status.dart';
import 'partner_detail_page.dart';
import 'partner_form_dialog.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({this.repository, super.key});

  final PartnerRepository? repository;

  @override
  PartnersPageState createState() => PartnersPageState();
}

class PartnersPageState extends State<PartnersPage> {
  static const _primaryColor = Color(0xFFE50914);
  static const _desktopBreakpoint = 900.0;

  late final PartnerRepository _repository =
      widget.repository ?? PartnerRepository();

  List<AdminPartnerSummary> _partners = const [];
  PartnerAnalyticsHealth? _health;
  bool _isLoading = true;
  String? _errorMessage;
  String? _healthError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  void refresh() {
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final partners = await _repository.listPartners();
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _partners = partners;
        _isLoading = false;
      });
    } on PartnerException catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _errorMessage = 'Partner listesi yüklenemedi.';
        _isLoading = false;
      });
    }

    unawaited(_loadHealth());
  }

  Future<void> _loadHealth() async {
    try {
      final health = await _repository.fetchAnalyticsHealth();
      if (!mounted) {
        return;
      }
      setState(() {
        _health = health;
        _healthError = null;
      });
    } on PartnerException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _health = null;
        _healthError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _health = null;
        _healthError = 'Analitik sağlık durumu yüklenemedi.';
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showPartnerFormDialog(
      context: context,
      repository: _repository,
    );

    if (created == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partner oluşturuldu.'),
        backgroundColor: Color(0xFF35C46A),
      ),
    );
    await _load();
  }

  Future<void> _openDetail(AdminPartnerSummary partner) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PartnerDetailPage(
          partnerId: partner.id,
          initialSummary: partner,
          repository: _repository,
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _desktopBreakpoint;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partnerler',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'İş birliği ortakları, üyeler ve analitikleri yönetin',
                          style: TextStyle(color: Color(0xFFB3B3B3)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Partner Oluştur'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HealthBanner(health: _health, errorMessage: _healthError),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(wide: wide)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody({required bool wide}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _primaryColor),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFB4B4)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: _primaryColor),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_partners.isEmpty) {
      return const Center(
        child: Text(
          'Henüz Partner yok.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
      );
    }

    if (wide) {
      return SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF181818)),
          columns: const [
            DataColumn(label: Text('Partner')),
            DataColumn(label: Text('Durum')),
            DataColumn(label: Text('Üyeler')),
            DataColumn(label: Text('Aktif Atama')),
            DataColumn(label: Text('Oluşturulma')),
          ],
          rows: [
            for (final partner in _partners)
              DataRow(
                onSelectChanged: (_) => _openDetail(partner),
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          partner.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (partner.legalName != null)
                          Text(
                            partner.legalName!,
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(_StatusChip(status: partner.status)),
                  DataCell(Text('${partner.activeMemberCount}')),
                  DataCell(Text('${partner.activeAssignmentCount}')),
                  DataCell(Text(formatUserDateTime(partner.createdAt))),
                ],
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _partners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final partner = _partners[index];
        return Material(
          color: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          child: InkWell(
            onTap: () => _openDetail(partner),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          partner.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _StatusChip(status: partner.status),
                    ],
                  ),
                  if (partner.legalName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      partner.legalName!,
                      style: const TextStyle(color: Color(0xFF777777)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Üye ${partner.activeMemberCount} · Atama '
                    '${partner.activeAssignmentCount} · '
                    '${formatUserDateTime(partner.createdAt)}',
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PartnerStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PartnerStatus.active => const Color(0xFF35C46A),
      PartnerStatus.suspended => const Color(0xFFFFA000),
      PartnerStatus.ended => const Color(0xFF777777),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HealthBanner extends StatelessWidget {
  const _HealthBanner({this.health, this.errorMessage});

  final PartnerAnalyticsHealth? health;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE50914).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE50914).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          'Analitik sağlık durumu alınamadı: $errorMessage',
          style: const TextStyle(color: Color(0xFFFFB4B4)),
        ),
      );
    }

    if (health == null) {
      return const SizedBox.shrink();
    }

    final color = switch (health!.status) {
      PartnerDataIntegrityStatus.healthy => const Color(0xFF35C46A),
      PartnerDataIntegrityStatus.warning => const Color(0xFFFFA000),
      PartnerDataIntegrityStatus.unavailable => const Color(0xFFE50914),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analitik Sağlık: ${health!.status.label}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          if (health!.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final warning in health!.warnings.take(4))
              Text(
                '• ${warning.displayMessage()}',
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
              ),
          ],
          if (health!.status == PartnerDataIntegrityStatus.unavailable) ...[
            const SizedBox(height: 6),
            const Text(
              'Analitik bütünlük doğrulaması şu anda kullanılamıyor.',
              style: TextStyle(color: Color(0xFFFFB4B4), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
