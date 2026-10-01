import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../admin/admin_home_screen.dart';
import '../auth/launch_screen.dart';
import '../guide/guide_home_screen.dart';
import '../tourist/tourist_home_screen.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LaunchScreen();
    }

    switch (auth.role) {
      case 'ADMIN':
        return const AdminHomeScreen();

      case 'GUIDE':
        return const GuideHomeScreen();

      case 'TOURIST':
      default:
        return const TouristHomeScreen();
    }
  }
}
