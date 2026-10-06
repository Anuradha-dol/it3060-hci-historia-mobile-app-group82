import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guide_model.dart';
import '../profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/guide_service.dart';
import '../tourist/create_post_screen.dart';
import '../tourist/notifications_screen.dart';
import '../widgets/community_feed.dart';
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
  int _feedKey = 0;

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

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
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

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
        setState(() {
          _loading = false;
        });
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
    if (_displayName.text.trim().isEmpty ||
        _primaryArea.text.trim().isEmpty ||
        _languages.text.trim().isEmpty ||
        _experience.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Complete the required guide details.',
        error: true,
      );
      return;
    }

    final years = int.tryParse(_experience.text.trim());

    if (years == null || years < 0) {
      showAppMessage(
        context,
        'Enter a valid years of experience value.',
        error: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final guide = await GuideService().updateMyGuideProfile(
        displayName: _displayName.text.trim(),
        primaryServiceArea: _primaryArea.text.trim(),
        serviceAreas: splitCsv(_serviceAreas.text),
        languages: splitCsv(_languages.text),
        yearsExperience: years,
        headline: _headline.text.trim(),
        bio: _bio.text.trim(),
        specialties: splitCsv(_specialties.text),
      );

      if (!mounted) return;

      _setGuide(guide);

      setState(() {
        _editing = false;
      });

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
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
  }) {
    return HistoriaTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      icon: icon,
    );
  }

  void _setIndex(int index) {
    setState(() {
      _index = index;
    });
  }

  void _openNotifications() {
    setState(() {
      _index = 1;
    });
  }

  void _openProfile() {
    setState(() {
      _index = 2;
    });
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    if (created == true && mounted) {
      setState(() {
        _feedKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _guideDashboard(),

      const NotificationsContent(roleLabel: 'GUIDE ACCOUNT'),

      RoleProfileContent(
        onGuideDashboard: () {
          _setIndex(0);
        },
        onNotifications: () {
          _setIndex(1);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),

      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),

      bottomNavigationBar: HistoriaBottomNavigation(
        currentIndex: _index,
        onTap: _setIndex,

        items: const [
          HistoriaNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),

          HistoriaNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'Alerts',
          ),

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

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,

      children: [
        _GuideHomeHero(
          name: user?.fullName ?? 'Guide',
          onRefresh: _load,
          onNotifications: _openNotifications,
          onProfile: _openProfile,
          onLogout: () {
            context.read<AuthProvider>().logout();
          },
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),

          child: _loading
              ? const Padding(
                  padding: EdgeInsets.only(top: 90, bottom: 90),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF176D4E)),
                  ),
                )
              : guide == null
              ? const _GuideUnavailable()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    _GuideStatusOverview(
                      guide: guide,
                      title: _statusTitle(guide.status),
                      message: _statusMessage(guide),
                    ),

                    const SizedBox(height: 17),

                    if (guide.status == 'APPROVED')
                      _approvedHome(guide)
                    else
                      _applicationHome(guide),

                    if (guide.status != 'REJECTED') ...[
                      const SizedBox(height: 20),

                      _GuidePrimaryButton(
                        icon: _editing
                            ? Icons.close_rounded
                            : Icons.edit_outlined,

                        label: _editing
                            ? 'Close editing'
                            : guide.status == 'NEEDS_WORK'
                            ? 'Update application'
                            : guide.status == 'APPROVED'
                            ? 'Edit guide profile'
                            : 'Edit application',

                        onPressed: () {
                          setState(() {
                            _editing = !_editing;
                          });
                        },
                      ),

                      if (_editing) ...[
                        const SizedBox(height: 13),

                        _guideEditSection(guide),
                      ],
                    ],

                    const SizedBox(height: 22),

                    const _GuideSectionTitle(
                      eyebrow: 'COMMUNITY',
                      title: 'Guide feed',
                      subtitle: 'Read and share historical discovery posts.',
                    ),

                    const SizedBox(height: 11),

                    _GuidePrimaryButton(
                      icon: Icons.add_circle_outline,
                      label: 'Create Post',
                      onPressed: _openCreatePost,
                    ),

                    const SizedBox(height: 14),

                    CommunityFeed(
                      key: ValueKey(_feedKey),
                      showHeader: false,
                      onCreatePost: _openCreatePost,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _approvedHome(GuideModel guide) {
    final completion = _completionScore(guide);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        _GuidePublicSummary(guide: guide),

        const SizedBox(height: 16),

        _GuideMetricRow(
          experience: guide.yearsExperience,
          languages: guide.languages.length,
          areas: guide.serviceAreas.length,
        ),

        const SizedBox(height: 18),

        _ProfileCompletionCard(value: completion),

        const SizedBox(height: 20),

        const _GuideSectionTitle(
          eyebrow: 'YOUR GUIDE PROFILE',
          title: 'Professional details',
          subtitle:
              'The information currently stored on your approved guide profile.',
        ),

        const SizedBox(height: 11),

        _GuideSurface(
          child: Column(
            children: [
              _GuideInfoRow(
                icon: Icons.map_outlined,
                label: 'Primary area',
                value: _emptyText(guide.primaryServiceArea),
              ),

              const _GuideDivider(),

              _GuideInfoRow(
                icon: Icons.route_outlined,
                label: 'Service areas',
                value: _listText(guide.serviceAreas),
              ),

              const _GuideDivider(),

              _GuideInfoRow(
                icon: Icons.translate_outlined,
                label: 'Languages',
                value: _listText(guide.languages),
              ),

              const _GuideDivider(),

              _GuideInfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Specialties',
                value: _listText(guide.specialties),
              ),
            ],
          ),
        ),

        if ((guide.headline != null && guide.headline!.trim().isNotEmpty) ||
            (guide.bio != null && guide.bio!.trim().isNotEmpty)) ...[
          const SizedBox(height: 18),

          const _GuideSectionTitle(
            eyebrow: 'ABOUT',
            title: 'Your guide story',
            subtitle: 'The introduction stored in your guide profile.',
          ),

          const SizedBox(height: 11),

          _GuideSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                if (guide.headline != null &&
                    guide.headline!.trim().isNotEmpty) ...[
                  Text(
                    guide.headline!,
                    style: const TextStyle(
                      color: Color(0xFF163D30),
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),
                ],

                if (guide.bio != null && guide.bio!.trim().isNotEmpty)
                  Text(
                    guide.bio!,
                    style: const TextStyle(
                      color: Color(0xFF687C72),
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        const _GuideSectionTitle(
          eyebrow: 'ACCOUNT',
          title: 'Manage your guide account',
          subtitle: 'Access your profile and account notifications.',
        ),

        const SizedBox(height: 11),

        Row(
          children: [
            Expanded(
              child: _GuideShortcut(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Account details',
                onTap: _openProfile,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _GuideShortcut(
                icon: Icons.notifications_none_rounded,
                title: 'Alerts',
                subtitle: 'Notifications',
                onTap: _openNotifications,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _applicationHome(GuideModel guide) {
    final canEdit = guide.status == 'PENDING' || guide.status == 'NEEDS_WORK';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        const _GuideSectionTitle(
          eyebrow: 'APPLICATION',
          title: 'Submitted details',
          subtitle:
              'The guide information currently attached to your application.',
        ),

        const SizedBox(height: 11),

        _GuideSurface(
          child: Column(
            children: [
              _GuideInfoRow(
                icon: Icons.badge_outlined,
                label: 'Display name',
                value: _emptyText(guide.displayName),
              ),

              const _GuideDivider(),

              _GuideInfoRow(
                icon: Icons.map_outlined,
                label: 'Primary area',
                value: _emptyText(guide.primaryServiceArea),
              ),

              const _GuideDivider(),

              _GuideInfoRow(
                icon: Icons.translate_outlined,
                label: 'Languages',
                value: _listText(guide.languages),
              ),

              const _GuideDivider(),

              _GuideInfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Specialties',
                value: _listText(guide.specialties),
              ),
            ],
          ),
        ),

        if (guide.adminNote != null && guide.adminNote!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),

          _AdminFeedbackCard(note: guide.adminNote!),
        ],

        if (!canEdit && guide.status == 'REJECTED') ...[
          const SizedBox(height: 14),

          const _GuideMessageCard(
            icon: Icons.info_outline,
            title: 'Application closed',
            message:
                'This application cannot be updated from the guide dashboard.',
          ),
        ],
      ],
    );
  }

  Widget _guideEditSection(GuideModel guide) {
    final needsWork = guide.status == 'NEEDS_WORK';

    final buttonText = needsWork
        ? 'Resubmit application'
        : 'Save guide profile';

    return _GuideSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration: const BoxDecoration(
                  color: Color(0xFFE3F1E8),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF176D4E),
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      needsWork ? 'Update application' : 'Edit guide profile',

                      style: const TextStyle(
                        color: Color(0xFF153D30),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      needsWork
                          ? 'Update the requested guide details and submit again.'
                          : 'Update your guide information.',

                      style: const TextStyle(
                        color: Color(0xFF78887F),
                        fontSize: 8.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (needsWork) ...[
            const _GuideMessageCard(
              icon: Icons.info_outline,
              title: 'Admin requested changes',
              message:
                  'Saving these changes sends the application back for admin review.',
            ),

            const SizedBox(height: 14),
          ],

          _field('Display Name', _displayName, icon: Icons.badge_outlined),

          _field(
            'Primary Service Area',
            _primaryArea,
            icon: Icons.location_on_outlined,
          ),

          _field(
            'Service Areas (comma separated)',
            _serviceAreas,
            icon: Icons.route_outlined,
          ),

          _field(
            'Languages (comma separated)',
            _languages,
            icon: Icons.translate_outlined,
          ),

          _field(
            'Years of Experience',
            _experience,
            keyboardType: TextInputType.number,
            icon: Icons.history_edu_outlined,
          ),

          _field('Headline', _headline, icon: Icons.short_text),

          _field('Bio', _bio, maxLines: 4, icon: Icons.notes_outlined),

          _field(
            'Specialties (comma separated)',
            _specialties,
            icon: Icons.workspace_premium_outlined,
          ),

          const SizedBox(height: 4),

          AsyncButton(
            loading: _saving,
            onPressed: _save,
            label: buttonText,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Approved guide';

      case 'NEEDS_WORK':
        return 'Application needs updates';

      case 'REJECTED':
        return 'Application rejected';

      case 'PENDING':
      default:
        return 'Application under review';
    }
  }

  String _statusMessage(GuideModel guide) {
    switch (guide.status) {
      case 'APPROVED':
        return 'Your guide profile is visible through approved guide search.';

      case 'NEEDS_WORK':
        return guide.adminNote == null || guide.adminNote!.isEmpty
            ? 'Admin requested updates before approval.'
            : guide.adminNote!;

      case 'REJECTED':
        return guide.adminNote == null || guide.adminNote!.isEmpty
            ? 'This guide application was rejected during admin review.'
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

class _GuideHomeHero extends StatelessWidget {
  final String name;

  final VoidCallback onRefresh;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _GuideHomeHero({
    required this.name,
    required this.onRefresh,
    required this.onNotifications,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFFF7FBF8), Color(0xFFE6F3EB), Color(0xFFD3E9DC)],
        ),
      ),

      child: Stack(
        children: [
          Positioned(
            right: -35,
            bottom: -45,

            child: Container(
              width: 180,
              height: 180,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: const Color(0xFF176A4C).withValues(alpha: 0.07),
              ),
            ),
          ),

          Positioned(
            right: 12,
            bottom: -17,

            child: Icon(
              Icons.account_balance_outlined,

              size: 135,

              color: const Color(0xFF176A4C).withValues(alpha: 0.09),
            ),
          ),

          Positioned(
            left: -25,
            bottom: -25,

            child: Icon(
              Icons.landscape_outlined,

              size: 120,

              color: const Color(0xFF176A4C).withValues(alpha: 0.07),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 8, 22),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    const HistoriaLogoMark(size: 36),

                    const SizedBox(width: 9),

                    const Expanded(child: HistoriaBrandText()),

                    IconButton(
                      tooltip: 'Notifications',

                      onPressed: onNotifications,

                      icon: const Icon(
                        Icons.notifications_none_rounded,

                        color: Color(0xFF176A4C),
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF176A4C),
                      ),

                      onSelected: (value) {
                        switch (value) {
                          case 'refresh':
                            onRefresh();
                            break;

                          case 'profile':
                            onProfile();
                            break;

                          case 'logout':
                            onLogout();
                            break;
                        }
                      },

                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 9),
                              Text('Refresh'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18),
                              SizedBox(width: 9),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18),
                              SizedBox(width: 9),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.70),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: const Color(0xFFD2E5D9)),
                  ),

                  child: const Text(
                    'GUIDE WORKSPACE',

                    style: TextStyle(
                      color: Color(0xFF4D806A),

                      fontSize: 7,

                      letterSpacing: 1,

                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'Welcome, $name',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Color(0xFF133C2E),

                    fontSize: 25,

                    height: 1,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Manage your HISTORIA guide profile and application.',

                  style: TextStyle(
                    color: Color(0xFF596B62),

                    fontSize: 10,

                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStatusOverview extends StatelessWidget {
  final GuideModel guide;
  final String title;
  final String message;

  const _GuideStatusOverview({
    required this.guide,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final style = _GuideStatusStyle.from(guide.status);

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [style.background, Colors.white],
        ),

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: style.border),

        boxShadow: const [
          BoxShadow(
            color: Color(0x09083A2A),

            blurRadius: 12,

            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: style.iconBackground,

              shape: BoxShape.circle,
            ),

            child: Icon(style.icon, color: style.foreground, size: 23),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,

                        style: const TextStyle(
                          color: Color(0xFF173E31),

                          fontSize: 13,

                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: style.foreground,

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        guide.status.replaceAll('_', ' '),

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 6.4,

                          fontWeight: FontWeight.w800,

                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  message,

                  style: const TextStyle(
                    color: Color(0xFF718279),

                    fontSize: 9,

                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePublicSummary extends StatelessWidget {
  final GuideModel guide;

  const _GuidePublicSummary({required this.guide});

  @override
  Widget build(BuildContext context) {
    return _GuideSurface(
      strongShadow: true,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 62,
            height: 62,

            alignment: Alignment.center,

            decoration: const BoxDecoration(
              color: Color(0xFFDDEFE4),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.badge_outlined,

              size: 29,

              color: Color(0xFF176B4C),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  guide.displayName.trim().isEmpty
                      ? 'Guide'
                      : guide.displayName,

                  style: const TextStyle(
                    color: Color(0xFF143C2F),

                    fontSize: 16,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,

                      size: 13,

                      color: Color(0xFF72847A),
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        guide.primaryServiceArea.trim().isEmpty
                            ? 'Not provided'
                            : guide.primaryServiceArea,

                        style: const TextStyle(
                          color: Color(0xFF72847A),

                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFF176E4D),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: const Text(
                    'APPROVED GUIDE',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 6.5,

                      letterSpacing: 0.4,

                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideMetricRow extends StatelessWidget {
  final int experience;
  final int languages;
  final int areas;

  const _GuideMetricRow({
    required this.experience,
    required this.languages,
    required this.areas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),

      decoration: BoxDecoration(
        color: const Color(0xFFE4F2E9),

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: const Color(0xFFCEE5D7)),
      ),

      child: Row(
        children: [
          Expanded(
            child: _GuideMetric(value: experience.toString(), label: 'YEARS'),
          ),

          const _GuideMetricDivider(),

          Expanded(
            child: _GuideMetric(
              value: languages.toString(),
              label: 'LANGUAGES',
            ),
          ),

          const _GuideMetricDivider(),

          Expanded(
            child: _GuideMetric(value: areas.toString(), label: 'AREAS'),
          ),
        ],
      ),
    );
  }
}

class _GuideMetric extends StatelessWidget {
  final String value;
  final String label;

  const _GuideMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,

          style: const TextStyle(
            color: Color(0xFF176A4C),

            fontSize: 20,

            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,

          style: const TextStyle(
            color: Color(0xFF708279),

            fontSize: 6.7,

            letterSpacing: 0.6,

            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GuideMetricDivider extends StatelessWidget {
  const _GuideMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFFC3DDCD));
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final double value;

  const _ProfileCompletionCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();

    return _GuideSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration: const BoxDecoration(
                  color: Color(0xFFE5F2E9),

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.donut_large_outlined,

                  size: 20,

                  color: Color(0xFF176D4E),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Profile completion',

                      style: TextStyle(
                        color: Color(0xFF163E31),

                        fontSize: 11,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Based on your current guide profile fields.',

                      style: TextStyle(color: Color(0xFF798980), fontSize: 8),
                    ),
                  ],
                ),
              ),

              Text(
                '$percent%',

                style: const TextStyle(
                  color: Color(0xFF176A4C),

                  fontSize: 18,

                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: value,

              minHeight: 8,

              backgroundColor: const Color(0xFFE0EAE4),

              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF247557),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _GuideSectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          eyebrow,

          style: const TextStyle(
            color: Color(0xFF4C856C),

            fontSize: 7.3,

            letterSpacing: 1,

            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,

          style: const TextStyle(
            color: Color(0xFF153D30),

            fontSize: 15,

            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          subtitle,

          style: const TextStyle(
            color: Color(0xFF78887F),

            fontSize: 8.8,

            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GuideSurface extends StatelessWidget {
  final Widget child;
  final bool strongShadow;

  const _GuideSurface({required this.child, this.strongShadow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFDCE8E1)),

        boxShadow: [
          BoxShadow(
            color: strongShadow
                ? const Color(0x16083A29)
                : const Color(0x08083A29),

            blurRadius: strongShadow ? 18 : 10,

            offset: Offset(0, strongShadow ? 6 : 4),
          ),
        ],
      ),

      child: child,
    );
  }
}

class _GuideInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GuideInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: const BoxDecoration(
              color: Color(0xFFE7F3EA),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, size: 18, color: const Color(0xFF267154)),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style: const TextStyle(
                    color: Color(0xFF7B8982),

                    fontSize: 7.8,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  style: const TextStyle(
                    color: Color(0xFF223F34),

                    fontSize: 10.2,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideDivider extends StatelessWidget {
  const _GuideDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFE7EEE9));
  }
}

class _GuideShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GuideShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(15),

      child: Container(
        padding: const EdgeInsets.all(13),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(15),

          border: Border.all(color: const Color(0xFFDCE8E1)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: 39,
              height: 39,

              decoration: const BoxDecoration(
                color: Color(0xFFE4F2E9),

                shape: BoxShape.circle,
              ),

              child: Icon(icon, size: 19, color: const Color(0xFF176D4E)),
            ),

            const SizedBox(height: 9),

            Text(
              title,

              style: const TextStyle(
                color: Color(0xFF163E31),

                fontSize: 10.5,

                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,

              style: const TextStyle(color: Color(0xFF798A81), fontSize: 7.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminFeedbackCard extends StatelessWidget {
  final String note;

  const _AdminFeedbackCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF5DD),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFF0DDAF)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,

            color: Color(0xFF976817),

            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Admin feedback',

                  style: TextStyle(
                    color: Color(0xFF76531B),

                    fontSize: 10.5,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  note,

                  style: const TextStyle(
                    color: Color(0xFF826B42),

                    fontSize: 8.7,

                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _GuideMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F3),

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: const Color(0xFFD7E7DD)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, color: const Color(0xFF3C755E), size: 19),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: Color(0xFF315E4D),

                    fontSize: 10,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  message,

                  style: const TextStyle(
                    color: Color(0xFF71837A),

                    fontSize: 8.5,

                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _GuidePrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,

      child: FilledButton.icon(
        onPressed: onPressed,

        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF176D4E),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        icon: Icon(icon, size: 18),

        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _GuideUnavailable extends StatelessWidget {
  const _GuideUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 30),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: const Color(0xFFDDE8E1)),
      ),

      child: const Column(
        children: [
          Icon(Icons.badge_outlined, size: 48, color: Color(0xFF176D4E)),

          SizedBox(height: 14),

          Text(
            'Guide profile unavailable',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Color(0xFF153D30),

              fontSize: 15,

              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'No guide profile was returned for this account.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Color(0xFF78887F),

              fontSize: 9,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStatusStyle {
  final Color background;
  final Color border;
  final Color foreground;
  final Color iconBackground;
  final IconData icon;

  const _GuideStatusStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.iconBackground,
    required this.icon,
  });

  factory _GuideStatusStyle.from(String status) {
    switch (status) {
      case 'APPROVED':
        return const _GuideStatusStyle(
          background: Color(0xFFEAF6EE),
          border: Color(0xFFC7E3D1),
          foreground: Color(0xFF176E4D),
          iconBackground: Color(0xFFD8EDDF),
          icon: Icons.verified_outlined,
        );

      case 'NEEDS_WORK':
        return const _GuideStatusStyle(
          background: Color(0xFFFFF7E5),
          border: Color(0xFFF0DDAE),
          foreground: Color(0xFF9B6917),
          iconBackground: Color(0xFFF8EAC7),
          icon: Icons.edit_note_outlined,
        );

      case 'REJECTED':
        return const _GuideStatusStyle(
          background: Color(0xFFFFEEEE),
          border: Color(0xFFF1C9C6),
          foreground: Color(0xFFB94B43),
          iconBackground: Color(0xFFF7DAD7),
          icon: Icons.cancel_outlined,
        );

      case 'PENDING':
      default:
        return const _GuideStatusStyle(
          background: Color(0xFFFFF8E7),
          border: Color(0xFFF0DFB6),
          foreground: Color(0xFFA16F18),
          iconBackground: Color(0xFFF8ECCD),
          icon: Icons.hourglass_top_rounded,
        );
    }
  }
}
