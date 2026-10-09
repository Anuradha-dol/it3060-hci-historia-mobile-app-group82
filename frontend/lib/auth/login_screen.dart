import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/home_router.dart';
import '../theme/app_colors.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'account_type_screen.dart';
import 'forgot_password_screen.dart';
import 'guide_resubmit_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      identifier: _identifier.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    if (success) {
      _goToHome();
      return;
    }

    showAppMessage(context, auth.error ?? 'Login failed.', error: true);
  }

  Future<void> _googleLogin() async {
    final auth = context.read<AuthProvider>();

    final success = await auth.googleLogin();

    if (!mounted) return;

    if (success) {
      _goToHome();
      return;
    }

    showAppMessage(
      context,
      auth.error ?? 'Google Sign-In failed.',
      error: true,
    );
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeRouter()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                  Color(0xFFF8FBF8),
                  Color(0xFFEDF7F1),
                  Color(0xFFE8F4ED),
                ],
              ),
            ),
          ),

          Positioned(
            top: 110,
            right: -80,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCAE6D7).withValues(alpha: 0.25),
              ),
            ),
          ),

          Positioned(
            top: 320,
            left: -95,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD8EDE2).withValues(alpha: 0.28),
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
                      title: 'Welcome back.',
                      subtitle: 'Sign in to continue your HISTORIA journey.',
                      eyebrow: 'ONE LOGIN FOR TOURIST AND GUIDE',
                      icon: Icons.eco_outlined,
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

                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),

                        children: [
                          Form(
                            key: _formKey,

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,

                              children: [
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    13,
                                    15,
                                    12,
                                  ),

                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF4FAF6),
                                        Color(0xFFEAF5EE),
                                      ],
                                    ),

                                    borderRadius: BorderRadius.circular(16),

                                    border: Border.all(
                                      color: const Color(0xFFCFE3D8),
                                    ),

                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A123F30),
                                        blurRadius: 14,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,

                                    children: [
                                      HistoriaTextField(
                                        label: 'Email, username or phone',
                                        hintText: 'Enter your account details',
                                        controller: _identifier,
                                        icon: Icons.email_outlined,
                                        required: true,

                                        validator: (value) {
                                          return requiredText(
                                            value,
                                            'Login identifier',
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 9),

                                      HistoriaTextField(
                                        label: 'Password',
                                        hintText: 'Enter your password',
                                        controller: _password,
                                        icon: Icons.lock_outline,
                                        required: true,
                                        obscureText: _hidePassword,

                                        validator: (value) {
                                          return requiredText(
                                            value,
                                            'Password',
                                          );
                                        },

                                        suffix: HistoriaPasswordSuffix(
                                          hidden: _hidePassword,
                                          onPressed: () {
                                            setState(() {
                                              _hidePassword = !_hidePassword;
                                            });
                                          },
                                        ),
                                      ),

                                      Align(
                                        alignment: Alignment.centerRight,

                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF176C4B,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            padding: const EdgeInsets.fromLTRB(
                                              6,
                                              7,
                                              0,
                                              7,
                                            ),
                                          ),

                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },

                                          child: const Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      HistoriaButton(
                                        loading: auth.loading,
                                        onPressed: _login,
                                        label: 'Sign in',
                                      ),

                                      const SizedBox(height: 8),

                                      _GoogleButton(
                                        loading: auth.loading,
                                        onPressed: _googleLogin,
                                      ),

                                      const SizedBox(height: 13),

                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Divider(
                                              color: Color(0xFFCCDCD3),
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                            ),

                                            child: Text(
                                              'New to HISTORIA?',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF708177,
                                                    ),
                                                    fontSize: 9.8,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),

                                          const Expanded(
                                            child: Divider(
                                              color: Color(0xFFCCDCD3),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 9),

                                      HistoriaOutlineButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AccountTypeScreen(),
                                            ),
                                          );
                                        },
                                        label: 'Create an account',
                                      ),

                                      const SizedBox(height: 3),

                                      Center(
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            foregroundColor: const Color(
                                              0xFF176C4B,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8,
                                            ),
                                          ),

                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const GuideResubmitScreen(),
                                              ),
                                            );
                                          },

                                          child: const Text(
                                            'Guide needs work? Resubmit',
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

                                const SizedBox(height: 14),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),

                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      const Icon(
                                        Icons.verified_user_outlined,
                                        size: 13,
                                        color: Color(0xFF56816B),
                                      ),

                                      const SizedBox(width: 5),

                                      Flexible(
                                        child: Text(
                                          'Guide accounts require admin approval before sign in.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF6E8177),
                                                fontSize: 9.2,
                                                height: 1.15,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!keyboardOpen) const _HeritageFooter(),
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

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,

      child: OutlinedButton(
        onPressed: loading ? null : onPressed,

        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFAFDFC),

          foregroundColor: AppColors.primaryDark,

          side: const BorderSide(color: Color(0xFFCBDDD4)),

          elevation: 0,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(width: 9),

            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeritageFooter extends StatelessWidget {
  const _HeritageFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      width: double.infinity,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          Positioned.fill(
            top: 14,

            child: ClipPath(
              clipper: _LoginFooterClipper(),

              child: Image.asset(
                'assets/images/auth_footer_4k.webp',

                fit: BoxFit.cover,

                alignment: const Alignment(0, 0.15),

                filterQuality: FilterQuality.high,

                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFE8F4ED));
                },
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,

            child: SizedBox(
              height: 34,

              child: CustomPaint(painter: _LoginGreenWavePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFooterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 21);

    path.quadraticBezierTo(size.width * 0.18, 2, size.width * 0.43, 12);

    path.quadraticBezierTo(size.width * 0.71, 27, size.width, 7);

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

class _LoginGreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFDCEFE5)
      ..style = PaintingStyle.fill;

    final path1 = Path();

    path1.moveTo(0, 23);

    path1.quadraticBezierTo(size.width * 0.20, 3, size.width * 0.46, 14);

    path1.quadraticBezierTo(size.width * 0.74, 29, size.width, 8);

    path1.lineTo(size.width, 22);

    path1.quadraticBezierTo(size.width * 0.74, 38, size.width * 0.46, 27);

    path1.quadraticBezierTo(size.width * 0.20, 16, 0, 33);

    path1.close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFC6E2D3)
      ..style = PaintingStyle.fill;

    final path2 = Path();

    path2.moveTo(0, 29);

    path2.quadraticBezierTo(size.width * 0.23, 16, size.width * 0.50, 25);

    path2.quadraticBezierTo(size.width * 0.78, 36, size.width, 18);

    path2.lineTo(size.width, 26);

    path2.quadraticBezierTo(size.width * 0.78, 40, size.width * 0.50, 32);

    path2.quadraticBezierTo(size.width * 0.23, 23, 0, 35);

    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
