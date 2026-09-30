import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'otp_screen.dart';

class GuideSignupScreen extends StatefulWidget {
  const GuideSignupScreen({super.key});

  @override
  State<GuideSignupScreen> createState() => _GuideSignupScreenState();
}

class _GuideSignupScreenState extends State<GuideSignupScreen> {
  final _stepKeys = List.generate(4, (_) => GlobalKey<FormState>());

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _address = TextEditingController();

  final _displayName = TextEditingController();
  final _primaryArea = TextEditingController();
  final _serviceAreas = TextEditingController();
  final _languages = TextEditingController();
  final _experience = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _specialties = TextEditingController();

  int _step = 0;

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    for (final controller in [
      _username,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _firstName,
      _lastName,
      _address,
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

  Future<void> _register() async {
    if (!_validateRequiredAccount()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await AuthService().registerGuide(
        data: {
          'username': _username.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'password': _password.text,
          'confirmPassword': _confirmPassword.text,
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'address': _address.text.trim(),
          'displayName': _displayName.text.trim(),
          'primaryServiceArea': _primaryArea.text.trim(),

          'serviceAreas': splitCsv(_serviceAreas.text).isEmpty
              ? [_primaryArea.text.trim()]
              : splitCsv(_serviceAreas.text),

          'languages': splitCsv(_languages.text),

          'yearsExperience': int.tryParse(_experience.text.trim()) ?? 0,

          'headline': _headline.text.trim(),
          'bio': _bio.text.trim(),

          'specialties': splitCsv(_specialties.text),
        },
      );

      if (!mounted) return;

      showAppMessage(context, 'Guide application submitted.');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpScreen(email: _email.text.trim(), guideRegistration: true),
        ),
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
          _loading = false;
        });
      }
    }
  }

  void _continue() {
    final form = _stepKeys[_step].currentState;

    if (form != null && !form.validate()) {
      return;
    }

    if (_step == 3) {
      _register();
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
      });

      return;
    }

    Navigator.maybePop(context);
  }

  bool _validateRequiredAccount() {
    final requiredValues = [
      _username.text,
      _email.text,
      _phone.text,
      _password.text,
      _confirmPassword.text,
      _firstName.text,
      _lastName.text,
      _address.text,
      _displayName.text,
      _primaryArea.text,
      _languages.text,
      _experience.text,
      _headline.text,
      _bio.text,
      _specialties.text,
    ];

    if (requiredValues.any((value) => value.trim().isEmpty)) {
      showAppMessage(
        context,
        'Complete all guide application fields.',
        error: true,
      );

      return false;
    }

    if (_password.text != _confirmPassword.text) {
      showAppMessage(context, 'Password fields must match.', error: true);

      setState(() {
        _step = 1;
      });

      return false;
    }

    if (int.tryParse(_experience.text.trim()) == null) {
      showAppMessage(
        context,
        'Years of experience must be a number.',
        error: true,
      );

      setState(() {
        _step = 3;
      });

      return false;
    }

    return true;
  }

  String? _required(String? value, String label) {
    return requiredText(value, label);
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Use at least 8 characters';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != _password.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  String? _experienceValidator(String? value) {
    final required = _required(value, 'Years of experience');

    if (required != null) {
      return required;
    }

    if (int.tryParse(value!.trim()) == null) {
      return 'Enter a number';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Become a local guide.',
      'Protect your account.',
      'Introduce yourself.',
      'Review and submit.',
    ];

    final subtitles = [
      'Start with the account details admins will review.',
      'Set a password before continuing your application.',
      'Tell travellers who you are and where you guide.',
      'Add service details before final submission.',
    ];

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: _step == 0,

      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) {
          _back();
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: true,

        backgroundColor: const Color(0xFFFCFDF8),

        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),

              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const ClampingScrollPhysics(),

                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,

                      padding: EdgeInsets.zero,

                      children: [
                        HistoriaHeader(
                          title: titles[_step],
                          subtitle: subtitles[_step],
                          eyebrow:
                              'GUIDE / STEP ${(_step + 1).toString().padLeft(2, '0')} OF 04',
                          icon: Icons.badge_outlined,
                          actions: [
                            HistoriaIconButton(
                              icon: _step == 0 ? Icons.close : Icons.arrow_back,
                              tooltip: _step == 0 ? 'Close' : 'Back',
                              onPressed: _back,
                            ),
                          ],
                        ),

                        HistoriaScreenPadding(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HistoriaProgressStepper(
                                currentStep: _step,
                                labels: const [
                                  'Account',
                                  'Security',
                                  'Profile',
                                  'Review',
                                ],
                              ),

                              const SizedBox(height: 4),

                              Form(
                                key: _stepKeys[_step],

                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,

                                  child: KeyedSubtree(
                                    key: ValueKey(_step),
                                    child: _stepContent(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!keyboardOpen) const _GuideFooterImage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 1:
        return _securityStep();

      case 2:
        return _profileStep();

      case 3:
        return _reviewStep();

      case 0:
      default:
        return _accountStep();
    }
  }

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        HistoriaTextField(
          label: 'Username',
          hintText: 'Choose a username',
          controller: _username,
          icon: Icons.person_outline,
          required: true,
          validator: (value) {
            return _required(value, 'Username');
          },
        ),

        HistoriaTextField(
          label: 'Email address',
          hintText: 'guide@example.com',
          controller: _email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          required: true,
          validator: (value) {
            return _required(value, 'Email address');
          },
        ),

        HistoriaTextField(
          label: 'Phone number',
          hintText: '+94 7X XXX XXXX',
          controller: _phone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          required: true,
          validator: (value) {
            return _required(value, 'Phone number');
          },
        ),

        const SizedBox(height: 8),

        const HistoriaInfoBox(
          title: 'Guide access',
          message: 'Guides verify email and pass admin review before access.',
        ),

        const SizedBox(height: 18),

        HistoriaButton(
          loading: _loading,
          onPressed: _continue,
          label: 'Continue',
        ),

        TextButton(
          onPressed: _loading ? null : _back,
          child: const Text('Back to account type'),
        ),
      ],
    );
  }

  Widget _securityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        HistoriaTextField(
          label: 'Password',
          hintText: 'Use 8 or more characters',
          controller: _password,
          icon: Icons.lock_outline,
          required: true,
          obscureText: _hidePassword,
          validator: _passwordValidator,

          suffix: HistoriaPasswordSuffix(
            hidden: _hidePassword,
            onPressed: () {
              setState(() {
                _hidePassword = !_hidePassword;
              });
            },
          ),
        ),

        HistoriaTextField(
          label: 'Confirm password',
          hintText: 'Repeat your password',
          controller: _confirmPassword,
          icon: Icons.lock_outline,
          required: true,
          obscureText: _hideConfirmPassword,
          validator: _confirmPasswordValidator,

          suffix: HistoriaPasswordSuffix(
            hidden: _hideConfirmPassword,
            onPressed: () {
              setState(() {
                _hideConfirmPassword = !_hideConfirmPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        const HistoriaInfoBox(
          title: 'Password guidance',
          message:
              'Use 8 or more characters. The two password fields must match.',
        ),

        const SizedBox(height: 18),

        HistoriaButton(
          loading: _loading,
          onPressed: _continue,
          label: 'Continue',
        ),

        TextButton(
          onPressed: _loading ? null : _back,
          child: const Text('Back to account details'),
        ),
      ],
    );
  }

  Widget _profileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 340) {
              return Column(
                children: [
                  _textField('First name', _firstName),

                  _textField('Last name', _lastName),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(child: _textField('First name', _firstName)),

                const SizedBox(width: 12),

                Expanded(child: _textField('Last name', _lastName)),
              ],
            );
          },
        ),

        _textField('Address', _address, icon: Icons.location_on_outlined),

        _textField('Display name', _displayName, icon: Icons.badge_outlined),

        _textField(
          'Primary service area',
          _primaryArea,
          icon: Icons.map_outlined,
        ),

        const SizedBox(height: 8),

        const HistoriaInfoBox(
          title: 'Public guide profile',
          message:
              'These details help travellers understand who will guide them.',
        ),

        const SizedBox(height: 18),

        HistoriaButton(
          loading: _loading,
          onPressed: _continue,
          label: 'Continue',
        ),

        TextButton(
          onPressed: _loading ? null : _back,
          child: const Text('Back to security'),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        _textField(
          'Additional service areas',
          _serviceAreas,
          hintText: 'Kandy, Galle, Anuradhapura',
          icon: Icons.route_outlined,
        ),

        _textField(
          'Languages',
          _languages,
          hintText: 'English, Sinhala, Tamil',
          icon: Icons.translate_outlined,
        ),

        _textField(
          'Years of experience',
          _experience,
          hintText: '3',
          icon: Icons.history_edu_outlined,
          keyboardType: TextInputType.number,
          validator: _experienceValidator,
        ),

        _textField(
          'Headline',
          _headline,
          hintText: 'Discover history with a local guide',
          icon: Icons.short_text,
        ),

        _textField(
          'Bio',
          _bio,
          hintText:
              'Tell travellers about yourself and your guiding experience.',
          icon: Icons.notes_outlined,
          maxLines: 4,
        ),

        _textField(
          'Specialties',
          _specialties,
          hintText: 'Ancient cities, temples, local food',
          icon: Icons.workspace_premium_outlined,
        ),

        const SizedBox(height: 8),

        const HistoriaInfoBox(
          title: 'Review submission',
          message:
              'After email verification, an admin reviews your guide application.',
        ),

        const SizedBox(height: 18),

        HistoriaButton(
          loading: _loading,
          onPressed: _continue,
          label: 'Submit guide application',
        ),

        TextButton(
          onPressed: _loading ? null : _back,
          child: const Text('Back to profile details'),
        ),
      ],
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    String? hintText,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return HistoriaTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      icon: icon,
      keyboardType: keyboardType,
      maxLines: maxLines,
      required: true,

      validator:
          validator ??
          (value) {
            return _required(value, label);
          },
    );
  }
}

class _GuideFooterImage extends StatelessWidget {
  const _GuideFooterImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 112,

      child: Image.asset(
        'assets/images/historia_guide_footer.png',

        width: double.infinity,
        height: 112,

        fit: BoxFit.cover,

        alignment: Alignment.bottomCenter,

        filterQuality: FilterQuality.high,

        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 112,
            color: const Color(0xFFFCFDF8),
          );
        },
      ),
    );
  }
}
