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

  // ================================================================
  // HOME
  // ================================================================

  void _openHome() {
    if (_index == 0) return;

    setState(() {
      _index = 0;
    });
  }

  // ================================================================
  // PROFILE
  // ================================================================

  void _openProfile() {
    if (_index == 4) return;

    setState(() {
      _index = 4;
    });
  }

  // ================================================================
  // NOTIFICATIONS
  // ================================================================

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  //
  // Home + Profile only work here.
  // Tour / Create / Explore belong to other members.
  // ================================================================

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
      // HOME
        _openHome();
        break;

      case 1:
      // TOUR
      // Other member's part - do nothing.
        break;

      case 2:
      // CREATE
      // Other member's part - do nothing.
        break;

      case 3:
      // EXPLORE
      // Other member's part - do nothing.
        break;

      case 4:
      // PROFILE
        _openProfile();
        break;
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),

      // ==============================================================
      // PAGE BODY
      // ==============================================================
      body: SafeArea(
        child: IndexedStack(
          index: _index == 4 ? 1 : 0,
          children: [
            // =========================================================
            // HOME
            // =========================================================
            _TouristDashboard(
              onNotifications: _openNotifications,
              onProfile: _openProfile,
            ),

            // =========================================================
            // PROFILE
            // =========================================================
            RoleProfileContent(
              // Find guides belongs to another member.
              onTouristGuides: () {},

              // Notification is your part.
              onNotifications: _openNotifications,
            ),
          ],
        ),
      ),

      // ==============================================================
      // BOTTOM NAVIGATION
      // ==============================================================
      bottomNavigationBar: HistoriaBottomNavigation(
        currentIndex: _index,
        onTap: _onBottomNavTap,
        items: const [
          // HOME
          HistoriaNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),

          // TOUR
          HistoriaNavItem(
            icon: Icons.map_outlined,
            label: 'Tour',
          ),

          // CREATE
          HistoriaNavItem(
            icon: Icons.edit_outlined,
            label: 'Create',
          ),

          // EXPLORE
          HistoriaNavItem(
            icon: Icons.explore_outlined,
            label: 'Explore',
          ),

          // PROFILE
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

// =====================================================================
// TOURIST HOME
//
// Actual Home feature belongs to another member.
// Only Notification + Profile access is added here.
// =====================================================================

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
        // =============================================================
        // HEADER
        // =============================================================
        HistoriaHeader(
          title: 'HISTORIA',
          subtitle: 'Explore history · Find your guide',
          eyebrow: 'TOURIST HOME',
          icon: Icons.account_balance_outlined,

          actions: [
            // =========================================================
            // NOTIFICATION BUTTON
            // =========================================================
            HistoriaIconButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onPressed: onNotifications,
            ),

            // =========================================================
            // PROFILE BUTTON
            // =========================================================
            HistoriaIconButton(
              icon: Icons.person_outline,
              tooltip: 'Profile',
              onPressed: onProfile,
            ),
          ],
        ),

        // =============================================================
        // HOME CONTENT
        //
        // Empty because actual Home UI belongs to another member.
        // =============================================================
        const Expanded(
          child: SizedBox.expand(),
        ),
      ],
    );
  }
}