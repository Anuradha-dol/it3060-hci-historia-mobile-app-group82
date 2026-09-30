import 'package:flutter/material.dart';

import '../auth/guide_resubmit_screen.dart';
import '../auth/login_screen.dart';
import '../widgets/historia_components.dart';

class GuidePendingScreen extends StatelessWidget {
  const GuidePendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HistoriaHeader(
              title: 'Application submitted',
              subtitle: 'Your guide account is waiting for admin approval.',
              eyebrow: 'GUIDE APPLICATION',
              icon: Icons.hourglass_top_outlined,
            ),
            HistoriaScreenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HistoriaStatusCard(
                    status: 'PENDING',
                    title: 'Pending admin review',
                    message:
                        'You can sign in after an admin approves your guide application.',
                  ),
                  const SizedBox(height: 14),
                  const HistoriaInfoBox(
                    title: 'Need changes?',
                    message:
                        'If an admin marks your application as needs work, use resubmit to send updated guide details.',
                    icon: Icons.edit_note_outlined,
                  ),
                  const SizedBox(height: 18),
                  HistoriaButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: Icons.login,
                    label: 'Back to Login',
                  ),
                  const SizedBox(height: 10),
                  HistoriaOutlineButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuideResubmitScreen(),
                        ),
                      );
                    },
                    icon: Icons.refresh,
                    label: 'Resubmit Application',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
