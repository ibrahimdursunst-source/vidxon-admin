import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../series/presentation/series_create_page.dart';
import '../../series/presentation/series_list_page.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_counts.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({required this.email, super.key});

  final String email;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const _primaryColor = Color(0xFFE50914);
  static const _sidebarBreakpoint = 900.0;

  final DashboardRepository _repository = DashboardRepository();
  final GlobalKey<SeriesListPageState> _seriesListKey =
      GlobalKey<SeriesListPageState>();

  late Future<DashboardCounts> _countsFuture;

  int _selectedNavIndex = 0;
  bool _showSeriesCreate = false;

  @override
  void initState() {
    super.initState();
    _countsFuture = _repository.fetchCounts();
  }

  void _refreshActivePage() {
    switch (_selectedNavIndex) {
      case 0:
        _refreshCounts();
      case 1:
        _seriesListKey.currentState?.refresh();
      default:
        break;
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidebar = constraints.maxWidth >= _sidebarBreakpoint;

        return Scaffold(
          backgroundColor: const Color(0xFF090909),
          appBar: _buildAppBar(),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useSidebar) _buildSidebar(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!useSidebar) _buildCompactNav(),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      title: const Text(
        'VIDXON ADMIN',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
      actions: [
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

  Widget _buildSidebar() {
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
              for (var i = 0; i < _navItems.length; i++)
                _NavItemTile(
                  item: _navItems[i],
                  selected: _selectedNavIndex == i,
                  onTap: () => _onNavTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNav() {
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
            for (var i = 0; i < _navItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CompactNavChip(
                  item: _navItems[i],
                  selected: _selectedNavIndex == i,
                  onTap: () => _onNavTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (_navItems[index].enabled) {
      setState(() {
        _selectedNavIndex = index;
        if (index != 1) {
          _showSeriesCreate = false;
        }
      });
    }
  }

  Widget _buildContent() {
    return switch (_selectedNavIndex) {
      0 => _buildOverviewContent(),
      1 => _buildSeriesContent(),
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
        onSuccess: () {
          setState(() {
            _showSeriesCreate = false;
          });
          _seriesListKey.currentState?.refresh();
        },
      );
    }

    return SeriesListPage(
      key: _seriesListKey,
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

  static const _navItems = [
    _NavItem(
      label: 'Genel Bakış',
      icon: Icons.dashboard_outlined,
      enabled: true,
    ),
    _NavItem(label: 'Diziler', icon: Icons.movie_outlined, enabled: true),
    _NavItem(
      label: 'Bölümler',
      icon: Icons.playlist_play_outlined,
      enabled: false,
    ),
    _NavItem(
      label: 'Kategoriler',
      icon: Icons.category_outlined,
      enabled: false,
    ),
    _NavItem(label: 'Medya', icon: Icons.perm_media_outlined, enabled: false),
  ];
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
