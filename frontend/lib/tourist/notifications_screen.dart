import 'package:flutter/material.dart';

import '../widgets/historia_components.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: NotificationsContent(standalone: true)),
    );
  }
}

class NotificationsContent extends StatelessWidget {
  final bool standalone;
  final String roleLabel;

  const NotificationsContent({
    super.key,
    this.standalone = false,
    this.roleLabel = 'ACCOUNT',
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HistoriaHeader(
          title: 'Notifications',
          subtitle: 'Account updates will appear here when supported.',
          eyebrow: roleLabel,
          icon: Icons.notifications_outlined,
          actions: [
            if (standalone)
              HistoriaIconButton(
                icon: Icons.close,
                tooltip: 'Close',
                onPressed: () => Navigator.maybePop(context),
              ),
          ],
        ),
        const HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoriaInfoBox(
                title: 'Placeholder only',
                message:
                    'A notification endpoint is not exposed yet, so this screen intentionally shows an empty state.',
                icon: Icons.info_outline,
                placeholder: true,
              ),
              SizedBox(height: 14),
              HistoriaEmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                message:
                    'Guide reviews, trip updates, and account messages can be connected here when the backend supports them.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
