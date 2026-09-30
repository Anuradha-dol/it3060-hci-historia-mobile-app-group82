import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guide_model.dart';
import '../profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/admin_guide_service.dart';
import '../services/api_service.dart';
import '../tourist/notifications_screen.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

// =====================================================================
// ADMIN HOME
// =====================================================================

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const _statuses = [
    'PENDING',
    'NEEDS_WORK',
    'APPROVED',
    'REJECTED',
  ];

  final _service = AdminGuideService();

  final Map<String, List<GuideModel>> _guidesByStatus = {
    for (final status in _statuses) status: <GuideModel>[],
  };

  String _selectedStatus = 'PENDING';

  int _index = 0;

  bool _loading = true;

  // ===================================================================
  // INIT
  // ===================================================================

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ===================================================================
  // LOAD ALL GUIDE APPLICATIONS
  // ===================================================================

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final results = await Future.wait(
        _statuses.map(
              (status) async {
            return MapEntry(
              status,
              await _service.getGuidesByStatus(status),
            );
          },
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
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ===================================================================
  // REVIEW GUIDE
  // ===================================================================

  Future<void> _review(
      GuideModel guide,
      String status,
      ) async {
    final noteController = TextEditingController(
      text: guide.adminNote ?? '',
    );

    final requiresNote =
        status == 'NEEDS_WORK' ||
            status == 'REJECTED';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = _statusPalette(status);

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            5,
            20,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            14,
            4,
            14,
            14,
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  palette.icon,
                  color: palette.main,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _decisionTitle(status),
                  style: const TextStyle(
                    color: Color(0xFF153D30),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                requiresNote
                    ? 'An admin note is required for this decision.'
                    : 'You can add an optional admin note.',
                style: const TextStyle(
                  color: Color(0xFF71837A),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: fieldDecoration(
                  'Admin note',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.main,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(11),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        guide.id == null) {
      noteController.dispose();
      return;
    }

    if (requiresNote &&
        noteController.text.trim().isEmpty) {
      noteController.dispose();

      if (!mounted) return;

      showAppMessage(
        context,
        'Admin note is required.',
        error: true,
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _service.reviewGuide(
        guideProfileId: guide.id!,
        status: status,
        adminNote:
        noteController.text.trim(),
      );

      noteController.dispose();

      await _loadAll();

      if (!mounted) return;

      showAppMessage(
        context,
        'Guide marked as ${status.replaceAll('_', ' ')}.',
      );
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
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ===================================================================
  // NAVIGATION
  // ===================================================================

  void _setIndex(int index) {
    setState(() {
      _index = index;
    });
  }

  void _openApplications({
    String status = 'PENDING',
  }) {
    setState(() {
      _selectedStatus = status;
      _index = 1;
    });
  }

  // ===================================================================
  // BUILD
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _applications(),
      _guidesDirectory(),

      const NotificationsContent(
        roleLabel: 'ADMIN ACCOUNT',
      ),

      RoleProfileContent(
        onAdminApplications: () {
          _openApplications();
        },
        onNotifications: () {
          _setIndex(3);
        },
      ),
    ];

    return Scaffold(
      backgroundColor:
      const Color(0xFFF4F8F5),

      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: pages,
        ),
      ),

      bottomNavigationBar:
      HistoriaBottomNavigation(
        currentIndex: _index,
        onTap: _setIndex,
        items: const [
          HistoriaNavItem(
            icon:
            Icons.dashboard_outlined,
            activeIcon:
            Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          HistoriaNavItem(
            icon:
            Icons.fact_check_outlined,
            activeIcon:
            Icons.fact_check_rounded,
            label: 'Apps',
          ),
          HistoriaNavItem(
            icon:
            Icons.badge_outlined,
            activeIcon:
            Icons.badge_rounded,
            label: 'Guides',
          ),
          HistoriaNavItem(
            icon:
            Icons.notifications_outlined,
            activeIcon:
            Icons.notifications_rounded,
            label: 'Alerts',
          ),
          HistoriaNavItem(
            icon:
            Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // DASHBOARD
  // ===================================================================

  Widget _dashboard() {
    final user =
        context.watch<AuthProvider>().user;

    final pending =
        _guidesByStatus['PENDING'] ?? [];

    final needsWork =
        _guidesByStatus['NEEDS_WORK'] ?? [];

    final approved =
        _guidesByStatus['APPROVED'] ?? [];

    final rejected =
        _guidesByStatus['REJECTED'] ?? [];

    final total =
        pending.length +
            needsWork.length +
            approved.length +
            rejected.length;

    return ListView(
      physics:
      const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _AdminHero(
          name:
          user?.fullName ?? 'Administrator',
          onRefresh: _loadAll,
          onApplications: () {
            _openApplications();
          },
          onProfile: () {
            _setIndex(4);
          },
          onLogout: () {
            context
                .read<AuthProvider>()
                .logout();
          },
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              if (_loading) ...[
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF176D4E),
                  backgroundColor:
                  Color(0xFFDDE9E2),
                ),
                const SizedBox(height: 16),
              ],

              const _AdminSectionTitle(
                eyebrow: 'OVERVIEW',
                title: 'Guide review status',
                subtitle:
                'Live counts from the current guide application records.',
              ),

              const SizedBox(height: 12),

              _AdminStatsGrid(
                pending: pending.length,
                approved: approved.length,
                needsWork: needsWork.length,
                rejected: rejected.length,
                total: total,
                onPending: () {
                  _openApplications(
                    status: 'PENDING',
                  );
                },
                onApproved: () {
                  _openApplications(
                    status: 'APPROVED',
                  );
                },
                onNeedsWork: () {
                  _openApplications(
                    status: 'NEEDS_WORK',
                  );
                },
                onRejected: () {
                  _openApplications(
                    status: 'REJECTED',
                  );
                },
              ),

              const SizedBox(height: 22),

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: _AdminSectionTitle(
                      eyebrow: 'REVIEW QUEUE',
                      title:
                      'Pending applications',
                      subtitle:
                      'Applications waiting for an admin decision.',
                    ),
                  ),
                  if (pending.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _openApplications(
                          status: 'PENDING',
                        );
                      },
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color:
                          Color(0xFF176D4E),
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 11),

              if (pending.isEmpty)
                const _AdminEmptyState(
                  icon: Icons.task_alt_rounded,
                  title:
                  'Review queue is clear',
                  message:
                  'There are no pending guide applications right now.',
                )
              else
                ...pending.take(3).map(
                      (guide) =>
                      _CompactGuideCard(
                        guide: guide,
                        onTap: () {
                          _openApplications(
                            status: guide.status,
                          );
                        },
                      ),
                ),

              const SizedBox(height: 20),

              const _AdminSectionTitle(
                eyebrow: 'MANAGEMENT',
                title: 'Admin tools',
                subtitle:
                'Access the guide review functions available in this build.',
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  Expanded(
                    child: _AdminShortcutCard(
                      icon: Icons
                          .fact_check_outlined,
                      title: 'Applications',
                      subtitle:
                      'Review guide status',
                      onTap: () {
                        _openApplications();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AdminShortcutCard(
                      icon:
                      Icons.badge_outlined,
                      title: 'Directory',
                      subtitle:
                      'Browse guide records',
                      onTap: () {
                        _setIndex(2);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _AdminShortcutCard(
                      icon: Icons
                          .notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Account alerts',
                      onTap: () {
                        _setIndex(3);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AdminShortcutCard(
                      icon:
                      Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Admin account',
                      onTap: () {
                        _setIndex(4);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // APPLICATIONS
  // ===================================================================

  Widget _applications() {
    final guides =
        _guidesByStatus[_selectedStatus] ??
            [];

    return ListView(
      physics:
      const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _AdminSubpageHeader(
          eyebrow: 'ADMIN / REVIEWS',
          title: 'Guide applications',
          subtitle:
          'Review applications by their current status.',
          icon:
          Icons.fact_check_outlined,
          onRefresh: _loadAll,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              const _AdminSectionTitle(
                eyebrow: 'FILTER',
                title: 'Application status',
                subtitle:
                'Choose a review state to inspect its guide applications.',
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in _statuses)
                    _AdminStatusFilter(
                      status: status,
                      count:
                      _guidesByStatus[status]
                          ?.length ??
                          0,
                      selected:
                      status ==
                          _selectedStatus,
                      onTap: () {
                        setState(() {
                          _selectedStatus =
                              status;
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading) ...[
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF176D4E),
                  backgroundColor:
                  Color(0xFFDDE9E2),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: _AdminSectionTitle(
                      eyebrow: 'APPLICATIONS',
                      title: _selectedStatus
                          .replaceAll(
                        '_',
                        ' ',
                      ),
                      subtitle:
                      '${guides.length} guide application${guides.length == 1 ? '' : 's'}',
                    ),
                  ),

                  _StatusCountBadge(
                    status: _selectedStatus,
                    count: guides.length,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (guides.isEmpty)
                _AdminEmptyState(
                  icon:
                  _statusPalette(
                    _selectedStatus,
                  ).icon,
                  title:
                  'No ${_selectedStatus.replaceAll('_', ' ').toLowerCase()} applications',
                  message:
                  'There are no guide applications in this status.',
                )
              else
                ...guides.map(
                  _reviewGuideCard,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // GUIDE DIRECTORY
  // ===================================================================

  Widget _guidesDirectory() {
    final approved =
        _guidesByStatus['APPROVED'] ?? [];

    final needsWork =
        _guidesByStatus['NEEDS_WORK'] ?? [];

    final rejected =
        _guidesByStatus['REJECTED'] ?? [];

    return ListView(
      physics:
      const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _AdminSubpageHeader(
          eyebrow: 'ADMIN / GUIDES',
          title: 'Guide directory',
          subtitle:
          'Browse guide applications grouped by review state.',
          icon: Icons.badge_outlined,
          onRefresh: _loadAll,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              if (_loading) ...[
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF176D4E),
                  backgroundColor:
                  Color(0xFFDDE9E2),
                ),
                const SizedBox(height: 16),
              ],

              _DirectoryHeading(
                status: 'APPROVED',
                title: 'Approved guides',
                count: approved.length,
              ),

              const SizedBox(height: 10),

              if (approved.isEmpty)
                const _AdminEmptyState(
                  icon:
                  Icons.verified_outlined,
                  title:
                  'No approved guides',
                  message:
                  'Approved guide records will appear here.',
                )
              else
                ...approved.map(
                      (guide) =>
                      _CompactGuideCard(
                        guide: guide,
                        onTap: () {
                          _openApplications(
                            status: 'APPROVED',
                          );
                        },
                      ),
                ),

              const SizedBox(height: 22),

              _DirectoryHeading(
                status: 'NEEDS_WORK',
                title: 'Needs work',
                count: needsWork.length,
              ),

              const SizedBox(height: 10),

              if (needsWork.isEmpty)
                const _AdminEmptyState(
                  icon:
                  Icons.edit_note_outlined,
                  title:
                  'No applications need changes',
                  message:
                  'Guide applications requiring updates will appear here.',
                )
              else
                ...needsWork.map(
                      (guide) =>
                      _CompactGuideCard(
                        guide: guide,
                        onTap: () {
                          _openApplications(
                            status: 'NEEDS_WORK',
                          );
                        },
                      ),
                ),

              const SizedBox(height: 22),

              _DirectoryHeading(
                status: 'REJECTED',
                title: 'Rejected',
                count: rejected.length,
              ),

              const SizedBox(height: 10),

              if (rejected.isEmpty)
                const _AdminEmptyState(
                  icon:
                  Icons.cancel_outlined,
                  title:
                  'No rejected applications',
                  message:
                  'Rejected guide applications will appear here.',
                )
              else
                ...rejected.map(
                      (guide) =>
                      _CompactGuideCard(
                        guide: guide,
                        onTap: () {
                          _openApplications(
                            status: 'REJECTED',
                          );
                        },
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // REVIEW GUIDE CARD
  // ===================================================================

  Widget _reviewGuideCard(
      GuideModel guide,
      ) {
    final status = guide.status;
    final palette =
    _statusPalette(status);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 13,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDCE8E1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A083829),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.badge_outlined,
                  color: palette.main,
                  size: 25,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        color:
                        Color(0xFF153D30),
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      guide.email,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                        Color(0xFF77877F),
                        fontSize: 8.5,
                      ),
                    ),

                    if (guide.phone != null &&
                        guide.phone!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        guide.phone!,
                        style: const TextStyle(
                          color:
                          Color(0xFF89978F),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              _GuideStatusBadge(
                status: status,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _AdminInfoLine(
            icon: Icons.map_outlined,
            label:
            'Primary service area',
            value: _emptyText(
              guide.primaryServiceArea,
            ),
          ),

          const _AdminDivider(),

          _AdminInfoLine(
            icon: Icons.route_outlined,
            label: 'Service areas',
            value: _listText(
              guide.serviceAreas,
            ),
          ),

          const _AdminDivider(),

          _AdminInfoLine(
            icon:
            Icons.translate_outlined,
            label: 'Languages',
            value: _listText(
              guide.languages,
            ),
          ),

          const _AdminDivider(),

          _AdminInfoLine(
            icon:
            Icons.history_edu_outlined,
            label: 'Experience',
            value:
            '${guide.yearsExperience} years',
          ),

          if (guide.specialties.isNotEmpty) ...[
            const _AdminDivider(),
            _AdminInfoLine(
              icon: Icons
                  .workspace_premium_outlined,
              label: 'Specialties',
              value: _listText(
                guide.specialties,
              ),
            ),
          ],

          if (guide.bio != null &&
              guide.bio!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 13),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color:
                const Color(0xFFF4F8F5),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Text(
                guide.bio!,
                style: const TextStyle(
                  color:
                  Color(0xFF687A71),
                  fontSize: 8.8,
                  height: 1.45,
                ),
              ),
            ),
          ],

          if (guide.adminNote != null &&
              guide.adminNote!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 13),

            _AdminNote(
              note: guide.adminNote!,
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
                      : () {
                    _review(
                      guide,
                      'APPROVED',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF176D4E,
                    ),
                  ),
                  icon: const Icon(
                    Icons.verified_outlined,
                    size: 17,
                  ),
                  label:
                  const Text('Approve'),
                ),

              if (guide.status !=
                  'NEEDS_WORK')
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                    _review(
                      guide,
                      'NEEDS_WORK',
                    );
                  },
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(
                      0xFF9A6A18,
                    ),
                    side:
                    const BorderSide(
                      color:
                      Color(0xFFE2C77E),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_note_outlined,
                    size: 17,
                  ),
                  label:
                  const Text('Needs work'),
                ),

              if (guide.status !=
                  'REJECTED')
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                    _review(
                      guide,
                      'REJECTED',
                    );
                  },
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(
                      0xFFB94B43,
                    ),
                    side:
                    const BorderSide(
                      color:
                      Color(0xFFE8B8B4),
                    ),
                  ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 17,
                  ),
                  label:
                  const Text('Reject'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // HELPERS
  // ===================================================================

  String _emptyText(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Not provided';
    }

    return value.trim();
  }

  String _listText(
      List<String> values,
      ) {
    if (values.isEmpty) {
      return 'Not provided';
    }

    return values.join(', ');
  }

  String _decisionTitle(
      String status,
      ) {
    switch (status) {
      case 'APPROVED':
        return 'Approve guide';

      case 'NEEDS_WORK':
        return 'Request changes';

      case 'REJECTED':
        return 'Reject guide';

      default:
        return 'Review guide';
    }
  }
}

// =====================================================================
// ADMIN HERO
// =====================================================================

class _AdminHero extends StatelessWidget {
  final String name;

  final VoidCallback onRefresh;
  final VoidCallback onApplications;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _AdminHero({
    required this.name,
    required this.onRefresh,
    required this.onApplications,
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
          colors: [
            Color(0xFF102F27),
            Color(0xFF174F3C),
            Color(0xFF276B50),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: 25,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                Colors.white.withValues(
                  alpha: 0.045,
                ),
              ),
            ),
          ),

          Positioned(
            right: 8,
            bottom: -14,
            child: Icon(
              Icons
                  .admin_panel_settings_outlined,
              size: 140,
              color:
              Colors.white.withValues(
                alpha: 0.055,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              11,
              8,
              22,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 9),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HISTORIA',
                            style: TextStyle(
                              color:
                              Colors.white,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w900,
                              letterSpacing:
                              0.3,
                            ),
                          ),
                          Text(
                            'ADMINISTRATION · GUIDE REVIEW',
                            style: TextStyle(
                              color: Color(
                                0xFFCBE1D6,
                              ),
                              fontSize: 6.2,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Applications',
                      onPressed:
                      onApplications,
                      icon: const Icon(
                        Icons
                            .fact_check_outlined,
                        color: Colors.white,
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
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
                      itemBuilder:
                          (context) => const [
                        PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 18,
                              ),
                              SizedBox(width: 9),
                              Text('Refresh'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .person_outline,
                                size: 18,
                              ),
                              SizedBox(width: 9),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                size: 18,
                              ),
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
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                    Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                      color:
                      Colors.white.withValues(
                        alpha: 0.13,
                      ),
                    ),
                  ),
                  child: const Text(
                    'ADMIN DASHBOARD',
                    style: TextStyle(
                      color: Color(
                        0xFFE1F0E8,
                      ),
                      fontSize: 7,
                      letterSpacing: 1,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'Welcome, $name',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Review guide applications and manage their approval status.',
                  style: TextStyle(
                    color: Color(
                      0xFFCEE2D8,
                    ),
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

// =====================================================================
// SUBPAGE HEADER
// =====================================================================

class _AdminSubpageHeader
    extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onRefresh;

  const _AdminSubpageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        12,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9FCFA),
            Color(0xFFE9F4ED),
            Color(0xFFDCEEE3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE1F0E7),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Color(0xFF176D4E),
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIA',
                      style: TextStyle(
                        color:
                        Color(0xFF153D30),
                        fontSize: 13.5,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                    Text(
                      'ADMINISTRATION',
                      style: TextStyle(
                        color:
                        Color(0xFF76877E),
                        fontSize: 6.2,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF176D4E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.68,
              ),
              borderRadius:
              BorderRadius.circular(20),
              border: Border.all(
                color:
                const Color(0xFFD2E5D9),
              ),
            ),
            child: Text(
              eyebrow,
              style: const TextStyle(
                color: Color(0xFF417A61),
                fontSize: 7,
                letterSpacing: 1,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                        Color(0xFF143C2F),
                        fontSize: 24,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                        Color(0xFF71837A),
                        fontSize: 9.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 58,
                height: 58,
                decoration:
                const BoxDecoration(
                  color:
                  Color(0xFFE4F2E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(0xFF176D4E),
                  size: 27,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SECTION TITLE
// =====================================================================

class _AdminSectionTitle
    extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _AdminSectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF4C846B),
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

// =====================================================================
// STATS GRID
// =====================================================================

class _AdminStatsGrid
    extends StatelessWidget {
  final int pending;
  final int approved;
  final int needsWork;
  final int rejected;
  final int total;

  final VoidCallback onPending;
  final VoidCallback onApproved;
  final VoidCallback onNeedsWork;
  final VoidCallback onRejected;

  const _AdminStatsGrid({
    required this.pending,
    required this.approved,
    required this.needsWork,
    required this.rejected,
    required this.total,
    required this.onPending,
    required this.onApproved,
    required this.onNeedsWork,
    required this.onRejected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AdminStatCard(
                value: pending,
                label: 'Pending',
                icon:
                Icons.hourglass_top_rounded,
                status: 'PENDING',
                onTap: onPending,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _AdminStatCard(
                value: approved,
                label: 'Approved',
                icon:
                Icons.verified_outlined,
                status: 'APPROVED',
                onTap: onApproved,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _AdminStatCard(
                value: needsWork,
                label: 'Needs work',
                icon:
                Icons.edit_note_outlined,
                status: 'NEEDS_WORK',
                onTap: onNeedsWork,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _AdminStatCard(
                value: rejected,
                label: 'Rejected',
                icon:
                Icons.cancel_outlined,
                status: 'REJECTED',
                onTap: onRejected,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color:
            const Color(0xFF173F32),
            borderRadius:
            BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                  Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Total guide records',
                  style: TextStyle(
                    color:
                    Color(0xFFD5E9DF),
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// STAT CARD
// =====================================================================

class _AdminStatCard
    extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final String status;
  final VoidCallback onTap;

  const _AdminStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
    _statusPalette(status);

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color:
            const Color(0xFFDDE8E1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08083A29),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: palette.main,
                size: 20,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '$value',
              style: TextStyle(
                color: palette.main,
                fontSize: 22,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: const TextStyle(
                color:
                Color(0xFF6F8178),
                fontSize: 9,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// SHORTCUT CARD
// =====================================================================

class _AdminShortcutCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(15),
          border: Border.all(
            color:
            const Color(0xFFDDE8E1),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 39,
              height: 39,
              decoration:
              const BoxDecoration(
                color: Color(0xFFE5F2E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                const Color(0xFF176D4E),
                size: 19,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF163E31),
                fontSize: 10.5,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF798A81),
                fontSize: 7.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// COMPACT GUIDE CARD
// =====================================================================

class _CompactGuideCard
    extends StatelessWidget {
  final GuideModel guide;
  final VoidCallback onTap;

  const _CompactGuideCard({
    required this.guide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
    _statusPalette(
      guide.status,
    );

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(15),
            border: Border.all(
              color:
              const Color(0xFFDDE8E1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: palette.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.badge_outlined,
                  color: palette.main,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                        Color(0xFF153D30),
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${guide.primaryServiceArea} · ${guide.email}',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                        Color(0xFF78887F),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              _GuideStatusBadge(
                status: guide.status,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// STATUS FILTER
// =====================================================================

class _AdminStatusFilter
    extends StatelessWidget {
  final String status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _AdminStatusFilter({
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
    _statusPalette(status);

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(30),
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? palette.soft
              : Colors.white,
          borderRadius:
          BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? palette.border
                : const Color(
                0xFFDCE8E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              palette.icon,
              size: 14,
              color: selected
                  ? palette.main
                  : const Color(
                  0xFF75867D),
            ),
            const SizedBox(width: 5),
            Text(
              '${status.replaceAll('_', ' ')} ($count)',
              style: TextStyle(
                color: selected
                    ? palette.main
                    : const Color(
                    0xFF65776E),
                fontSize: 8,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// STATUS COUNT - FIXED
// =====================================================================

class _StatusCountBadge
    extends StatelessWidget {
  final String status;
  final int count;

  const _StatusCountBadge({
    required this.status,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
    _statusPalette(status);

    return Container(
      constraints: const BoxConstraints(
        minWidth: 38,
      ),
      height: 38,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: palette.border,
        ),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: palette.main,
          fontSize: 15,
          fontWeight:
          FontWeight.w900,
        ),
      ),
    );
  }
}

// =====================================================================
// DIRECTORY HEADING
// =====================================================================

class _DirectoryHeading
    extends StatelessWidget {
  final String status;
  final String title;
  final int count;

  const _DirectoryHeading({
    required this.status,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
    _statusPalette(status);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.soft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            palette.icon,
            size: 18,
            color: palette.main,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF153D30),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        Text(
          '$count',
          style: TextStyle(
            color: palette.main,
            fontSize: 15,
            fontWeight:
            FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// STATUS BADGE
// =====================================================================

class _GuideStatusBadge
    extends StatelessWidget {
  final String status;

  const _GuideStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final palette =
    _statusPalette(status);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: palette.border,
        ),
      ),
      child: Text(
        status.replaceAll(
          '_',
          ' ',
        ),
        style: TextStyle(
          color: palette.main,
          fontSize: 6.2,
          letterSpacing: 0.3,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }
}

// =====================================================================
// ADMIN INFO LINE
// =====================================================================

class _AdminInfoLine
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AdminInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration:
            const BoxDecoration(
              color: Color(0xFFE7F3EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color:
              const Color(0xFF267154),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color:
                    Color(0xFF7A8981),
                    fontSize: 7.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color:
                    Color(0xFF223F34),
                    fontSize: 10.2,
                    fontWeight:
                    FontWeight.w700,
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

class _AdminDivider
    extends StatelessWidget {
  const _AdminDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Color(0xFFE7EEE9),
    );
  }
}

// =====================================================================
// ADMIN NOTE
// =====================================================================

class _AdminNote
    extends StatelessWidget {
  final String note;

  const _AdminNote({
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E1),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEFDCAD),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .admin_panel_settings_outlined,
            size: 18,
            color: Color(0xFF936415),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin note',
                  style: TextStyle(
                    color:
                    Color(0xFF75511B),
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(
                    color:
                    Color(0xFF816A42),
                    fontSize: 8.4,
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

// =====================================================================
// EMPTY STATE
// =====================================================================

class _AdminEmptyState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        22,
        28,
        22,
        26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDDE8E1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration:
            const BoxDecoration(
              color: Color(0xFFE6F2EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 31,
              color:
              const Color(0xFF176D4E),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF153D30),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF75867D),
              fontSize: 8.8,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// STATUS PALETTE
// =====================================================================

class _AdminStatusPalette {
  final Color main;
  final Color soft;
  final Color border;
  final IconData icon;

  const _AdminStatusPalette({
    required this.main,
    required this.soft,
    required this.border,
    required this.icon,
  });
}

_AdminStatusPalette _statusPalette(
    String status,
    ) {
  switch (status) {
    case 'APPROVED':
      return const _AdminStatusPalette(
        main: Color(0xFF176D4E),
        soft: Color(0xFFE4F3E9),
        border: Color(0xFFC6E1D1),
        icon: Icons.verified_outlined,
      );

    case 'NEEDS_WORK':
      return const _AdminStatusPalette(
        main: Color(0xFF9B6917),
        soft: Color(0xFFFFF4D8),
        border: Color(0xFFEED89C),
        icon: Icons.edit_note_outlined,
      );

    case 'REJECTED':
      return const _AdminStatusPalette(
        main: Color(0xFFB94B43),
        soft: Color(0xFFFFE9E7),
        border: Color(0xFFEDC2BE),
        icon: Icons.cancel_outlined,
      );

    case 'PENDING':
    default:
      return const _AdminStatusPalette(
        main: Color(0xFF9A701D),
        soft: Color(0xFFFFF5DB),
        border: Color(0xFFEEDCAC),
        icon: Icons.hourglass_top_rounded,
      );
  }
}