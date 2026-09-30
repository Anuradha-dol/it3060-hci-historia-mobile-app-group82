import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guide_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/guide_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../tourist/notifications_screen.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'approved_guides_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: RoleProfileContent(standalone: true)),
    );
  }
}

class RoleProfileContent extends StatefulWidget {
  final bool standalone;
  final VoidCallback? onTouristGuides;
  final VoidCallback? onNotifications;
  final VoidCallback? onGuideDashboard;
  final VoidCallback? onAdminApplications;

  const RoleProfileContent({
    super.key,
    this.standalone = false,
    this.onTouristGuides,
    this.onNotifications,
    this.onGuideDashboard,
    this.onAdminApplications,
  });

  @override
  State<RoleProfileContent> createState() => _RoleProfileContentState();
}

class _RoleProfileContentState extends State<RoleProfileContent> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _deletePassword = TextEditingController();

  UserModel? _profile;
  GuideModel? _guide;
  String? _guideError;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _deletePassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await UserService().getMyProfile();
      GuideModel? guide;
      String? guideError;

      if (profile.role == 'GUIDE') {
        try {
          guide = await GuideService().getMyGuideProfile();
        } catch (e) {
          guideError = ApiService.instance.getErrorMessage(e);
        }
      }

      if (!mounted) return;
      _profile = profile;
      _guide = guide;
      _guideError = guideError;
      _firstName.text = profile.firstName ?? '';
      _lastName.text = profile.lastName ?? '';
      _phone.text = profile.phone ?? '';
      _address.text = profile.address ?? '';
      await context.read<AuthProvider>().refreshProfile();
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

  Future<void> _updateProfile() async {
    setState(() => _saving = true);
    try {
      final updated = await UserService().updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      await context.read<AuthProvider>().refreshProfile();
      if (!mounted) return;
      showAppMessage(context, 'Profile updated.');
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

  Future<void> _changePassword() async {
    if (_currentPassword.text.isEmpty ||
        _newPassword.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      showAppMessage(context, 'Password fields are required.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await UserService().changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      showAppMessage(context, result.message);
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

  Future<void> _deleteAccount() async {
    _deletePassword.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: TextField(
            controller: _deletePassword,
            obscureText: true,
            decoration: fieldDecoration('Current password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _deletePassword.text.isEmpty) {
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await UserService().deleteAccount(
        currentPassword: _deletePassword.text,
      );
      if (!mounted) return;
      showAppMessage(context, result.message);
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      if (widget.standalone) {
        Navigator.maybePop(context);
      }
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
    bool obscure = false,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return HistoriaTextField(
      label: label,
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          HistoriaHeader(
            title: _profileTitle(profile),
            subtitle: _profileSubtitle(profile),
            eyebrow: _roleLabel(profile?.role),
            icon: Icons.person_outline,
            actions: [
              HistoriaIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: _load,
              ),
              if (widget.standalone)
                HistoriaIconButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  onPressed: () => Navigator.maybePop(context),
                ),
            ],
          ),
          HistoriaScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile != null) _identityCard(profile),
                const SizedBox(height: 14),
                if (profile?.role == 'GUIDE') ...[
                  _guideProfileBlock(),
                  const SizedBox(height: 14),
                ],
                _roleActions(profile),
                const SizedBox(height: 14),
                _personalInfoSection(),
                const SizedBox(height: 14),
                _passwordSection(),
                if (profile?.role != 'ADMIN') ...[
                  const SizedBox(height: 14),
                  _accountDangerSection(),
                ],
                const SizedBox(height: 14),
                HistoriaOutlineButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  onPressed: _saving
                      ? null
                      : () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityCard(UserModel profile) {
    return HistoriaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _initials(profile.fullName),
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text(profile.email, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
              HistoriaStatusChip(
                status: profile.emailVerified ? 'VERIFIED' : 'PENDING',
              ),
            ],
          ),
          const SizedBox(height: 14),
          HistoriaListTile(
            icon: Icons.alternate_email,
            title: 'Username',
            subtitle: profile.username,
          ),
          HistoriaListTile(
            icon: Icons.phone_outlined,
            title: 'Phone',
            subtitle: _emptyText(profile.phone),
          ),
          HistoriaListTile(
            icon: Icons.location_on_outlined,
            title: 'Address',
            subtitle: _emptyText(profile.address),
          ),
        ],
      ),
    );
  }

  Widget _guideProfileBlock() {
    final guide = _guide;
    final error = _guideError;

    if (guide == null) {
      return HistoriaInfoBox(
        title: 'Guide profile',
        message: error ?? 'Guide details are not available right now.',
        icon: Icons.badge_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistoriaStatusCard(
          status: guide.status,
          title: 'Guide application: ${guide.status.replaceAll('_', ' ')}',
          message: _guideStatusMessage(guide),
        ),
        const SizedBox(height: 14),
        HistoriaProfileSection(
          title: 'Guide details',
          children: [
            HistoriaListTile(
              icon: Icons.badge_outlined,
              title: 'Display name',
              subtitle: _emptyText(guide.displayName),
            ),
            HistoriaListTile(
              icon: Icons.map_outlined,
              title: 'Primary service area',
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
            HistoriaListTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Specialties',
              subtitle: _listText(guide.specialties),
            ),
            if (guide.headline != null && guide.headline!.isNotEmpty)
              HistoriaListTile(
                icon: Icons.short_text,
                title: 'Headline',
                subtitle: guide.headline,
              ),
            if (guide.bio != null && guide.bio!.isNotEmpty)
              HistoriaListTile(
                icon: Icons.notes_outlined,
                title: 'Bio',
                subtitle: guide.bio,
              ),
            if (guide.adminNote != null && guide.adminNote!.isNotEmpty)
              HistoriaListTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin note',
                subtitle: guide.adminNote,
              ),
          ],
        ),
      ],
    );
  }

  Widget _roleActions(UserModel? profile) {
    final role = profile?.role ?? 'TOURIST';
    final children = <Widget>[];

    if (role == 'TOURIST') {
      children.addAll([
        HistoriaListTile(
          icon: Icons.travel_explore,
          title: 'Find approved guides',
          subtitle: 'Search local guides by service area.',
          onTap:
              widget.onTouristGuides ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ApprovedGuidesScreen(),
                  ),
                );
              },
        ),
        HistoriaListTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'View trip and account updates.',
          onTap:
              widget.onNotifications ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
        ),
      ]);
    } else if (role == 'GUIDE') {
      children.add(
        HistoriaListTile(
          icon: Icons.dashboard_outlined,
          title: 'Guide dashboard',
          subtitle: 'Review your guide status and profile details.',
          onTap: widget.onGuideDashboard,
        ),
      );
    } else if (role == 'ADMIN') {
      children.add(
        HistoriaListTile(
          icon: Icons.fact_check_outlined,
          title: 'Guide applications',
          subtitle: 'Review pending, approved, and rejected guides.',
          onTap: widget.onAdminApplications,
        ),
      );
    }

    return HistoriaProfileSection(
      title: role == 'ADMIN' ? 'Admin navigation' : 'Account shortcuts',
      children: children,
    );
  }

  Widget _personalInfoSection() {
    return HistoriaProfileSection(
      title: 'Personal information',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 340) {
              return Column(
                children: [
                  _field('First name (optional)', _firstName),
                  _field('Last name (optional)', _lastName),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field('First name (optional)', _firstName)),
                const SizedBox(width: 12),
                Expanded(child: _field('Last name (optional)', _lastName)),
              ],
            );
          },
        ),
        _field(
          'Phone (optional)',
          _phone,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        _field(
          'Address (optional)',
          _address,
          icon: Icons.location_on_outlined,
        ),
        const HistoriaInfoBox(
          title: 'Email verification',
          message: 'Your email is changed through verification.',
        ),
        const SizedBox(height: 14),
        AsyncButton(
          loading: _saving,
          onPressed: _updateProfile,
          label: 'Save my changes',
          icon: Icons.save_outlined,
        ),
      ],
    );
  }

  Widget _passwordSection() {
    return HistoriaProfileSection(
      title: 'Change password',
      children: [
        _field('Current Password', _currentPassword, obscure: true),
        _field('New Password', _newPassword, obscure: true),
        _field('Confirm Password', _confirmPassword, obscure: true),
        AsyncButton(
          loading: _saving,
          onPressed: _changePassword,
          label: 'Change Password',
          icon: Icons.lock_outline,
        ),
      ],
    );
  }

  Widget _accountDangerSection() {
    return HistoriaProfileSection(
      title: 'Account',
      children: [
        HistoriaOutlineButton(
          label: 'Delete Account',
          icon: Icons.delete_outline,
          onPressed: _saving ? null : _deleteAccount,
          danger: true,
        ),
      ],
    );
  }

  String _profileTitle(UserModel? profile) {
    if (profile == null) return 'Profile';
    if (profile.role == 'ADMIN') return 'Admin profile';
    if (profile.role == 'GUIDE') return 'Guide profile.';
    return 'Update your details.';
  }

  String _profileSubtitle(UserModel? profile) {
    if (profile == null) return '';
    if (profile.role == 'ADMIN') {
      return 'Manage your account and guide review access.';
    }
    if (profile.role == 'GUIDE') {
      return 'Your account details and guide application information.';
    }
    return 'Your travel account, contact details, and settings.';
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'ADMIN ACCOUNT';
      case 'GUIDE':
        return 'GUIDE ACCOUNT';
      case 'TOURIST':
      default:
        return 'TOURIST ACCOUNT';
    }
  }

  String _guideStatusMessage(GuideModel guide) {
    switch (guide.status) {
      case 'APPROVED':
        return 'Your guide profile is visible to tourists searching approved guides.';
      case 'NEEDS_WORK':
        return guide.adminNote == null || guide.adminNote!.isEmpty
            ? 'Admin requested updates before approval.'
            : guide.adminNote!;
      case 'REJECTED':
        return guide.adminNote == null || guide.adminNote!.isEmpty
            ? 'This guide application was rejected.'
            : guide.adminNote!;
      case 'PENDING':
      default:
        return 'Your guide application is waiting for admin review.';
    }
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'H';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
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
