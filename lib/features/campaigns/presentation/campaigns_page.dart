import 'package:flutter/material.dart';

import 'popup_campaigns_tab.dart';
import 'push_campaigns_tab.dart';

/// Top-level campaigns page with Pop-up and Push tabs.
/// Access restricted to super-admins (hidden from nav for others).
class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => CampaignsPageState();
}

class CampaignsPageState extends State<CampaignsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _popupKey = GlobalKey<PopupCampaignsTabState>();
  final _pushKey = GlobalKey<PushCampaignsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void refresh() {
    _popupKey.currentState?.refresh();
    _pushKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            'Kampanyalar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pop-up'lar"),
            Tab(text: 'Push Bildirimleri'),
          ],
          labelColor: const Color(0xFFE50914),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE50914),
          isScrollable: false,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PopupCampaignsTab(key: _popupKey),
              PushCampaignsTab(key: _pushKey),
            ],
          ),
        ),
      ],
    );
  }
}
