import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _stepKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

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
      _firstName,
      _lastName,
      _city,
      _address,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_validateRequiredAccount()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AuthService().registerTourist(
        username: _username.text.trim(),
        email: _email.text.trim(),
        phone: _emptyToNull(_phone.text),
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        address: _emptyToNull(_combinedAddress()),
      );

      if (!mounted) return;
      showAppMessage(context, result.message);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: _email.text.trim())),
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
        setState(() => _loading = false);
      }
    }
  }

  void _continue() {
    final form = _stepKeys[_step].currentState;
    if (form != null && !form.validate()) {
      return;
    }

    if (_step == 2) {
      _register();
      return;
    }

    setState(() => _step += 1);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    Navigator.maybePop(context);
  }

  bool _validateRequiredAccount() {
    if (_username.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      showAppMessage(
        context,
        'Complete the required account fields.',
        error: true,
      );
      return false;
    }

    if (_password.text != _confirmPassword.text) {
      showAppMessage(context, 'Password fields must match.', error: true);
      setState(() => _step = 1);
      return false;
    }

    return true;
  }

  String? _required(String? value, String label) => requiredText(value, label);

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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _combinedAddress() {
    final address = _address.text.trim();
    final city = _city.text.trim();
    if (address.isNotEmpty && city.isNotEmpty) {
      return '$address, $city';
    }
    return address.isNotEmpty ? address : city;
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Create your account.',
      'Secure your account.',
      'Tell us about you.',
    ];
    final subtitles = [
      'Your details for exploring historical places.',
      'Create your password to continue.',
      'Only your account details are required.',
    ];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) {
          _back();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.zero,
                children: [
                  HistoriaHeader(
                    title: titles[_step],
                    subtitle: subtitles[_step],
                    eyebrow:
                        'TOURIST · STEP ${(_step + 1).toString().padLeft(2, '0')} OF 03',
                    icon: Icons.eco_outlined,
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
                          labels: const ['Account', 'Security', 'Profile'],
                        ),
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
                      ],
                    ),
                  ),
                  const HistoriaFooterArt(height: 72),
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
          validator: (value) => _required(value, 'Username'),
        ),
        HistoriaTextField(
          label: 'Email address',
          hintText: 'name@example.com',
          controller: _email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          required: true,
          validator: (value) => _required(value, 'Email address'),
        ),
        HistoriaTextField(
          label: 'Phone number (optional)',
          hintText: '+94 7X XXX XXXX',
          controller: _phone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        const HistoriaInfoBox(
          title: 'Email verification',
          message: 'We will send an activation code to your email.',
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
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
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
            onPressed: () => setState(() {
              _hideConfirmPassword = !_hideConfirmPassword;
            }),
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
                  HistoriaTextField(
                    label: 'First name (optional)',
                    hintText: 'First name',
                    controller: _firstName,
                  ),
                  HistoriaTextField(
                    label: 'Last name (optional)',
                    hintText: 'Last name',
                    controller: _lastName,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HistoriaTextField(
                    label: 'First name (optional)',
                    hintText: 'First name',
                    controller: _firstName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HistoriaTextField(
                    label: 'Last name (optional)',
                    hintText: 'Last name',
                    controller: _lastName,
                  ),
                ),
              ],
            );
          },
        ),
        HistoriaTextField(
          label: 'City (optional)',
          hintText: 'City or town',
          controller: _city,
        ),
        HistoriaTextField(
          label: 'Address (optional)',
          hintText: 'Street or area',
          controller: _address,
        ),
        const SizedBox(height: 8),
        const HistoriaInfoBox(
          title: 'Tourist account',
          message: 'You can complete or update your profile later.',
        ),
        const SizedBox(height: 18),
        HistoriaButton(
          loading: _loading,
          onPressed: _continue,
          label: 'Create tourist account',
        ),
        TextButton(
          onPressed: _loading ? null : _register,
          child: const Text('Skip optional details'),
        ),
      ],
    );
  }
}
