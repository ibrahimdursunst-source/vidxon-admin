import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/admin_l10n.dart';
import '../../admin_context/presentation/admin_context_scope.dart';
import '../../admin_locale/presentation/admin_language_selector.dart';
import '../../admin_locale/presentation/admin_locale_scope.dart';
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
    final l10n = context.l10n;

    return [
      _NavItem(
        id: _NavId.overview,
        label: l10n.navOverview,
        icon: Icons.dashboard_outlined,
        enabled: true,
      ),
      _NavItem(
        id: _NavId.series,
        label: l10n.navSeries,
        icon: Icons.movie_outlined,
        enabled: true,
      ),
      _NavItem(
        id: _NavId.users,
        label: l10n.navUsers,
        icon: Icons.people_outlined,
        enabled: true,
      ),
      _NavItem(
        id: _NavId.audit,
        label: l10n.navAudit,
        icon: Icons.receipt_long_outlined,
        enabled: true,
      ),
      _NavItem(
        id: _NavId.partners,
        label: l10n.navPartners,
        icon: Icons.handshake_outlined,
        enabled: true,
      ),
      if (showSuperAdminNav) ...[
        _NavItem(
          id: _NavId.campaigns,
          label: l10n.navCampaigns,
          icon: Icons.campaign_outlined,
          enabled: true,
        ),
        _NavItem(
          id: _NavId.admins,
          label: l10n.navAdmins,
          icon: Icons.admin_panel_settings_outlined,
          enabled: true,
        ),
      ],
      _NavItem(
        id: _NavId.episodes,
        label: l10n.navEpisodes,
        icon: Icons.playlist_play_outlined,
        enabled: false,
      ),
      _NavItem(
        id: _NavId.categories,
        label: l10n.navCategories,
        icon: Icons.category_outlined,
        enabled: false,
      ),
      _NavItem(
        id: _NavId.media,
        label: l10n.navMedia,
        icon: Icons.perm_media_outlined,
        enabled: false,
      ),
    ];
  }

  void _refreshActivePage() {
    final items = _navItems(context);
    if (_selectedNavIndex < 0 || _selectedNavIndex >= items.length) {
      return;
    }
    switch (items[_selectedNavIndex].id) {
      case _NavId.overview:
        _refreshCounts();
      case _NavId.series:
        _seriesListKey.currentState?.refresh();
      case _NavId.users:
        _usersPageKey.currentState?.refresh();
      case _NavId.audit:
        _auditPageKey.currentState?.refresh();
      case _NavId.partners:
        _partnersPageKey.currentState?.refresh();
      case _NavId.campaigns:
        _campaignsPageKey.currentState?.refresh();
      case _NavId.admins:
        _managementPageKey.currentState?.refresh();
      default:
        break;
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
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
      title: Text(
        context.l10n.appBrandAdmin,
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
        if (AdminLocaleScope.maybeOf(context) != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AdminLanguageSelector(
              controller: AdminLocaleScope.of(context),
            ),
          ),
        IconButton(
          tooltip: context.l10n.refresh,
          onPressed: _refreshActivePage,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: context.l10n.signOut,
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
        if (navItems[index].id != _NavId.series) {
          _showSeriesCreate = false;
        }
      });
    }
  }

  Widget _buildContent(BuildContext context, List<_NavItem> navItems) {
    if (_selectedNavIndex >= navItems.length) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (navItems[_selectedNavIndex].id) {
      _NavId.overview => _buildOverviewContent(),
      _NavId.series => _buildSeriesContent(),
      _NavId.users => AdminUsersPage(key: _usersPageKey),
      _NavId.audit => AdminAuditPage(key: _auditPageKey),
      _NavId.partners => PartnersPage(key: _partnersPageKey),
      _NavId.campaigns => CampaignsPage(key: _campaignsPageKey),
      _NavId.admins => AdminManagementPage(key: _managementPageKey),
      _ => Center(
        child: Text(
          context.l10n.comingSoonSection,
          style: const TextStyle(color: Color(0xFFB3B3B3)),
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
                      context.l10n.dataLoadFailed,
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
                      child: Text(context.l10n.retry),
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
                context.l10n.navOverview,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.overviewSubtitle,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
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
                          label: context.l10n.navSeries,
                          count: counts.seriesCount,
                          icon: Icons.movie_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 720 ? cardWidth : null,
                        child: _StatCard(
                          label: context.l10n.navEpisodes,
                          count: counts.episodeCount,
                          icon: Icons.playlist_play_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 720 ? cardWidth : null,
                        child: _StatCard(
                          label: context.l10n.navCategories,
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

enum _NavId {
  overview,
  series,
  users,
  audit,
  partners,
  campaigns,
  admins,
  episodes,
  categories,
  media,
}

class _NavItem {
  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  final _NavId id;
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
