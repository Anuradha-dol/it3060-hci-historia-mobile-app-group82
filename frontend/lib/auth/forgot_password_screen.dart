import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

enum ResetStep { request, verify, reset }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
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

  // ================================================================
  // REQUEST RESET
  // ================================================================

  Future<void> _requestReset() async {
    if (_email.text.trim().isEmpty &&
        _username.text.trim().isEmpty &&
        _phone.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Enter email, username or phone.',
        error: true,
      );
      return;
    }

    await _run(() async {
      final result = await AuthService().forgotPassword(
        username: _username.text.trim().isEmpty
            ? null
            : _username.text.trim(),
        email: _email.text.trim().isEmpty
            ? null
            : _email.text.trim(),
        phone: _phone.text.trim().isEmpty
            ? null
            : _phone.text.trim(),
      );

      if (!mounted) return;

      showAppMessage(
        context,
        result.message,
      );

      setState(() {
        _step = ResetStep.verify;
      });
    });
  }

  // ================================================================
  // VERIFY CODE
  // ================================================================

  Future<void> _verifyCode() async {
    if (_email.text.trim().isEmpty ||
        _code.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Email and code are required.',
        error: true,
      );
      return;
    }

    await _run(() async {
      final result = await AuthService().verifyForgotPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
      );

      if (!mounted) return;

      showAppMessage(
        context,
        result.message,
      );

      setState(() {
        _step = ResetStep.reset;
      });
    });
  }

  // ================================================================
  // RESEND
  // ================================================================

  Future<void> _resendCode() async {
    if (_email.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Email is required.',
        error: true,
      );
      return;
    }

    await _run(() async {
      final result = await AuthService().resendForgotPasswordOtp(
        email: _email.text.trim(),
      );

      if (!mounted) return;

      showAppMessage(
        context,
        result.message,
      );
    });
  }

  // ================================================================
  // RESET PASSWORD
  // ================================================================

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty ||
        _newPassword.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      showAppMessage(
        context,
        'Password fields are required.',
        error: true,
      );
      return;
    }

    if (_newPassword.text != _confirmPassword.text) {
      showAppMessage(
        context,
        'Passwords do not match.',
        error: true,
      );
      return;
    }

    await _run(() async {
      final result = await AuthService().resetPassword(
        email: _email.text.trim(),
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );

      if (!mounted) return;

      showAppMessage(
        context,
        result.message,
      );

      Navigator.pop(context);
    });
  }

  // ================================================================
  // RUN ASYNC ACTION
  // ================================================================

  Future<void> _run(
      Future<void> Function() action,
      ) async {
    setState(() {
      _loading = true;
    });

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
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ================================================================
  // STEP INDEX
  // ================================================================

  int get _stepIndex {
    switch (_step) {
      case ResetStep.request:
        return 0;
      case ResetStep.verify:
        return 1;
      case ResetStep.reset:
        return 2;
    }
  }

  // ================================================================
  // BACK
  // ================================================================

  void _back() {
    if (_step == ResetStep.reset) {
      setState(() {
        _step = ResetStep.verify;
      });
      return;
    }

    if (_step == ResetStep.verify) {
      setState(() {
        _step = ResetStep.request;
      });
      return;
    }

    Navigator.maybePop(context);
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final keyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: _step == ResetStep.request,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _back();
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF0F7F3),

        body: Stack(
          children: [
            // ========================================================
            // BACKGROUND
            // ========================================================
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF9FCF9),
                    Color(0xFFF1F8F4),
                    Color(0xFFEAF5EF),
                  ],
                ),
              ),
            ),

            // ========================================================
            // DECORATION
            // ========================================================
            Positioned(
              top: 115,
              right: -75,
              child: Container(
                width: 185,
                height: 185,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD3EBDD)
                      .withValues(alpha: 0.28),
                ),
              ),
            ),

            Positioned(
              top: 345,
              left: -90,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDDEFE5)
                      .withValues(alpha: 0.24),
                ),
              ),
            ),

            // ========================================================
            // PAGE
            // ========================================================
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),

                  child: Column(
                    children: [
                      // =================================================
                      // HEADER
                      // =================================================
                      HistoriaHeader(
                        title: _title,
                        subtitle: _subtitle,
                        eyebrow:
                        'ACCOUNT RECOVERY · STEP ${(_stepIndex + 1).toString().padLeft(2, '0')} OF 03',
                        icon: Icons.lock_reset_rounded,
                        actions: [
                          HistoriaIconButton(
                            icon: _step == ResetStep.request
                                ? Icons.close
                                : Icons.arrow_back,
                            tooltip: _step == ResetStep.request
                                ? 'Close'
                                : 'Back',
                            onPressed: _back,
                          ),
                        ],
                      ),

                      // =================================================
                      // SCROLLABLE CONTENT
                      // =================================================
                      Expanded(
                        child: ListView(
                          physics:
                          const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior
                              .onDrag,
                          padding:
                          const EdgeInsets.fromLTRB(
                            17,
                            8,
                            17,
                            15,
                          ),

                          children: [
                            // ===========================================
                            // PROGRESS
                            // ===========================================
                            HistoriaProgressStepper(
                              currentStep: _stepIndex,
                              labels: const [
                                'Find',
                                'Verify',
                                'Reset',
                              ],
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            // ===========================================
                            // STEP CARD
                            // ===========================================
                            Container(
                              padding:
                              const EdgeInsets.fromLTRB(
                                14,
                                13,
                                14,
                                12,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF7FBF8),
                                    Color(0xFFECF6F0),
                                  ],
                                ),
                                borderRadius:
                                BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                  const Color(0xFFCFE3D8),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x09123F30),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),

                              child: AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 180,
                                ),
                                switchInCurve:
                                Curves.easeOut,
                                switchOutCurve:
                                Curves.easeIn,

                                child: KeyedSubtree(
                                  key: ValueKey(_step),
                                  child: _content(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =================================================
                      // FIXED BOTTOM IMAGE
                      // =================================================
                      if (!keyboardOpen)
                        const _ForgotPasswordFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TITLES
  // ================================================================

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

  // ================================================================
  // CONTENT ROUTER
  // ================================================================

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

  // ================================================================
  // STEP 01 - FIND ACCOUNT
  // ================================================================

  Widget _requestContent() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        const _RecoverySectionHeading(
          icon: Icons.person_search_outlined,
          title: 'Find your account',
          subtitle:
          'Enter the account information you remember.',
        ),

        const SizedBox(height: 12),

        const HistoriaInfoBox(
          title: 'Account recovery',
          message:
          'Email is recommended. Username or phone can also help identify the account.',
          icon: Icons.info_outline,
        ),

        const SizedBox(height: 12),

        HistoriaTextField(
          label: 'Email',
          hintText: 'name@example.com',
          controller: _email,
          icon: Icons.email_outlined,
          keyboardType:
          TextInputType.emailAddress,
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
          keyboardType:
          TextInputType.phone,
        ),

        const SizedBox(height: 10),

        HistoriaButton(
          loading: _loading,
          onPressed: _requestReset,
          label: 'Send recovery code',
          icon: Icons.mark_email_unread_outlined,
        ),
      ],
    );
  }

  // ================================================================
  // STEP 02 - VERIFY
  // ================================================================

  Widget _verifyContent() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        const _RecoverySectionHeading(
          icon: Icons.mark_email_read_outlined,
          title: 'Verify reset code',
          subtitle:
          'Enter the code sent to your recovery email.',
        ),

        const SizedBox(height: 12),

        HistoriaInfoBox(
          title: 'Check your inbox',
          message: _email.text.trim().isEmpty
              ? 'Enter your email address and the reset code you received.'
              : 'We sent a password reset code to ${_email.text.trim()}.',
          icon: Icons.mail_outline,
        ),

        const SizedBox(height: 12),

        HistoriaTextField(
          label: 'Email',
          hintText: 'name@example.com',
          controller: _email,
          icon: Icons.email_outlined,
          keyboardType:
          TextInputType.emailAddress,
        ),

        HistoriaTextField(
          label: 'Reset code',
          hintText: 'Enter code',
          controller: _code,
          icon: Icons.pin_outlined,
          keyboardType:
          TextInputType.number,
        ),

        const SizedBox(height: 9),

        HistoriaButton(
          loading: _loading,
          onPressed: _verifyCode,
          label: 'Verify code',
          icon: Icons.verified_outlined,
        ),

        const SizedBox(height: 2),

        Center(
          child: TextButton.icon(
            onPressed:
            _loading ? null : _resendCode,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 14,
            ),
            label: const Text(
              'Resend reset code',
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STEP 03 - RESET
  // ================================================================

  Widget _resetContent() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        const _RecoverySectionHeading(
          icon: Icons.password_outlined,
          title: 'New password',
          subtitle:
          'Create a new secure password for your HISTORIA account.',
        ),

        const SizedBox(height: 12),

        const HistoriaInfoBox(
          title: 'Password guidance',
          message:
          'Use 8 or more characters and enter the same password twice.',
          icon: Icons.shield_outlined,
        ),

        const SizedBox(height: 12),

        HistoriaTextField(
          label: 'New password',
          hintText:
          'Use 8 or more characters',
          controller: _newPassword,
          icon: Icons.lock_outline,
          obscureText:
          _hideNewPassword,
          suffix:
          HistoriaPasswordSuffix(
            hidden: _hideNewPassword,
            onPressed: () {
              setState(() {
                _hideNewPassword =
                !_hideNewPassword;
              });
            },
          ),
        ),

        HistoriaTextField(
          label: 'Confirm password',
          hintText:
          'Repeat your password',
          controller:
          _confirmPassword,
          icon:
          Icons.lock_outline,
          obscureText:
          _hideConfirmPassword,
          suffix:
          HistoriaPasswordSuffix(
            hidden:
            _hideConfirmPassword,
            onPressed: () {
              setState(() {
                _hideConfirmPassword =
                !_hideConfirmPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        HistoriaButton(
          loading: _loading,
          onPressed: _resetPassword,
          label: 'Reset password',
          icon: Icons.lock_reset_rounded,
        ),
      ],
    );
  }
}

// =====================================================================
// STEP SECTION HEADING
// =====================================================================

class _RecoverySectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RecoverySectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEFE5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 21,
            color:
            const Color(0xFF1D7452),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color:
                  Color(0xFF123F32),
                  fontSize: 13.5,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color:
                  Color(0xFF6A7C73),
                  fontSize: 9.8,
                  height: 1.3,
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
// BOTTOM IMAGE
//
// IMAGE EKA WITHARAI.
// EXTRA WAVE PAINTER / TEXT NAHA.
// =====================================================================

class _ForgotPasswordFooter extends StatelessWidget {
  const _ForgotPasswordFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,

      child: Image.asset(
        'assets/images/historia_forgot_footer.png',

        width: double.infinity,
        height: 140,

        fit: BoxFit.cover,

        alignment:
        Alignment.bottomCenter,

        filterQuality:
        FilterQuality.high,

        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return Container(
            width: double.infinity,
            height: 140,
            color:
            const Color(0xFFEAF5EE),
          );
        },
      ),
    );
  }
}