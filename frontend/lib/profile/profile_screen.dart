import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../auth/login_screen.dart';
import '../models/guide_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/guide_service.dart';
import '../services/user_service.dart';
import '../tourist/notifications_screen.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'approved_guides_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAF7),
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
  final _userService = UserService();
  final _guideService = GuideService();
  final _imagePicker = ImagePicker();

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
  bool _uploadingProfileImage = false;
  bool _uploadingCoverImage = false;

  bool _showEditProfile = false;
  bool _showSecurity = false;

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
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final profile = await _userService.getMyProfile();

      GuideModel? guide;
      String? guideError;

      if (profile.role == 'GUIDE') {
        try {
          guide = await _guideService.getMyGuideProfile();
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

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      debugPrint('Profile media update failed: $e');

      final message = ApiService.instance.getErrorMessage(e);

      showAppMessage(
        context,
        message == 'Something went wrong.'
            ? 'Unable to select or upload this image.'
            : message,
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

  Future<void> _updateProfile() async {
    setState(() {
      _saving = true;
    });

    try {
      final updated = await _userService.updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _profile = updated;
        _showEditProfile = false;
      });

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
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    await _pickAndSaveProfileMedia(cover: false);
  }

  Future<void> _pickCoverImage() async {
    await _pickAndSaveProfileMedia(cover: true);
  }

  Future<void> _pickAndSaveProfileMedia({required bool cover}) async {
    if (_saving || _uploadingProfileImage || _uploadingCoverImage) {
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: cover ? 88 : 86,
        maxWidth: cover ? 2200 : 1200,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;
        showAppMessage(
          context,
          'Selected image could not be read.',
          error: true,
        );
        return;
      }

      setState(() {
        if (cover) {
          _uploadingCoverImage = true;
        } else {
          _uploadingProfileImage = true;
        }
      });

      final imageUrl = cover
          ? await _userService.uploadCoverImage(
              imageBytes: bytes,
              fileName: _mediaFileName(picked, 'cover'),
            )
          : await _userService.uploadProfileImage(
              imageBytes: bytes,
              fileName: _mediaFileName(picked, 'profile'),
            );

      final updated = await _userService.updateProfile(
        profileImageUrl: cover ? null : imageUrl,
        coverImageUrl: cover ? imageUrl : null,
      );

      if (!mounted) return;

      setState(() {
        _profile = updated;
      });

      await context.read<AuthProvider>().refreshProfile();

      if (!mounted) return;

      showAppMessage(
        context,
        cover ? 'Cover photo updated.' : 'Profile photo updated.',
      );
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
          if (cover) {
            _uploadingCoverImage = false;
          } else {
            _uploadingProfileImage = false;
          }
        });
      }
    }
  }

  String _mediaFileName(XFile file, String fallback) {
    final name = file.name.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return '$fallback-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  Future<void> _changePassword() async {
    if (_currentPassword.text.isEmpty ||
        _newPassword.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      showAppMessage(context, 'Password fields are required.', error: true);
      return;
    }

    if (_newPassword.text != _confirmPassword.text) {
      showAppMessage(context, 'New passwords do not match.', error: true);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result = await _userService.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );

      if (!mounted) return;

      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();

      setState(() {
        _showSecurity = false;
      });

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
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    _deletePassword.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete account',
            style: TextStyle(
              color: Color(0xFF173C30),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: _deletePassword,
            obscureText: true,
            decoration: fieldDecoration('Current password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC7473F),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _deletePassword.text.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result = await _userService.deleteAccount(
        currentPassword: _deletePassword.text,
      );

      if (!mounted) return;

      showAppMessage(context, result.message);

      await context.read<AuthProvider>().logout();

      if (!mounted) return;

      _goToLogin();
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

  Future<void> _logout() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    _goToLogin();
  }

  void _goToLogin() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openNotifications() {
    if (widget.onNotifications != null) {
      widget.onNotifications!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openApprovedGuides() {
    if (widget.onTouristGuides != null) {
      widget.onTouristGuides!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApprovedGuidesScreen()),
    );
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF176B4D)),
      );
    }

    final profile = _profile;

    if (profile == null) {
      return const Center(child: Text('Profile details are not available.'));
    }

    switch (profile.role) {
      case 'GUIDE':
        return _buildGuideProfile(profile);

      case 'ADMIN':
        return _buildAdminProfile(profile);

      case 'TOURIST':
      default:
        return _buildTouristProfile(profile);
    }
  }

  Widget _buildTouristProfile(UserModel profile) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _TouristHero(
          profile: profile,
          initials: _initials(profile.fullName),
          onNotification: _openNotifications,
          onClose: widget.standalone ? () => Navigator.maybePop(context) : null,
          onPickProfileImage: _pickProfileImage,
          onPickCoverImage: _pickCoverImage,
          uploadingProfileImage: _uploadingProfileImage,
          uploadingCoverImage: _uploadingCoverImage,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle(
                eyebrow: 'QUICK ACCESS',
                title: 'Your account',
                subtitle: 'Access guides and your HISTORIA updates.',
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.travel_explore,
                      title: 'Find guides',
                      subtitle: 'Approved local guides',
                      onTap: _openApprovedGuides,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ActionTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Account updates',
                      onTap: _openNotifications,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                eyebrow: 'PROFILE',
                title: 'Account details',
                subtitle: 'Your current HISTORIA account information.',
              ),

              const SizedBox(height: 11),

              _WhiteCard(
                child: Column(
                  children: [
                    _InfoLine(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: profile.username,
                    ),

                    const _SoftDivider(),

                    _InfoLine(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profile.email,
                    ),

                    const _SoftDivider(),

                    _InfoLine(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _emptyText(profile.phone),
                    ),

                    const _SoftDivider(),

                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: _emptyText(profile.address),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _PrimaryButton(
                icon: _showEditProfile ? Icons.close : Icons.edit_outlined,
                label: _showEditProfile ? 'Close edit' : 'Edit profile',
                onPressed: () {
                  setState(() {
                    _showEditProfile = !_showEditProfile;
                  });
                },
              ),

              if (_showEditProfile) ...[
                const SizedBox(height: 12),
                _buildEditSection(),
              ],

              const SizedBox(height: 10),

              _OutlineProfileButton(
                icon: Icons.lock_outline,
                label: _showSecurity ? 'Close security' : 'Change password',
                onPressed: () {
                  setState(() {
                    _showSecurity = !_showSecurity;
                  });
                },
              ),

              if (_showSecurity) ...[
                const SizedBox(height: 12),
                _buildSecuritySection(),
              ],

              const SizedBox(height: 20),

              _buildLogout(),

              const SizedBox(height: 10),

              _buildDeleteAccount(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideProfile(UserModel profile) {
    final guide = _guide;

    final guideName = guide?.displayName;

    final displayName = guideName != null && guideName.trim().isNotEmpty
        ? guideName.trim()
        : profile.fullName;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _GuideHero(
          profile: profile,
          onRefresh: _load,
          onClose: widget.standalone ? () => Navigator.maybePop(context) : null,
          onPickCoverImage: _pickCoverImage,
          uploadingCoverImage: _uploadingCoverImage,
        ),

        Transform.translate(
          offset: const Offset(0, -31),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GuideIdentityCard(
                  initials: _initials(profile.fullName),
                  profileImageUrl: profile.profileImageUrl,
                  name: displayName,
                  area: _emptyText(guide?.primaryServiceArea),
                  status: guide?.status ?? 'PENDING',
                  onPickProfileImage: _pickProfileImage,
                  uploadingProfileImage: _uploadingProfileImage,
                ),

                const SizedBox(height: 12),

                if (guide == null)
                  _WhiteCard(
                    child: HistoriaInfoBox(
                      title: 'Guide profile',
                      message:
                          _guideError ??
                          'Guide details are not available right now.',
                      icon: Icons.badge_outlined,
                    ),
                  )
                else ...[
                  _GuideStats(
                    experience: guide.yearsExperience,
                    languages: guide.languages.length,
                    areas: guide.serviceAreas.length,
                  ),

                  const SizedBox(height: 22),

                  const _SectionTitle(
                    eyebrow: 'PUBLIC GUIDE PROFILE',
                    title: 'About your guiding',
                    subtitle: 'The guide information stored in your profile.',
                  ),

                  const SizedBox(height: 11),

                  _WhiteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (guide.headline != null &&
                            guide.headline!.trim().isNotEmpty) ...[
                          Text(
                            guide.headline!,
                            style: const TextStyle(
                              color: Color(0xFF133D2F),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 9),
                        ],

                        Text(
                          guide.bio == null || guide.bio!.trim().isEmpty
                              ? 'Not provided'
                              : guide.bio!,
                          style: const TextStyle(
                            color: Color(0xFF63776D),
                            fontSize: 11,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    eyebrow: 'SERVICE',
                    title: 'Where you guide',
                    subtitle: 'Your current service information.',
                  ),

                  const SizedBox(height: 11),

                  _WhiteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GuideDetailLine(
                          icon: Icons.map_outlined,
                          label: 'Primary service area',
                          value: _emptyText(guide.primaryServiceArea),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Service areas',
                          style: TextStyle(
                            color: Color(0xFF75867E),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 7),

                        if (guide.serviceAreas.isEmpty)
                          const Text(
                            'Not provided',
                            style: TextStyle(
                              color: Color(0xFF213F34),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: guide.serviceAreas
                                .map((area) => _GuideTag(text: area))
                                .toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    eyebrow: 'EXPERTISE',
                    title: 'Guide details',
                    subtitle: 'Your language and specialty information.',
                  ),

                  const SizedBox(height: 11),

                  _WhiteCard(
                    child: Column(
                      children: [
                        _InfoLine(
                          icon: Icons.translate_outlined,
                          label: 'Languages',
                          value: _listText(guide.languages),
                        ),

                        const _SoftDivider(),

                        _InfoLine(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Specialties',
                          value: _listText(guide.specialties),
                        ),
                      ],
                    ),
                  ),

                  if (guide.adminNote != null &&
                      guide.adminNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),

                    _AdminNoteCard(text: guide.adminNote!),
                  ],
                ],

                const SizedBox(height: 18),

                if (widget.onGuideDashboard != null) ...[
                  _PrimaryButton(
                    icon: Icons.dashboard_outlined,
                    label: 'Guide dashboard',
                    onPressed: widget.onGuideDashboard!,
                  ),

                  const SizedBox(height: 10),
                ],

                _OutlineProfileButton(
                  icon: _showEditProfile ? Icons.close : Icons.edit_outlined,
                  label: _showEditProfile
                      ? 'Close account edit'
                      : 'Edit account details',
                  onPressed: () {
                    setState(() {
                      _showEditProfile = !_showEditProfile;
                    });
                  },
                ),

                if (_showEditProfile) ...[
                  const SizedBox(height: 12),
                  _buildEditSection(),
                ],

                const SizedBox(height: 10),

                _OutlineProfileButton(
                  icon: Icons.lock_outline,
                  label: _showSecurity ? 'Close security' : 'Change password',
                  onPressed: () {
                    setState(() {
                      _showSecurity = !_showSecurity;
                    });
                  },
                ),

                if (_showSecurity) ...[
                  const SizedBox(height: 12),
                  _buildSecuritySection(),
                ],

                const SizedBox(height: 20),

                _buildLogout(),

                const SizedBox(height: 10),

                _buildDeleteAccount(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminProfile(UserModel profile) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _AdminHero(
          profile: profile,
          onRefresh: _load,
          onClose: widget.standalone ? () => Navigator.maybePop(context) : null,
          onPickProfileImage: _pickProfileImage,
          onPickCoverImage: _pickCoverImage,
          uploadingProfileImage: _uploadingProfileImage,
          uploadingCoverImage: _uploadingCoverImage,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle(
                eyebrow: 'ADMIN ACCOUNT',
                title: 'Account details',
                subtitle: 'Your HISTORIA administrator account.',
              ),

              const SizedBox(height: 11),

              _WhiteCard(
                child: Column(
                  children: [
                    _InfoLine(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: profile.username,
                    ),

                    const _SoftDivider(),

                    _InfoLine(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profile.email,
                    ),

                    const _SoftDivider(),

                    _InfoLine(
                      icon: Icons.verified_user_outlined,
                      label: 'Email status',
                      value: profile.emailVerified ? 'Verified' : 'Pending',
                    ),
                  ],
                ),
              ),

              if (widget.onAdminApplications != null) ...[
                const SizedBox(height: 16),

                _PrimaryButton(
                  icon: Icons.fact_check_outlined,
                  label: 'Guide applications',
                  onPressed: widget.onAdminApplications!,
                ),
              ],

              const SizedBox(height: 18),

              _OutlineProfileButton(
                icon: _showEditProfile ? Icons.close : Icons.edit_outlined,
                label: _showEditProfile ? 'Close edit' : 'Edit account details',
                onPressed: () {
                  setState(() {
                    _showEditProfile = !_showEditProfile;
                  });
                },
              ),

              if (_showEditProfile) ...[
                const SizedBox(height: 12),
                _buildEditSection(),
              ],

              const SizedBox(height: 10),

              _OutlineProfileButton(
                icon: Icons.lock_outline,
                label: _showSecurity ? 'Close security' : 'Change password',
                onPressed: () {
                  setState(() {
                    _showSecurity = !_showSecurity;
                  });
                },
              ),

              if (_showSecurity) ...[
                const SizedBox(height: 12),
                _buildSecuritySection(),
              ],

              const SizedBox(height: 20),

              _buildLogout(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditSection() {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Personal information',
            style: TextStyle(
              color: Color(0xFF153D30),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

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

                  const SizedBox(width: 10),

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

          const SizedBox(height: 4),

          AsyncButton(
            loading: _saving,
            onPressed: _updateProfile,
            label: 'Save changes',
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Change password',
            style: TextStyle(
              color: Color(0xFF153D30),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          _field(
            'Current password',
            _currentPassword,
            obscure: true,
            icon: Icons.lock_outline,
          ),

          _field(
            'New password',
            _newPassword,
            obscure: true,
            icon: Icons.password_outlined,
          ),

          _field(
            'Confirm password',
            _confirmPassword,
            obscure: true,
            icon: Icons.lock_reset_outlined,
          ),

          const SizedBox(height: 4),

          AsyncButton(
            loading: _saving,
            onPressed: _changePassword,
            label: 'Change password',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildLogout() {
    return _OutlineProfileButton(
      icon: Icons.logout_rounded,
      label: 'Logout',
      onPressed: _saving ? null : _logout,
    );
  }

  Widget _buildDeleteAccount() {
    if (_profile?.role == 'ADMIN') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 49,
      child: OutlinedButton.icon(
        onPressed: _saving ? null : _deleteAccount,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC64C44),
          side: const BorderSide(color: Color(0xFFEBC6C2)),
          backgroundColor: const Color(0xFFFFFAFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text(
          'Delete account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'H';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
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

class _ProfileHeroShell extends StatelessWidget {
  final UserModel profile;
  final String initials;
  final String roleLabel;
  final String title;
  final String subtitle;
  final Color accent;
  final bool dark;
  final String statusText;
  final bool statusSuccess;
  final List<Widget> leadingActions;
  final VoidCallback? onClose;
  final VoidCallback onPickProfileImage;
  final VoidCallback onPickCoverImage;
  final bool uploadingProfileImage;
  final bool uploadingCoverImage;

  const _ProfileHeroShell({
    required this.profile,
    required this.initials,
    required this.roleLabel,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.dark,
    required this.statusText,
    required this.statusSuccess,
    required this.leadingActions,
    required this.onClose,
    required this.onPickProfileImage,
    required this.onPickCoverImage,
    required this.uploadingProfileImage,
    required this.uploadingCoverImage,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : const Color(0xFF133C2E);
    final subtitleColor = dark
        ? const Color(0xFFD1E6DC)
        : const Color(0xFF73857B);
    final labelColor = dark ? const Color(0xFFB9DDCD) : const Color(0xFF4D806A);

    return SizedBox(
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ProfileCoverBackground(
            imageUrl: profile.coverImageUrl,
            dark: dark,
            accent: accent,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.62),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.78),
                      ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                _ProfileTopBar(
                  dark: dark,
                  actions: leadingActions,
                  onClose: onClose,
                ),
                const Spacer(),
                Row(
                  children: [
                    _EditableAvatar(
                      initials: initials,
                      imageUrl: profile.profileImageUrl,
                      size: 82,
                      accent: accent,
                      onTap: onPickProfileImage,
                      uploading: uploadingProfileImage,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roleLabel,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 7.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(
                            text: statusText,
                            success: statusSuccess,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: _CoverEditButton(
              onTap: onPickCoverImage,
              uploading: uploadingCoverImage,
              dark: dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverHeroBanner extends StatelessWidget {
  final UserModel profile;
  final String roleLabel;
  final String title;
  final String subtitle;
  final Color accent;
  final bool dark;
  final VoidCallback onPickCoverImage;
  final bool uploadingCoverImage;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const _CoverHeroBanner({
    required this.profile,
    required this.roleLabel,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.dark,
    required this.onPickCoverImage,
    required this.uploadingCoverImage,
    required this.actions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 225,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ProfileCoverBackground(
            imageUrl: profile.coverImageUrl,
            dark: dark,
            accent: accent,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 54),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileTopBar(dark: dark, actions: actions, onClose: onClose),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD2E5D9)),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Color(0xFF4D806A),
                      fontSize: 7.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF133C2E),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF596B62),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 51,
            child: _CoverEditButton(
              onTap: onPickCoverImage,
              uploading: uploadingCoverImage,
              dark: dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final bool dark;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const _ProfileTopBar({
    required this.dark,
    required this.actions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = dark ? Colors.white : const Color(0xFF176A4C);

    return Row(
      children: [
        _HistoriaMark(dark: dark),
        const SizedBox(width: 9),
        Expanded(child: _HistoriaBrand(dark: dark)),
        ...actions,
        if (onClose != null)
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close, color: iconColor),
          ),
      ],
    );
  }
}

class _ProfileCoverBackground extends StatelessWidget {
  final String? imageUrl;
  final bool dark;
  final Color accent;

  const _ProfileCoverBackground({
    required this.imageUrl,
    required this.dark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveImageUrl(imageUrl);

    if (resolved.isNotEmpty) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    if (dark) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF122F27), Color(0xFF174E3B)],
          ),
        ),
      );
    }

    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FBF8), Color(0xFFE6F3EB), Color(0xFFD3E9DC)],
        ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final double size;
  final Color accent;
  final VoidCallback onTap;
  final bool uploading;

  const _EditableAvatar({
    required this.initials,
    required this.imageUrl,
    required this.size,
    required this.accent,
    required this.onTap,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: uploading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB9D9C7), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16083B2A),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(child: _avatarContent()),
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: uploading
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarContent() {
    final resolved = ApiConfig.resolveImageUrl(imageUrl);

    if (resolved.isNotEmpty) {
      return Image.network(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initials(),
      );
    }

    return _initials();
  }

  Widget _initials() {
    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: const Color(0xFFDCEFE4),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: accent,
              fontSize: size * 0.29,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverEditButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool uploading;
  final bool dark;

  const _CoverEditButton({
    required this.onTap,
    required this.uploading,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change cover photo',
      child: InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.26)
                  : const Color(0xFFD2E5D9),
            ),
          ),
          child: uploading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF176A4C),
                  ),
                )
              : Icon(
                  Icons.add_photo_alternate_outlined,
                  color: dark ? Colors.white : const Color(0xFF176A4C),
                  size: 19,
                ),
        ),
      ),
    );
  }
}

class _TouristHero extends StatelessWidget {
  final UserModel profile;
  final String initials;

  final VoidCallback onNotification;
  final VoidCallback? onClose;
  final VoidCallback onPickProfileImage;
  final VoidCallback onPickCoverImage;
  final bool uploadingProfileImage;
  final bool uploadingCoverImage;

  const _TouristHero({
    required this.profile,
    required this.initials,
    required this.onNotification,
    required this.onClose,
    required this.onPickProfileImage,
    required this.onPickCoverImage,
    required this.uploadingProfileImage,
    required this.uploadingCoverImage,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileHeroShell(
      profile: profile,
      initials: initials,
      roleLabel: 'TOURIST PROFILE',
      title: profile.fullName,
      subtitle: '@${profile.username}',
      accent: const Color(0xFF176A4C),
      dark: false,
      statusText: profile.emailVerified ? 'VERIFIED' : 'EMAIL PENDING',
      statusSuccess: profile.emailVerified,
      leadingActions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotification,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF176A4C),
          ),
        ),
      ],
      onClose: onClose,
      onPickProfileImage: onPickProfileImage,
      onPickCoverImage: onPickCoverImage,
      uploadingProfileImage: uploadingProfileImage,
      uploadingCoverImage: uploadingCoverImage,
    );
  }
}

class _GuideHero extends StatelessWidget {
  final UserModel profile;
  final VoidCallback onRefresh;
  final VoidCallback? onClose;
  final VoidCallback onPickCoverImage;
  final bool uploadingCoverImage;

  const _GuideHero({
    required this.profile,
    required this.onRefresh,
    required this.onClose,
    required this.onPickCoverImage,
    required this.uploadingCoverImage,
  });

  @override
  Widget build(BuildContext context) {
    return _CoverHeroBanner(
      profile: profile,
      roleLabel: 'GUIDE PROFILE',
      title: 'Your guide profile.',
      subtitle: 'Your professional information in HISTORIA.',
      accent: const Color(0xFF176A4C),
      dark: false,
      onPickCoverImage: onPickCoverImage,
      uploadingCoverImage: uploadingCoverImage,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: Color(0xFF176A4C)),
        ),
      ],
      onClose: onClose,
    );
  }
}

class _AdminHero extends StatelessWidget {
  final UserModel profile;
  final VoidCallback onRefresh;
  final VoidCallback? onClose;
  final VoidCallback onPickProfileImage;
  final VoidCallback onPickCoverImage;
  final bool uploadingProfileImage;
  final bool uploadingCoverImage;

  const _AdminHero({
    required this.profile,
    required this.onRefresh,
    required this.onClose,
    required this.onPickProfileImage,
    required this.onPickCoverImage,
    required this.uploadingProfileImage,
    required this.uploadingCoverImage,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileHeroShell(
      profile: profile,
      initials: _fallbackInitials(profile.fullName),
      roleLabel: 'ADMIN PROFILE',
      title: profile.fullName,
      subtitle: profile.email,
      accent: const Color(0xFF176A4C),
      dark: false,
      statusText: profile.emailVerified ? 'VERIFIED ADMIN' : 'EMAIL PENDING',
      statusSuccess: profile.emailVerified,
      leadingActions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: Color(0xFF176A4C)),
        ),
      ],
      onClose: onClose,
      onPickProfileImage: onPickProfileImage,
      onPickCoverImage: onPickCoverImage,
      uploadingProfileImage: uploadingProfileImage,
      uploadingCoverImage: uploadingCoverImage,
    );
  }

  String _fallbackInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'A';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _GuideIdentityCard extends StatelessWidget {
  final String initials;
  final String? profileImageUrl;
  final String name;
  final String area;
  final String status;
  final VoidCallback onPickProfileImage;
  final bool uploadingProfileImage;

  const _GuideIdentityCard({
    required this.initials,
    required this.profileImageUrl,
    required this.name,
    required this.area,
    required this.status,
    required this.onPickProfileImage,
    required this.uploadingProfileImage,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      strongShadow: true,
      child: Row(
        children: [
          _EditableAvatar(
            initials: initials,
            imageUrl: profileImageUrl,
            size: 66,
            accent: const Color(0xFF166747),
            onTap: onPickProfileImage,
            uploading: uploadingProfileImage,
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF153D30),
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
                      color: Color(0xFF74867D),
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        area,
                        style: const TextStyle(
                          color: Color(0xFF74867D),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                _StatusBadge(
                  text: status.replaceAll('_', ' '),
                  success: status == 'APPROVED',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStats extends StatelessWidget {
  final int experience;
  final int languages;
  final int areas;

  const _GuideStats({
    required this.experience,
    required this.languages,
    required this.areas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2E8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFCFE5D7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(value: experience.toString(), label: 'YEARS'),
          ),

          const _StatDivider(),

          Expanded(
            child: _StatItem(value: languages.toString(), label: 'LANGUAGES'),
          ),

          const _StatDivider(),

          Expanded(
            child: _StatItem(value: areas.toString(), label: 'AREAS'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

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
            color: Color(0xFF6F8278),
            fontSize: 6.8,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 31, color: const Color(0xFFC3DDCE));
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionTitle({
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
            color: Color(0xFF4C846B),
            fontSize: 7.4,
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
            color: Color(0xFF78877F),
            fontSize: 9,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final bool strongShadow;

  const _WhiteCard({required this.child, this.strongShadow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8E1)),
        boxShadow: [
          BoxShadow(
            color: strongShadow
                ? const Color(0x18093829)
                : const Color(0x09093829),
            blurRadius: strongShadow ? 18 : 10,
            offset: Offset(0, strongShadow ? 6 : 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
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
            width: 37,
            height: 37,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F4EC),
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
                  style: const TextStyle(color: Color(0xFF7A8981), fontSize: 8),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF233F35),
                    fontSize: 10.5,
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

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFE8EEEA));
  }
}

class _GuideDetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GuideDetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFE7F3EA),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF236B4E)),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF7A8981), fontSize: 8),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF213F34),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideTag extends StatelessWidget {
  final String text;

  const _GuideTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F2E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9DFD2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF27694F),
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminNoteCard extends StatelessWidget {
  final String text;

  const _AdminNoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DFB7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: Color(0xFF9B6A17),
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin note',
                  style: TextStyle(
                    color: Color(0xFF78551F),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF826D47),
                    fontSize: 9,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
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
          border: Border.all(color: const Color(0xFFDDE8E1)),
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

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool success;

  const _StatusBadge({required this.text, required this.success});

  @override
  Widget build(BuildContext context) {
    final background = success
        ? const Color(0xFF176F4E)
        : const Color(0xFFE5A746);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 6.8,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({
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

class _OutlineProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlineProfileButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF176D4E),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFC9DFD2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _HistoriaMark extends StatelessWidget {
  final bool dark;

  const _HistoriaMark({this.dark = false});

  @override
  Widget build(BuildContext context) {
    return HistoriaLogoMark(dark: dark, size: 35);
  }
}

class _HistoriaBrand extends StatelessWidget {
  final bool dark;

  const _HistoriaBrand({this.dark = false});

  @override
  Widget build(BuildContext context) {
    return HistoriaBrandText(dark: dark);
  }
}
