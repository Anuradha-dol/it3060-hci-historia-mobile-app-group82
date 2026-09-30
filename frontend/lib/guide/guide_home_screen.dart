import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guide_model.dart';
import '../profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/guide_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../tourist/notifications_screen.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

class GuideHomeScreen extends StatefulWidget {
  const GuideHomeScreen({super.key});

  @override
  State<GuideHomeScreen> createState() => _GuideHomeScreenState();
}

class _GuideHomeScreenState extends State<GuideHomeScreen> {
  final _displayName = TextEditingController();
  final _primaryArea = TextEditingController();
  final _serviceAreas = TextEditingController();
  final _languages = TextEditingController();
  final _experience = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _specialties = TextEditingController();

  GuideModel? _guide;
  int _index = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _displayName,
      _primaryArea,
      _serviceAreas,
      _languages,
      _experience,
      _headline,
      _bio,
      _specialties,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final guide = await GuideService().getMyGuideProfile();
      if (!mounted) return;
      _setGuide(guide);
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setGuide(GuideModel guide) {
    setState(() {
      _guide = guide;
      _displayName.text = guide.displayName;
      _primaryArea.text = guide.primaryServiceArea;
      _serviceAreas.text = guide.serviceAreas.join(', ');
      _languages.text = guide.languages.join(', ');
      _experience.text = guide.yearsExperience.toString();
      _headline.text = guide.headline ?? '';
      _bio.text = guide.bio ?? '';
      _specialties.text = guide.specialties.join(', ');
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final guide = await GuideService().updateMyGuideProfile(
        displayName: _displayName.text.trim(),
        primaryServiceArea: _primaryArea.text.trim(),
        serviceAreas: splitCsv(_serviceAreas.text),
        languages: splitCsv(_languages.text),
        yearsExperience: int.tryParse(_experience.text.trim()) ?? 0,
        headline: _headline.text.trim(),
        bio: _bio.text.trim(),
        specialties: splitCsv(_specialties.text),
      );
      if (!mounted) return;
      _setGuide(guide);
      final message = guide.status == 'PENDING'
          ? 'Guide application submitted for admin review.'
          : 'Guide profile updated.';
      showAppMessage(context, message);
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return HistoriaTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  void _setIndex(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _guideDashboard(),
      const _GuideRequestsContent(),
      const _GuideScheduleContent(),
      const NotificationsContent(roleLabel: 'GUIDE ACCOUNT'),
      RoleProfileContent(onGuideDashboard: () => _setIndex(0)),
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
          HistoriaNavItem(icon: Icons.assignment_outlined, label: 'Requests'),
          HistoriaNavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Schedule',
          ),
          HistoriaNavItem(icon: Icons.notifications_outlined, label: 'Alerts'),
          HistoriaNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _guideDashboard() {
    final user = context.watch<AuthProvider>().user;
    final guide = _guide;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          HistoriaHeader(
            title: 'Welcome ${user?.fullName ?? 'guide'}',
            subtitle: 'Manage your guide application and public profile.',
            eyebrow: 'GUIDE HOME',
            icon: Icons.badge_outlined,
            actions: [
              HistoriaIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: _load,
              ),
              HistoriaIconButton(
                icon: Icons.logout,
                tooltip: 'Logout',
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
          HistoriaScreenPadding(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (guide == null)
                        const HistoriaInfoBox(
                          title: 'Guide profile unavailable',
                          message:
                              'The current account is a guide, but no guide profile was returned.',
                          icon: Icons.error_outline,
                        )
                      else ...[
                        _statusCard(guide),
                        const SizedBox(height: 14),
                        if (guide.status == 'APPROVED')
                          _approvedWorkspace(guide)
                        else
                          _applicationStateWorkspace(guide),
                        if (guide.status != 'REJECTED') ...[
                          const SizedBox(height: 14),
                          _guideEditSection(guide),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(GuideModel guide) {
    return HistoriaStatusCard(
      status: guide.status,
      title: _statusTitle(guide.status),
      message: _statusMessage(guide),
    );
  }

  Widget _approvedWorkspace(GuideModel guide) {
    final completion = _completionScore(guide);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth > 360;
            final cards = [
              HistoriaStatCard(
                label: 'Service areas',
                value: guide.serviceAreas.length.toString(),
                icon: Icons.route_outlined,
              ),
              HistoriaStatCard(
                label: 'Languages',
                value: guide.languages.length.toString(),
                icon: Icons.translate_outlined,
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [cards.first, const SizedBox(height: 12), cards.last],
              );
            }

            return Row(
              children: [
                Expanded(child: cards.first),
                const SizedBox(width: 12),
                Expanded(child: cards.last),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        HistoriaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile completion', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completion,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: AppColors.primarySoft,
              ),
              const SizedBox(height: 8),
              Text(
                '${(completion * 100).round()}% of guide profile fields are completed.',
                style: AppTextStyles.bodyMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const HistoriaSectionHeader(
          title: 'Guide workspace',
          subtitle: 'Available responsibilities for approved guides.',
        ),
        HistoriaRoleCard(
          icon: Icons.person_outline,
          title: 'Guide profile',
          subtitle: 'Review account and public guide details.',
          onTap: () => _setIndex(4),
        ),
        const SizedBox(height: 12),
        HistoriaRoleCard(
          icon: Icons.assignment_outlined,
          title: 'Tour requests',
          subtitle: 'Prepared for future traveller requests.',
          onTap: () => _setIndex(1),
        ),
        const SizedBox(height: 12),
        HistoriaRoleCard(
          icon: Icons.calendar_month_outlined,
          title: 'Schedule',
          subtitle: 'Prepared for future guide availability tools.',
          onTap: () => _setIndex(2),
        ),
        const SizedBox(height: 12),
        HistoriaRoleCard(
          icon: Icons.notifications_outlined,
          title: 'Guide notifications',
          subtitle: 'Placeholder until notification support is added.',
          onTap: () => _setIndex(3),
        ),
        const SizedBox(height: 12),
        const HistoriaInfoBox(
          title: 'Booking requests placeholder',
          message:
              'The backend does not expose booking or tour request endpoints yet.',
          icon: Icons.event_available_outlined,
          placeholder: true,
        ),
      ],
    );
  }

  Widget _applicationStateWorkspace(GuideModel guide) {
    final canEdit = guide.status == 'PENDING' || guide.status == 'NEEDS_WORK';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistoriaSectionHeader(
          title: guide.status == 'REJECTED'
              ? 'Application closed'
              : 'Application details',
          subtitle: canEdit
              ? 'These details are visible to admins during review.'
              : 'This application cannot be updated from the app.',
        ),
        HistoriaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HistoriaListTile(
                icon: Icons.badge_outlined,
                title: 'Display name',
                subtitle: _emptyText(guide.displayName),
              ),
              HistoriaListTile(
                icon: Icons.map_outlined,
                title: 'Primary area',
                subtitle: _emptyText(guide.primaryServiceArea),
              ),
              HistoriaListTile(
                icon: Icons.translate_outlined,
                title: 'Languages',
                subtitle: _listText(guide.languages),
              ),
              HistoriaListTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Specialties',
                subtitle: _listText(guide.specialties),
              ),
              if (guide.adminNote != null && guide.adminNote!.isNotEmpty)
                HistoriaListTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin note',
                  subtitle: guide.adminNote,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guideEditSection(GuideModel guide) {
    final title = guide.status == 'NEEDS_WORK'
        ? 'Update and resubmit'
        : guide.status == 'APPROVED'
        ? 'Edit guide profile'
        : 'Edit application';
    final button = guide.status == 'NEEDS_WORK'
        ? 'Resubmit Application'
        : 'Save Guide Profile';

    return HistoriaProfileSection(
      title: title,
      children: [
        if (guide.status == 'NEEDS_WORK') ...[
          const HistoriaInfoBox(
            title: 'Needs work',
            message:
                'Saving these changes sends the application back to PENDING for admin review.',
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 12),
        ],
        _field('Display Name', _displayName),
        _field('Primary Service Area', _primaryArea),
        _field('Service Areas (comma separated)', _serviceAreas),
        _field('Languages (comma separated)', _languages),
        _field(
          'Years of Experience',
          _experience,
          keyboardType: TextInputType.number,
        ),
        _field('Headline', _headline),
        _field('Bio', _bio, maxLines: 4),
        _field('Specialties (comma separated)', _specialties),
        AsyncButton(
          loading: _saving,
          onPressed: _save,
          label: button,
          icon: Icons.save_outlined,
        ),
      ],
    );
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Approved guide dashboard';
      case 'NEEDS_WORK':
        return 'Application needs updates';
      case 'REJECTED':
        return 'Application rejected';
      case 'PENDING':
      default:
        return 'Application pending review';
    }
  }

  String _statusMessage(GuideModel guide) {
    switch (guide.status) {
      case 'APPROVED':
        return 'Tourists can find your guide profile through approved guide search.';
      case 'NEEDS_WORK':
        return guide.adminNote == null || guide.adminNote!.isEmpty
            ? 'Admin requested updates before approval.'
            : guide.adminNote!;
      case 'REJECTED':
        return guide.adminNote == null || guide.adminNote!.isEmpty
            ? 'This guide application was rejected by admin review.'
            : guide.adminNote!;
      case 'PENDING':
      default:
        return 'Your guide application is waiting for an admin decision.';
    }
  }

  double _completionScore(GuideModel guide) {
    final fields = <String>[
      guide.displayName,
      guide.primaryServiceArea,
      guide.headline ?? '',
      guide.bio ?? '',
      guide.serviceAreas.isNotEmpty ? 'serviceAreas' : '',
      guide.languages.isNotEmpty ? 'languages' : '',
      guide.specialties.isNotEmpty ? 'specialties' : '',
      guide.yearsExperience > 0 ? 'experience' : '',
    ];
    final completed = fields.where((value) => value.trim().isNotEmpty).length;
    return completed / fields.length;
  }

  String _emptyText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not provided';
    }
    return value.trim();
  }

  String _listText(List<String> values) {
    if (values.isEmpty) {
      return 'Not provided';
    }
    return values.join(', ');
  }
}

class _GuideRequestsContent extends StatelessWidget {
  const _GuideRequestsContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        HistoriaHeader(
          title: 'Tour requests.',
          subtitle: 'Manage traveller requests when booking support is added.',
          eyebrow: 'GUIDE / REQUESTS',
          icon: Icons.assignment_outlined,
        ),
        HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoriaInfoBox(
                title: 'Booking requests placeholder',
                message:
                    'The backend does not expose booking request endpoints yet.',
                placeholder: true,
              ),
              SizedBox(height: 14),
              HistoriaEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No requests yet',
                message:
                    'Traveller requests can appear here after the booking API exists.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideScheduleContent extends StatelessWidget {
  const _GuideScheduleContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        HistoriaHeader(
          title: 'Your schedule.',
          subtitle: 'Availability and confirmed tours will live here.',
          eyebrow: 'GUIDE / SCHEDULE',
          icon: Icons.calendar_month_outlined,
        ),
        HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoriaInfoBox(
                title: 'Schedule placeholder',
                message:
                    'Calendar data is not available in the current backend contract.',
                placeholder: true,
              ),
              SizedBox(height: 14),
              HistoriaEmptyState(
                icon: Icons.event_available_outlined,
                title: 'No scheduled tours',
                message:
                    'Confirmed tours and availability controls can be connected here later.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
