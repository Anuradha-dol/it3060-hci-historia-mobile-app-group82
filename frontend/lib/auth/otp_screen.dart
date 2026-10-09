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
    final code = _code.text.trim();

    if (code.isEmpty) {
      showAppMessage(context, 'Enter the OTP code.', error: true);
      return;
    }

    if (code.length != 6) {
      showAppMessage(
        context,
        'Enter the 6 digit verification code.',
        error: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await AuthService().verifyEmail(
        email: widget.email,
        code: code,
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
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_loading) return;

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
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF0F7F3),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF9FCF9),
                  Color(0xFFF0F8F3),
                  Color(0xFFEAF5EF),
                ],
              ),
            ),
          ),

          Positioned(
            top: 115,
            right: -75,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD3EBDD).withValues(alpha: 0.28),
              ),
            ),
          ),

          Positioned(
            top: 340,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDDEFE5).withValues(alpha: 0.24),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: Column(
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
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                        ),
                      ],
                    ),

                    Expanded(
                      child: ListView(
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(17, 8, 17, 5),
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,

                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  11,
                                ),

                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFF6FBF8),
                                      Color(0xFFEBF6F0),
                                    ],
                                  ),

                                  borderRadius: BorderRadius.circular(15),

                                  border: Border.all(
                                    color: const Color(0xFFCFE3D8),
                                  ),

                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x09123F30),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,

                                  children: [
                                    HistoriaInfoBox(
                                      title: 'Your inbox',
                                      message: widget.guideRegistration
                                          ? 'Verify your email first. Your guide application will then wait for admin approval.'
                                          : 'Your tourist account activates after this code is confirmed.',
                                    ),

                                    const SizedBox(height: 12),

                                    HistoriaTextField(
                                      label: 'Verification code',
                                      hintText: 'Enter 6 digit code',
                                      controller: _code,
                                      icon: Icons.pin_outlined,
                                      keyboardType: TextInputType.number,
                                    ),

                                    const SizedBox(height: 7),

                                    HistoriaButton(
                                      loading: _loading,
                                      onPressed: _verify,
                                      label: 'Verify account',
                                    ),

                                    const SizedBox(height: 1),

                                    Center(
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF176C4B,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                        ),

                                        onPressed: _loading ? null : _resend,

                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 13,
                                        ),

                                        label: const Text(
                                          'Resend code',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      size: 12,
                                      color: Color(0xFF56816B),
                                    ),

                                    const SizedBox(width: 5),

                                    Flexible(
                                      child: Text(
                                        widget.guideRegistration
                                            ? 'Your guide application continues after email verification.'
                                            : 'Your HISTORIA account activates after verification.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF6E8177),
                                              fontSize: 8.5,
                                              height: 1.2,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (!keyboardOpen) const _OtpFooterImage(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpFooterImage extends StatelessWidget {
  const _OtpFooterImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          Positioned.fill(
            top: 10,

            child: ClipPath(
              clipper: _OtpFooterClipper(),

              child: Image.asset(
                'assets/images/historia_otp_footer.png',

                width: double.infinity,
                height: 140,

                fit: BoxFit.cover,

                alignment: const Alignment(0, 0.35),

                filterQuality: FilterQuality.high,

                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFEAF5EE));
                },
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,

            child: SizedBox(
              height: 30,

              child: CustomPaint(painter: _OtpGreenWavePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpFooterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 19);

    path.quadraticBezierTo(size.width * 0.18, 5, size.width * 0.43, 12);

    path.quadraticBezierTo(size.width * 0.70, 25, size.width, 8);

    path.lineTo(size.width, size.height);

    path.lineTo(0, size.height);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _OtpGreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final firstPaint = Paint()
      ..color = const Color(0xFFDCEFE5)
      ..style = PaintingStyle.fill;

    final secondPaint = Paint()
      ..color = const Color(0xFFC6E2D3)
      ..style = PaintingStyle.fill;

    final firstPath = Path();

    firstPath.moveTo(0, 20);

    firstPath.quadraticBezierTo(size.width * 0.20, 5, size.width * 0.46, 13);

    firstPath.quadraticBezierTo(size.width * 0.74, 27, size.width, 9);

    firstPath.lineTo(size.width, 19);

    firstPath.quadraticBezierTo(size.width * 0.74, 33, size.width * 0.46, 25);

    firstPath.quadraticBezierTo(size.width * 0.20, 16, 0, 30);

    firstPath.close();

    canvas.drawPath(firstPath, firstPaint);

    final secondPath = Path();

    secondPath.moveTo(0, 26);

    secondPath.quadraticBezierTo(size.width * 0.23, 17, size.width * 0.51, 24);

    secondPath.quadraticBezierTo(size.width * 0.78, 34, size.width, 18);

    secondPath.lineTo(size.width, 25);

    secondPath.quadraticBezierTo(size.width * 0.78, 37, size.width * 0.51, 31);

    secondPath.quadraticBezierTo(size.width * 0.23, 23, 0, 34);

    secondPath.close();

    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
