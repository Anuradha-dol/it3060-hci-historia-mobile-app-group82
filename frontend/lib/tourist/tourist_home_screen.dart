import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/approved_guides_screen.dart';
import '../profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../theme/app_text_styles.dart';
import '../widgets/historia_components.dart';
import 'notifications_screen.dart';

class TouristHomeScreen extends StatefulWidget {
  const TouristHomeScreen({super.key});

  @override
  State<TouristHomeScreen> createState() => _TouristHomeScreenState();
}

class _TouristHomeScreenState extends State<TouristHomeScreen> {
  int _index = 0;

  void _setIndex(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _TouristDashboard(
        onNavigate: _setIndex,
        onNotifications: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
      ),
      const ApprovedGuidesContent(),
      const _TouristCreateContent(),
      const _TouristExploreContent(),
      RoleProfileContent(
        onTouristGuides: () => _setIndex(1),
        onNotifications: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: HistoriaBottomNavigation(
        currentIndex: _index,
        onTap: _setIndex,
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
  final ValueChanged<int> onNavigate;
  final VoidCallback onNotifications;

  const _TouristDashboard({
    required this.onNavigate,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HistoriaHeader(
          title: 'Welcome ${user?.fullName ?? 'traveller'}',
          subtitle: 'Discover heritage places and connect with local guides.',
          eyebrow: 'TOURIST HOME',
          icon: Icons.account_balance,
          actions: [
            HistoriaIconButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onPressed: onNotifications,
            ),
            HistoriaIconButton(
              icon: Icons.logout,
              tooltip: 'Logout',
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
        HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null && !user.emailVerified) ...[
                const HistoriaStatusCard(
                  status: 'PENDING',
                  title: 'Email verification pending',
                  message:
                      'Some account features may require a verified email.',
                ),
                const SizedBox(height: 14),
              ],
              HistoriaSectionHeader(
                title: 'Plan your visit',
                subtitle: 'Tourist actions available in the current build.',
              ),
              HistoriaRoleCard(
                icon: Icons.travel_explore,
                title: 'Find local guides',
                subtitle:
                    'Search approved guides by service area using the backend guide API.',
                onTap: () => onNavigate(1),
              ),
              const SizedBox(height: 12),
              HistoriaRoleCard(
                icon: Icons.edit_outlined,
                title: 'Create a trip idea',
                subtitle:
                    'Prepare a future itinerary draft when tour APIs are available.',
                onTap: () => onNavigate(2),
              ),
              const SizedBox(height: 12),
              HistoriaRoleCard(
                icon: Icons.explore_outlined,
                title: 'Explore heritage',
                subtitle:
                    'Browse discovery placeholders in the HISTORIA style.',
                onTap: () => onNavigate(3),
              ),
              const SizedBox(height: 18),
              const HistoriaSectionHeader(
                title: 'Discover history',
                subtitle: 'Prepared for future place discovery data.',
              ),
              const HistoriaInfoBox(
                title: 'Historical places placeholder',
                message:
                    'No places endpoint is exposed yet. This section is a UI placeholder for future historical place discovery.',
                icon: Icons.account_balance_outlined,
                placeholder: true,
              ),
              const SizedBox(height: 12),
              const HistoriaInfoBox(
                title: 'Tours placeholder',
                message:
                    'Tour booking data is not available in the backend contract yet.',
                icon: Icons.route_outlined,
                placeholder: true,
              ),
              const SizedBox(height: 18),
              const HistoriaSectionHeader(
                title: 'Recent activity',
                subtitle: 'No activity endpoint is available yet.',
              ),
              const HistoriaEmptyState(
                icon: Icons.history,
                title: 'No recent tourist activity',
                message:
                    'Visited places, saved guides, or booked tours can appear here after those APIs exist.',
              ),
              const SizedBox(height: 18),
              Text(
                'HISTORIA keeps the tourist home focused on discovery without inventing unsupported booking logic.',
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TouristCreateContent extends StatelessWidget {
  const _TouristCreateContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        HistoriaHeader(
          title: 'Create your tour.',
          subtitle: 'Plan notes for future guided heritage trips.',
          eyebrow: 'TOURIST / CREATE',
          icon: Icons.edit_outlined,
        ),
        HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoriaInfoBox(
                title: 'Tour creation placeholder',
                message:
                    'The backend does not expose tourist tour creation yet. This keeps the Figma navigation ready without inventing API behavior.',
                placeholder: true,
              ),
              SizedBox(height: 14),
              HistoriaEmptyState(
                icon: Icons.route_outlined,
                title: 'No draft tours',
                message:
                    'Saved trip drafts can appear here after a tour planning endpoint exists.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TouristExploreContent extends StatelessWidget {
  const _TouristExploreContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        HistoriaHeader(
          title: 'Explore heritage.',
          subtitle: 'Discover historical places and local stories.',
          eyebrow: 'TOURIST / EXPLORE',
          icon: Icons.explore_outlined,
        ),
        HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoriaInfoBox(
                title: 'Historical places',
                message:
                    'Place discovery is a visual placeholder until a places endpoint is available.',
                placeholder: true,
              ),
              SizedBox(height: 14),
              HistoriaRoleCard(
                icon: Icons.account_balance_outlined,
                eyebrow: 'Ancient cities',
                title: 'Cultural landmarks',
                subtitle:
                    'Prepared for future content cards from the places API.',
                actionLabel: 'Coming soon',
              ),
              SizedBox(height: 12),
              HistoriaRoleCard(
                icon: Icons.forest_outlined,
                eyebrow: 'Nature and history',
                title: 'Scenic heritage routes',
                subtitle:
                    'Route discovery can connect here when tour data exists.',
                actionLabel: 'Coming soon',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
