import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

enum ResetStep { request, verify, reset }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  ResetStep _step = ResetStep.request;
  bool _loading = false;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_email.text.trim().isEmpty &&
        _username.text.trim().isEmpty &&
        _phone.text.trim().isEmpty) {
      showAppMessage(context, 'Enter email, username or phone.', error: true);
      return;
    }

    await _run(() async {
      final result = await AuthService().forgotPassword(
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (!mounted) return;
      showAppMessage(context, result.message);
      setState(() => _step = ResetStep.verify);
    });
  }

  Future<void> _verifyCode() async {
    if (_email.text.trim().isEmpty || _code.text.trim().isEmpty) {
      showAppMessage(context, 'Email and code are required.', error: true);
      return;
    }

    await _run(() async {
      final result = await AuthService().verifyForgotPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
      );
      if (!mounted) return;
      showAppMessage(context, result.message);
      setState(() => _step = ResetStep.reset);
    });
  }

  Future<void> _resendCode() async {
    if (_email.text.trim().isEmpty) {
      showAppMessage(context, 'Email is required.', error: true);
      return;
    }

    await _run(() async {
      final result = await AuthService().resendForgotPasswordOtp(
        email: _email.text.trim(),
      );
      if (!mounted) return;
      showAppMessage(context, result.message);
    });
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty ||
        _newPassword.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      showAppMessage(context, 'Password fields are required.', error: true);
      return;
    }

    await _run(() async {
      final result = await AuthService().resetPassword(
        email: _email.text.trim(),
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      showAppMessage(context, result.message);
      Navigator.pop(context);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
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

  int get _stepIndex => switch (_step) {
    ResetStep.request => 0,
    ResetStep.verify => 1,
    ResetStep.reset => 2,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.zero,
              children: [
                HistoriaHeader(
                  title: _title,
                  subtitle: _subtitle,
                  eyebrow: 'ACCOUNT RECOVERY',
                  icon: Icons.lock_reset,
                  actions: [
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
                      HistoriaProgressStepper(
                        currentStep: _stepIndex,
                        labels: const ['Find', 'Verify', 'Reset'],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _content(),
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
    );
  }

  String get _title {
    switch (_step) {
      case ResetStep.request:
        return 'Forgot password?';
      case ResetStep.verify:
        return 'Check your email.';
      case ResetStep.reset:
        return 'Create a new password.';
    }
  }

  String get _subtitle {
    switch (_step) {
      case ResetStep.request:
        return 'Enter your account details to receive a reset code.';
      case ResetStep.verify:
        return 'Verify the reset code before changing your password.';
      case ResetStep.reset:
        return 'Set a secure password for your HISTORIA account.';
    }
  }

  Widget _content() {
    switch (_step) {
      case ResetStep.verify:
        return _verifyContent();
      case ResetStep.reset:
        return _resetContent();
      case ResetStep.request:
        return _requestContent();
    }
  }

  Widget _requestContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HistoriaInfoBox(
          title: '1 of 3',
          message:
              'Email is recommended. Username or phone can help identify the account.',
        ),
        const SizedBox(height: 16),
        HistoriaTextField(
          label: 'Email',
          hintText: 'name@example.com',
          controller: _email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        HistoriaTextField(
          label: 'Username',
          hintText: 'your_username',
          controller: _username,
          icon: Icons.person_outline,
        ),
        HistoriaTextField(
          label: 'Phone number',
          hintText: '+94 7X XXX XXXX',
          controller: _phone,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 4),
        HistoriaButton(
          loading: _loading,
          onPressed: _requestReset,
          label: 'Send recovery code',
        ),
      ],
    );
  }

  Widget _verifyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistoriaTextField(
          label: 'Email',
          hintText: 'name@example.com',
          controller: _email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        HistoriaTextField(
          label: 'Reset code',
          hintText: 'Enter code',
          controller: _code,
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 4),
        HistoriaButton(
          loading: _loading,
          onPressed: _verifyCode,
          label: 'Verify code',
        ),
        TextButton(
          onPressed: _loading ? null : _resendCode,
          child: const Text('Resend reset code'),
        ),
      ],
    );
  }

  Widget _resetContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistoriaTextField(
          label: 'New password',
          hintText: 'Use 8 or more characters',
          controller: _newPassword,
          icon: Icons.lock_outline,
          obscureText: _hideNewPassword,
          suffix: HistoriaPasswordSuffix(
            hidden: _hideNewPassword,
            onPressed: () =>
                setState(() => _hideNewPassword = !_hideNewPassword),
          ),
        ),
        HistoriaTextField(
          label: 'Confirm password',
          hintText: 'Repeat your password',
          controller: _confirmPassword,
          icon: Icons.lock_outline,
          obscureText: _hideConfirmPassword,
          suffix: HistoriaPasswordSuffix(
            hidden: _hideConfirmPassword,
            onPressed: () => setState(() {
              _hideConfirmPassword = !_hideConfirmPassword;
            }),
          ),
        ),
        const SizedBox(height: 4),
        HistoriaButton(
          loading: _loading,
          onPressed: _resetPassword,
          label: 'Reset password',
        ),
      ],
    );
  }
}
