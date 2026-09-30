import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guide_model.dart';
import '../profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/admin_guide_service.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../tourist/notifications_screen.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const _statuses = ['PENDING', 'NEEDS_WORK', 'APPROVED', 'REJECTED'];

  final _service = AdminGuideService();
  final Map<String, List<GuideModel>> _guidesByStatus = {
    for (final status in _statuses) status: <GuideModel>[],
  };

  String _selectedStatus = 'PENDING';
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait(
        _statuses.map(
          (status) async =>
              MapEntry(status, await _service.getGuidesByStatus(status)),
        ),
      );
      if (!mounted) return;
      setState(() {
        _guidesByStatus
          ..clear()
          ..addEntries(results);
      });
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

  Future<void> _review(GuideModel guide, String status) async {
    final noteController = TextEditingController(text: guide.adminNote ?? '');
    final requiresNote = status == 'NEEDS_WORK' || status == 'REJECTED';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${status.replaceAll('_', ' ')} guide'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requiresNote
                    ? 'Admin note is required for this decision.'
                    : 'Optional admin note for this decision.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: fieldDecoration('Admin note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || guide.id == null) {
      noteController.dispose();
      return;
    }

    if (requiresNote && noteController.text.trim().isEmpty) {
      noteController.dispose();
      if (!mounted) return;
      showAppMessage(context, 'Admin note is required.', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.reviewGuide(
        guideProfileId: guide.id!,
        status: status,
        adminNote: noteController.text.trim(),
      );
      noteController.dispose();
      await _loadAll();
      if (!mounted) return;
      showAppMessage(context, 'Guide marked as $status.');
    } catch (e) {
      noteController.dispose();
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

  void _setIndex(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _applications(),
      _guidesDirectory(),
      const NotificationsContent(roleLabel: 'ADMIN ACCOUNT'),
      RoleProfileContent(onAdminApplications: () => _setIndex(1)),
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
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          HistoriaNavItem(icon: Icons.fact_check_outlined, label: 'Apps'),
          HistoriaNavItem(icon: Icons.badge_outlined, label: 'Guides'),
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

  Widget _dashboard() {
    final user = context.watch<AuthProvider>().user;
    final pending = _guidesByStatus['PENDING'] ?? [];
    final total = _statuses.fold<int>(
      0,
      (sum, status) => sum + (_guidesByStatus[status]?.length ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          HistoriaHeader(
            title: 'Admin dashboard',
            subtitle: 'Review guide applications and account status.',
            eyebrow: user?.fullName ?? 'ADMIN HOME',
            icon: Icons.admin_panel_settings_outlined,
            actions: [
              HistoriaIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: _loadAll,
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
                if (_loading) const LinearProgressIndicator(minHeight: 3),
                if (_loading) const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 380
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    final cards = [
                      HistoriaStatCard(
                        label: 'Pending',
                        value: '${pending.length}',
                        icon: Icons.hourglass_top_outlined,
                        color: AppColors.info,
                      ),
                      HistoriaStatCard(
                        label: 'Approved',
                        value: '${_guidesByStatus['APPROVED']?.length ?? 0}',
                        icon: Icons.verified_outlined,
                        color: AppColors.success,
                      ),
                      HistoriaStatCard(
                        label: 'Needs work',
                        value: '${_guidesByStatus['NEEDS_WORK']?.length ?? 0}',
                        icon: Icons.edit_note_outlined,
                        color: AppColors.warning,
                      ),
                      HistoriaStatCard(
                        label: 'Total reviewed',
                        value: '$total',
                        icon: Icons.fact_check_outlined,
                        color: AppColors.primary,
                      ),
                    ];

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final card in cards)
                          SizedBox(width: cardWidth, child: card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                HistoriaSectionHeader(
                  title: 'Pending review',
                  subtitle: pending.isEmpty
                      ? 'No pending guide applications.'
                      : '${pending.length} application(s) need admin review.',
                  actionLabel: 'Open',
                  onAction: () {
                    setState(() {
                      _selectedStatus = 'PENDING';
                      _index = 1;
                    });
                  },
                ),
                if (pending.isEmpty)
                  const HistoriaEmptyState(
                    icon: Icons.task_alt,
                    title: 'Review queue is clear',
                    message:
                        'New guide applications will appear here after submission.',
                  )
                else
                  ...pending.take(3).map(_compactGuideCard),
                const SizedBox(height: 18),
                const HistoriaInfoBox(
                  title: 'Admin scope',
                  message:
                      'This dashboard only uses the existing guide review APIs. User, booking, and place management are not present in the backend contract.',
                  icon: Icons.admin_panel_settings_outlined,
                  placeholder: true,
                ),
                const SizedBox(height: 12),
                HistoriaRoleCard(
                  icon: Icons.badge_outlined,
                  title: 'Guide directory',
                  subtitle:
                      'Scan applications grouped by current review state.',
                  onTap: () => _setIndex(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guidesDirectory() {
    final approved = _guidesByStatus['APPROVED'] ?? [];
    final needsWork = _guidesByStatus['NEEDS_WORK'] ?? [];
    final rejected = _guidesByStatus['REJECTED'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          HistoriaHeader(
            title: 'Guide directory.',
            subtitle: 'Approved and reviewed guide applications.',
            eyebrow: 'ADMIN / GUIDES',
            icon: Icons.badge_outlined,
            actions: [
              HistoriaIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: _loadAll,
              ),
            ],
          ),
          HistoriaScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) const LinearProgressIndicator(minHeight: 3),
                if (_loading) const SizedBox(height: 14),
                HistoriaSectionHeader(
                  title: 'Approved guides',
                  subtitle:
                      '${approved.length} guide(s) live for tourist search.',
                ),
                if (approved.isEmpty)
                  const HistoriaEmptyState(
                    icon: Icons.verified_outlined,
                    title: 'No approved guides',
                    message: 'Approved guide profiles will appear here.',
                  )
                else
                  ...approved.map(_compactGuideCard),
                const SizedBox(height: 18),
                HistoriaSectionHeader(
                  title: 'Needs work',
                  subtitle: '${needsWork.length} application(s) need updates.',
                ),
                if (needsWork.isEmpty)
                  const HistoriaInfoBox(
                    title: 'No needs work items',
                    message:
                        'Applications needing changes will appear in this section.',
                    placeholder: true,
                  )
                else
                  ...needsWork.map(_compactGuideCard),
                const SizedBox(height: 18),
                HistoriaSectionHeader(
                  title: 'Rejected',
                  subtitle: '${rejected.length} closed application(s).',
                ),
                if (rejected.isEmpty)
                  const HistoriaInfoBox(
                    title: 'No rejected applications',
                    message: 'Rejected guide records will appear here.',
                    placeholder: true,
                  )
                else
                  ...rejected.map(_compactGuideCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _applications() {
    final guides = _guidesByStatus[_selectedStatus] ?? [];

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          HistoriaHeader(
            title: 'Guide applications',
            subtitle: 'Review applications by approval status.',
            eyebrow: 'ADMIN REVIEWS',
            icon: Icons.fact_check_outlined,
            actions: [
              HistoriaIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: _loadAll,
              ),
            ],
          ),
          HistoriaScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in _statuses)
                      _StatusFilterButton(
                        status: status,
                        count: _guidesByStatus[status]?.length ?? 0,
                        selected: status == _selectedStatus,
                        onTap: () => setState(() => _selectedStatus = status),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_loading) const LinearProgressIndicator(minHeight: 3),
                if (_loading) const SizedBox(height: 14),
                HistoriaSectionHeader(
                  title: _selectedStatus.replaceAll('_', ' '),
                  subtitle: '${guides.length} guide application(s)',
                ),
                if (guides.isEmpty)
                  const HistoriaEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No guide applications found',
                    message: 'Switch status filters or refresh the list.',
                  )
                else
                  ...guides.map(_reviewGuideCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactGuideCard(GuideModel guide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HistoriaRoleCard(
        icon: Icons.badge_outlined,
        title: guide.title,
        subtitle: '${guide.primaryServiceArea} | ${guide.email}',
        onTap: () {
          setState(() {
            _selectedStatus = guide.status;
            _index = 1;
          });
        },
        trailing: HistoriaStatusChip(status: guide.status),
      ),
    );
  }

  Widget _reviewGuideCard(GuideModel guide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HistoriaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guide.title, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 4),
                      Text(
                        '${guide.email} | ${guide.phone ?? 'No phone'}',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                HistoriaStatusChip(status: guide.status),
              ],
            ),
            const SizedBox(height: 12),
            HistoriaListTile(
              icon: Icons.map_outlined,
              title: 'Primary area',
              subtitle: _emptyText(guide.primaryServiceArea),
            ),
            HistoriaListTile(
              icon: Icons.route_outlined,
              title: 'Service areas',
              subtitle: _listText(guide.serviceAreas),
            ),
            HistoriaListTile(
              icon: Icons.translate_outlined,
              title: 'Languages',
              subtitle: _listText(guide.languages),
            ),
            HistoriaListTile(
              icon: Icons.history_edu_outlined,
              title: 'Experience',
              subtitle: '${guide.yearsExperience} years',
            ),
            if (guide.bio != null && guide.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(guide.bio!, style: AppTextStyles.bodyMuted),
              ),
            if (guide.adminNote != null && guide.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              HistoriaInfoBox(
                title: 'Admin note',
                message: guide.adminNote!,
                icon: Icons.admin_panel_settings_outlined,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (guide.status != 'APPROVED')
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _review(guide, 'APPROVED'),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Approve'),
                  ),
                if (guide.status != 'NEEDS_WORK')
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _review(guide, 'NEEDS_WORK'),
                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                    label: const Text('Needs Work'),
                  ),
                if (guide.status != 'REJECTED')
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _review(guide, 'REJECTED'),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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

class _StatusFilterButton extends StatelessWidget {
  final String status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterButton({
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = historiaStatusPalette(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.background : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? palette.border : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              palette.icon,
              size: 16,
              color: selected ? palette.foreground : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${status.replaceAll('_', ' ')} ($count)',
              style: TextStyle(
                color: selected ? palette.foreground : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
