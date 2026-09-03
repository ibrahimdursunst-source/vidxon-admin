import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../admin_context/presentation/admin_context_scope.dart';
import '../../admins/presentation/admin_management_page.dart';
import '../../audit/presentation/admin_audit_page.dart';
import '../../categories/data/category_repository.dart';
import '../../media/data/image_upload_repository.dart';
import '../../media/domain/poster_file.dart';
import '../../campaigns/presentation/campaigns_page.dart';
import '../../partners/presentation/partners_page.dart';
import '../../series/data/series_mutation_repository.dart';
import '../../series/data/series_repository.dart';
import '../../series/presentation/series_create_page.dart';
import '../../series/presentation/series_detail_page.dart';
import '../../series/presentation/series_list_page.dart';
import '../../users/presentation/admin_role_badge.dart';
import '../../users/presentation/admin_users_page.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_counts.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    required this.email,
    this.initialSelectedNavIndex = 0,
    this.seriesListRepository,
    this.seriesCreateMutationRepository,
    this.seriesDetailRepository,
    this.imageUploadRepository,
    this.categoryRepository,
    this.dashboardRepository,
    this.initialPosterForTesting,
    super.key,
  });

  final String email;
  final int initialSelectedNavIndex;
  final SeriesRepository? seriesListRepository;
  final SeriesMutationRepository? seriesCreateMutationRepository;
  final SeriesRepository? seriesDetailRepository;
  final ImageUploadRepository? imageUploadRepository;
  final CategoryRepository? categoryRepository;
  final DashboardRepository? dashboardRepository;
  final PosterFile? initialPosterForTesting;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const _primaryColor = Color(0xFFE50914);
  static const _sidebarBreakpoint = 900.0;

  late final DashboardRepository _repository =
      widget.dashboardRepository ?? DashboardRepository();
  final GlobalKey<SeriesListPageState> _seriesListKey =
      GlobalKey<SeriesListPageState>();
  final GlobalKey<AdminUsersPageState> _usersPageKey =
      GlobalKey<AdminUsersPageState>();
  final GlobalKey<AdminAuditPageState> _auditPageKey =
      GlobalKey<AdminAuditPageState>();
  final GlobalKey<AdminManagementPageState> _managementPageKey =
      GlobalKey<AdminManagementPageState>();
  final GlobalKey<PartnersPageState> _partnersPageKey =
      GlobalKey<PartnersPageState>();
  final GlobalKey<CampaignsPageState> _campaignsPageKey =
      GlobalKey<CampaignsPageState>();

  late Future<DashboardCounts> _countsFuture;

  int _selectedNavIndex = 0;
  bool _showSeriesCreate = false;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialSelectedNavIndex;
    _countsFuture = _repository.fetchCounts();
  }

  List<_NavItem> _navItems(BuildContext context) {
    final contextResult = AdminContextScope.maybeOf(context);
    final showSuperAdminNav =
        contextResult != null &&
        !contextResult.isLoading &&
        contextResult.isSuperAdmin;

    return [
      const _NavItem(
        label: 'Genel Bakış',
        icon: Icons.dashboard_outlined,
        enabled: true,
      ),
      const _NavItem(
        label: 'Diziler',
        icon: Icons.movie_outlined,
        enabled: true,
      ),
      const _NavItem(
        label: 'Kullanıcılar',
        icon: Icons.people_outlined,
        enabled: true,
      ),
      const _NavItem(
        label: 'İşlem Kayıtları',
        icon: Icons.receipt_long_outlined,
        enabled: true,
      ),
      const _NavItem(
        label: 'Partnerler',
        icon: Icons.handshake_outlined,
        enabled: true,
      ),
      if (showSuperAdminNav) ...[
        const _NavItem(
          label: 'Kampanyalar',
          icon: Icons.campaign_outlined,
          enabled: true,
        ),
        const _NavItem(
          label: 'Yöneticiler',
          icon: Icons.admin_panel_settings_outlined,
          enabled: true,
        ),
      ],
      const _NavItem(
        label: 'Bölümler',
        icon: Icons.playlist_play_outlined,
        enabled: false,
      ),
      const _NavItem(
        label: 'Kategoriler',
        icon: Icons.category_outlined,
        enabled: false,
      ),
      const _NavItem(
        label: 'Medya',
        icon: Icons.perm_media_outlined,
        enabled: false,
      ),
    ];
  }

  String _navLabel(BuildContext context, int index) {
    final items = _navItems(context);
    if (index < 0 || index >= items.length) {
      return '';
    }

    return items[index].label;
  }

  void _refreshActivePage() {
    final label = _navLabel(context, _selectedNavIndex);
    switch (label) {
      case 'Genel Bakış':
        _refreshCounts();
      case 'Diziler':
        _seriesListKey.currentState?.refresh();
      case 'Kullanıcılar':
        _usersPageKey.currentState?.refresh();
      case 'İşlem Kayıtları':
        _auditPageKey.currentState?.refresh();
      case 'Partnerler':
        _partnersPageKey.currentState?.refresh();
      case 'Kampanyalar':
        _campaignsPageKey.currentState?.refresh();
      case 'Yöneticiler':
        _managementPageKey.currentState?.refresh();
      default:
        break;
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut(
      scope: SignOutScope.global,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems(context);

    if (_selectedNavIndex >= navItems.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedNavIndex = 0);
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidebar = constraints.maxWidth >= _sidebarBreakpoint;

        return Scaffold(
          backgroundColor: const Color(0xFF090909),
          appBar: _buildAppBar(context),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useSidebar) _buildSidebar(navItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!useSidebar) _buildCompactNav(navItems),
                    Expanded(child: _buildContent(context, navItems)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final contextResult = AdminContextScope.maybeOf(context);
    final roleLabel = contextResult?.context?.role.labelTurkish;

    return AppBar(
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      title: const Text(
        'VIDXON ADMIN',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
      actions: [
        if (roleLabel != null) ...[
          AdminRoleBadge(label: roleLabel),
          const SizedBox(width: 8),
        ] else if (contextResult?.isLoading == true)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              widget.email,
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Yenile',
          onPressed: _refreshActivePage,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Çıkış Yap',
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidebar(List<_NavItem> navItems) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(right: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < navItems.length; i++)
                _NavItemTile(
                  item: navItems[i],
                  selected: _selectedNavIndex == i,
                  onTap: () => _onNavTap(i, navItems),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNav(List<_NavItem> navItems) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < navItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CompactNavChip(
                  item: navItems[i],
                  selected: _selectedNavIndex == i,
                  onTap: () => _onNavTap(i, navItems),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index, List<_NavItem> navItems) {
    if (index < navItems.length && navItems[index].enabled) {
      setState(() {
        _selectedNavIndex = index;
        if (navItems[index].label != 'Diziler') {
          _showSeriesCreate = false;
        }
      });
    }
  }

  Widget _buildContent(BuildContext context, List<_NavItem> navItems) {
    if (_selectedNavIndex >= navItems.length) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (navItems[_selectedNavIndex].label) {
      'Genel Bakış' => _buildOverviewContent(),
      'Diziler' => _buildSeriesContent(),
      'Kullanıcılar' => AdminUsersPage(key: _usersPageKey),
      'İşlem Kayıtları' => AdminAuditPage(key: _auditPageKey),
      'Partnerler' => PartnersPage(key: _partnersPageKey),
      'Kampanyalar' => CampaignsPage(key: _campaignsPageKey),
      'Yöneticiler' => AdminManagementPage(key: _managementPageKey),
      _ => const Center(
        child: Text(
          'Bu bölüm yakında eklenecek.',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
      ),
    };
  }

  Widget _buildSeriesContent() {
    if (_showSeriesCreate) {
      return SeriesCreatePage(
        onCancel: () {
          setState(() {
            _showSeriesCreate = false;
          });
        },
        onSuccess: (created) {
          setState(() {
            _showSeriesCreate = false;
          });
          _seriesListKey.currentState?.refresh();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => SeriesDetailPage(
                seriesId: created.id,
                initialSeries: created,
                seriesRepository:
                    widget.seriesDetailRepository ??
                    widget.seriesListRepository,
                mutationRepository: widget.seriesCreateMutationRepository,
                categoryRepository: widget.categoryRepository,
                imageUploadRepository: widget.imageUploadRepository,
              ),
            ),
          );
        },
        seriesMutationRepository: widget.seriesCreateMutationRepository,
        imageUploadRepository: widget.imageUploadRepository,
        categoryRepository: widget.categoryRepository,
        initialPosterForTesting: widget.initialPosterForTesting,
      );
    }

    return SeriesListPage(
      key: _seriesListKey,
      repository: widget.seriesListRepository,
      onCreateTap: () {
        setState(() {
          _showSeriesCreate = true;
        });
      },
    );
  }

  void _refreshCounts() {
    setState(() {
      _countsFuture = _repository.fetchCounts();
    });
  }

  Widget _buildOverviewContent() {
    return FutureBuilder<DashboardCounts>(
      future: _countsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Veriler yüklenemedi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _refreshCounts,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final counts = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Genel Bakış',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'İçerik istatistiklerinin özeti',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 720
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth >= 720 ? cardWidth : null,
                        child: _StatCard(
                          label: 'Diziler',
                          count: counts.seriesCount,
                          icon: Icons.movie_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 720 ? cardWidth : null,
                        child: _StatCard(
                          label: 'Bölümler',
                          count: counts.episodeCount,
                          icon: Icons.playlist_play_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 720 ? cardWidth : null,
                        child: _StatCard(
                          label: 'Kategoriler',
                          count: counts.categoryCount,
                          icon: Icons.category_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.enabled,
  });

  final String label;
  final IconData icon;
  final bool enabled;
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE50914);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? primaryColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: item.enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: item.enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: selected ? primaryColor : const Color(0xFFB3B3B3),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: selected
                            ? Colors.white
                            : const Color(0xFFB3B3B3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavChip extends StatelessWidget {
  const _CompactNavChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE50914);

    return Material(
      color: selected
          ? primaryColor.withValues(alpha: 0.15)
          : const Color(0xFF181818),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: item.enabled ? 1 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: selected ? primaryColor : const Color(0xFFB3B3B3),
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : const Color(0xFFB3B3B3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFE50914)),
            const SizedBox(height: 16),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
