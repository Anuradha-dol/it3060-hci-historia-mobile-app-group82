import 'package:flutter/material.dart';

import '../guide/guide_pending_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool guideRegistration;

  const OtpScreen({
    super.key,
    required this.email,
    this.guideRegistration = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().isEmpty) {
      showAppMessage(context, 'Enter the OTP code.', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AuthService().verifyEmail(
        email: widget.email,
        code: _code.text.trim(),
      );

      if (!mounted) return;
      showAppMessage(context, result.message);

      if (widget.guideRegistration) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GuidePendingScreen()),
          (route) => false,
        );
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
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
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resend() async {
    try {
      final result = await AuthService().resendOtp(email: widget.email);
      if (!mounted) return;
      showAppMessage(context, result.message);
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(e),
        error: true,
      );
    }
  }

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
                  title: 'Verify your email.',
                  subtitle:
                      'Enter the verification code sent to ${widget.email}.',
                  eyebrow: widget.guideRegistration
                      ? 'GUIDE APPLICATION'
                      : 'ACCOUNT VERIFICATION',
                  icon: Icons.verified_user_outlined,
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
                      HistoriaInfoBox(
                        title: 'Your inbox',
                        message: widget.guideRegistration
                            ? 'Verify email first. Your application then waits for admin approval.'
                            : 'Your tourist account activates after this code is confirmed.',
                      ),
                      const SizedBox(height: 16),
                      HistoriaTextField(
                        label: 'Verification code',
                        hintText: 'Enter 6 digit code',
                        controller: _code,
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      HistoriaButton(
                        loading: _loading,
                        onPressed: _verify,
                        label: 'Verify account',
                      ),
                      TextButton(
                        onPressed: _loading ? null : _resend,
                        child: const Text('Resend code'),
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
}
