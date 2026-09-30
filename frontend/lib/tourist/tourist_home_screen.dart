import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../widgets/historia_components.dart';
import 'notifications_screen.dart';

class TouristHomeScreen extends StatefulWidget {
  const TouristHomeScreen({super.key});

  @override
  State<TouristHomeScreen> createState() => _TouristHomeScreenState();
}

class _TouristHomeScreenState extends State<TouristHomeScreen> {
  int _index = 0;

  void _openHome() {
    if (_index == 0) return;

    setState(() {
      _index = 0;
    });
  }

  void _openProfile() {
    if (_index == 4) return;

    setState(() {
      _index = 4;
    });
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _openHome();
        break;

      case 1:
        break;

      case 2:
        break;

      case 3:
        break;

      case 4:
        _openProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),

      body: SafeArea(
        child: IndexedStack(
          index: _index == 4 ? 1 : 0,
          children: [
            _TouristDashboard(
              onNotifications: _openNotifications,
              onProfile: _openProfile,
            ),

            RoleProfileContent(
              onTouristGuides: () {},

              onNotifications: _openNotifications,
            ),
          ],
        ),
      ),

      bottomNavigationBar: HistoriaBottomNavigation(
        currentIndex: _index,
        onTap: _onBottomNavTap,
        items: const [
          HistoriaNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),

          HistoriaNavItem(icon: Icons.map_outlined, label: 'Tour'),

          HistoriaNavItem(icon: Icons.edit_outlined, label: 'Create'),

          HistoriaNavItem(icon: Icons.explore_outlined, label: 'Explore'),

          HistoriaNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TouristDashboard extends StatelessWidget {
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _TouristDashboard({
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HistoriaHeader(
          title: 'HISTORIA',
          subtitle: 'Explore history / Find your guide',
          eyebrow: 'TOURIST HOME',
          icon: Icons.account_balance_outlined,

          actions: [
            HistoriaIconButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onPressed: onNotifications,
            ),

            HistoriaIconButton(
              icon: Icons.person_outline,
              tooltip: 'Profile',
              onPressed: onProfile,
            ),
          ],
        ),

        const Expanded(child: SizedBox.expand()),
      ],
    );
  }
}
